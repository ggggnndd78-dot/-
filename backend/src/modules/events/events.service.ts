import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertCanViewEvents(userId: number) {
    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });

    if (roles.some((entry) => entry.role.code === 'admin_super')) return;

    const allowed = roles.some((entry) =>
      entry.role.rolePermissions.some((rp) => rp.permission.code === 'view_audit_logs'),
    );

    if (!allowed) {
      throw new ForbiddenException({
        message: 'You do not have permission to view domain events',
        error_code: 'PERMISSION_DENIED',
      });
    }
  }

  private safeTake(take?: string) {
    const parsed = Number(take ?? 50);
    if (!Number.isFinite(parsed) || parsed <= 0) return 50;
    return Math.min(parsed, 100);
  }

  private safeSkip(skip?: string) {
    const parsed = Number(skip ?? 0);
    if (!Number.isFinite(parsed) || parsed < 0) return 0;
    return parsed;
  }

  async listDomainEvents(userId: number, query: { name?: string; aggregateType?: string; aggregateId?: string; take?: string; skip?: string }) {
    await this.assertCanViewEvents(userId);

    const events = await (this.prisma as any).domainEventRecord.findMany({
      where: {
        ...(query.name ? { name: query.name } : {}),
        ...(query.aggregateType ? { aggregateType: query.aggregateType } : {}),
        ...(query.aggregateId ? { aggregateId: query.aggregateId } : {}),
      },
      include: {
        outboxItems: { select: { publicId: true, status: true, attempts: true, createdAt: true }, take: 1, orderBy: { createdAt: 'desc' } },
      },
      orderBy: { createdAt: 'desc' },
      take: this.safeTake(query.take),
      skip: this.safeSkip(query.skip),
    });

    return {
      success: true,
      message: 'Domain events retrieved successfully',
      data: events.map((event: any) => ({
        id: event.publicId,
        name: event.name,
        aggregate_type: event.aggregateType,
        aggregate_id: event.aggregateId,
        actor_user_id: event.actorUserId,
        source: event.source,
        payload: event.payload,
        occurred_at: event.occurredAt,
        created_at: event.createdAt,
        outbox: event.outboxItems?.[0]
          ? {
              id: event.outboxItems[0].publicId,
              status: event.outboxItems[0].status,
              attempts: event.outboxItems[0].attempts,
              created_at: event.outboxItems[0].createdAt,
            }
          : null,
      })),
    };
  }

  async listOutbox(userId: number, query: { status?: string; take?: string; skip?: string }) {
    await this.assertCanViewEvents(userId);

    const items = await (this.prisma as any).eventOutbox.findMany({
      where: query.status ? { status: query.status } : undefined,
      orderBy: { createdAt: 'desc' },
      take: this.safeTake(query.take),
      skip: this.safeSkip(query.skip),
    });

    return {
      success: true,
      message: 'Event outbox retrieved successfully',
      data: items.map((item: any) => ({
        id: item.publicId,
        event_name: item.eventName,
        aggregate_type: item.aggregateType,
        aggregate_id: item.aggregateId,
        destination: item.destination,
        status: item.status,
        attempts: item.attempts,
        last_error: item.lastError,
        available_at: item.availableAt,
        processed_at: item.processedAt,
        created_at: item.createdAt,
      })),
    };
  }

  async listEventLogs(userId: number, query: { eventId?: string; status?: string; take?: string; skip?: string }) {
    await this.assertCanViewEvents(userId);

    let domainEventId: number | undefined;
    if (query.eventId) {
      const event = await (this.prisma as any).domainEventRecord.findUnique({ where: { publicId: query.eventId } });
      domainEventId = event?.id ?? -1;
    }

    const logs = await (this.prisma as any).eventLog.findMany({
      where: {
        ...(domainEventId !== undefined ? { domainEventId } : {}),
        ...(query.status ? { status: query.status } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: this.safeTake(query.take),
      skip: this.safeSkip(query.skip),
    });

    return {
      success: true,
      message: 'Event logs retrieved successfully',
      data: logs.map((log: any) => ({
        id: log.publicId,
        event_name: log.eventName,
        status: log.status,
        message: log.message,
        metadata: log.metadata,
        created_at: log.createdAt,
      })),
    };
  }
}
