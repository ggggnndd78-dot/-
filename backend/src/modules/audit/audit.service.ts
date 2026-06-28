import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface AuditWriteInput {
  actorUserId?: number | null;
  action: string;
  entityType?: string | null;
  entityId?: string | number | null;
  method?: string | null;
  path?: string | null;
  ipAddress?: string | null;
  userAgent?: string | null;
  requestId?: string | null;
  locale?: string | null;
  metadata?: Record<string, unknown> | null;
}

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async write(input: AuditWriteInput) {
    return this.prisma.auditLog.create({
      data: {
        actorUserId: input.actorUserId ?? null,
        action: input.action,
        entityType: input.entityType ?? null,
        entityId: input.entityId == null ? null : String(input.entityId),
        method: input.method ?? null,
        path: input.path ?? null,
        ipAddress: input.ipAddress ?? null,
        userAgent: input.userAgent ?? null,
        requestId: input.requestId ?? null,
        locale: input.locale ?? null,
        metadata: input.metadata == null ? undefined : (input.metadata as Prisma.InputJsonValue),
      },
    });
  }

  async list(params: { take?: number; skip?: number; actorUserId?: number; action?: string }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    return this.prisma.auditLog.findMany({
      where: {
        actorUserId: params.actorUserId,
        action: params.action,
      },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
  }
}
