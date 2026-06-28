import { Injectable, Logger } from '@nestjs/common';
import { AuditService } from '../../modules/audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { DomainEvent, PublishedDomainEvent } from './domain-event.interface';

@Injectable()
export class EventBusService {
  private readonly logger = new Logger(EventBusService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  private normalizeAggregateId(value: DomainEvent['aggregateId']): string | null {
    if (value === undefined || value === null) return null;
    return String(value);
  }

  async publish(event: DomainEvent): Promise<PublishedDomainEvent> {
    const occurredAt = event.occurredAt ?? new Date();
    const aggregateId = this.normalizeAggregateId(event.aggregateId);
    const payload = event.payload ?? {};

    this.logger.log(
      `DomainEvent ${event.name} aggregate=${event.aggregateType ?? 'n/a'}:${aggregateId ?? 'n/a'}`,
    );

    if (event.idempotencyKey) {
      const existing = await (this.prisma as any).domainEventRecord.findUnique({
        where: { idempotencyKey: event.idempotencyKey },
        include: { outboxItems: { orderBy: { createdAt: 'desc' }, take: 1 } },
      });

      if (existing) {
        return {
          published: true,
          event_name: existing.name,
          event_id: existing.publicId,
          outbox_id: existing.outboxItems?.[0]?.publicId ?? '',
          occurred_at: existing.occurredAt.toISOString(),
        };
      }
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const domainEvent = await (tx as any).domainEventRecord.create({
        data: {
          name: event.name,
          aggregateType: event.aggregateType ?? null,
          aggregateId,
          actorUserId: event.actorUserId ?? null,
          source: event.source ?? 'backend',
          idempotencyKey: event.idempotencyKey ?? null,
          payload,
          occurredAt,
        },
      });

      const outbox = await (tx as any).eventOutbox.create({
        data: {
          domainEventId: domainEvent.id,
          eventName: event.name,
          aggregateType: event.aggregateType ?? null,
          aggregateId,
          destination: 'internal',
          payload,
          status: 'PENDING',
          availableAt: occurredAt,
        },
      });

      await (tx as any).eventLog.create({
        data: {
          domainEventId: domainEvent.id,
          eventName: event.name,
          status: 'RECORDED',
          message: 'Domain event recorded and queued in outbox.',
          metadata: {
            outbox_id: outbox.publicId,
            aggregate_type: event.aggregateType ?? null,
            aggregate_id: aggregateId,
          },
        },
      });

      return { domainEvent, outbox };
    });

    await this.audit.write({
      actorUserId: event.actorUserId ?? null,
      action: `event.${event.name}`,
      entityType: event.aggregateType ?? 'domain_event',
      entityId: aggregateId ?? created.domainEvent.publicId,
      metadata: {
        event_id: created.domainEvent.publicId,
        outbox_id: created.outbox.publicId,
        event_name: event.name,
        occurred_at: occurredAt.toISOString(),
        payload,
      },
    });

    return {
      published: true,
      event_name: event.name,
      event_id: created.domainEvent.publicId,
      outbox_id: created.outbox.publicId,
      occurred_at: occurredAt.toISOString(),
    };
  }
}
