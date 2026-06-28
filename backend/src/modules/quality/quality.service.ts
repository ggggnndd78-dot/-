
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { CompleteDeploymentRunDto, CreateDeploymentRunDto, CreateQaRunDto, RecordQaResultDto, UpdateReleaseChecklistItemDto } from './dto/quality.dto';

const REQUIRED_TABLES = [
  'users',
  'roles',
  'permissions',
  'organizations',
  'branches',
  'catalog_products',
  'market_listings',
  'listing_inventory',
  'commerce_orders',
  'commerce_order_items',
  'commerce_invoices',
  'payment_transactions',
  'ledger_accounts',
  'journal_entries',
  'delivery_shipments',
  'support_tickets',
  'review_product_reviews',
  'wallet_accounts',
  'audit_logs',
  'event_outbox',
];

@Injectable()
export class QualityService {
  constructor(private readonly prisma: PrismaService, private readonly audit: AuditService) {}

  async readiness() {
    const tableRows = await this.prisma.$queryRawUnsafe<Array<{ table_name: string }>>(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()',
    ).catch(() => []);
    const tables = new Set(tableRows.map((row: any) => String(row.table_name ?? row.TABLE_NAME ?? '').toLowerCase()));
    const missingTables = REQUIRED_TABLES.filter((table) => !tables.has(table));
    const [openFindings, pendingReleaseChecks, failedReleaseChecks, latestQaRun, latestDeployment] = await Promise.all([
      (this.prisma as any).systemAuditFinding.count({ where: { status: 'OPEN', severity: { in: ['CRITICAL', 'HIGH'] } } }).catch(() => 0),
      (this.prisma as any).releaseChecklistItem.count({ where: { isRequired: true, status: 'PENDING' } }).catch(() => 0),
      (this.prisma as any).releaseChecklistItem.count({ where: { isRequired: true, status: 'FAILED' } }).catch(() => 0),
      (this.prisma as any).qaTestRun.findFirst({ orderBy: { createdAt: 'desc' }, include: { results: true } }).catch(() => null),
      (this.prisma as any).deploymentRun.findFirst({ orderBy: { createdAt: 'desc' } }).catch(() => null),
    ]);
    const blockers = missingTables.length + openFindings + pendingReleaseChecks + failedReleaseChecks;
    return {
      success: true,
      data: {
        status: blockers === 0 ? 'READY' : 'NOT_READY',
        blockers,
        missingTables,
        openCriticalOrHighFindings: openFindings,
        pendingReleaseChecks,
        failedReleaseChecks,
        latestQaRun,
        latestDeployment,
      },
    };
  }

  async createRun(actorUserId: number, dto: CreateQaRunDto) {
    const run = await (this.prisma as any).qaTestRun.create({
      data: {
        runKey: `qa_${Date.now()}_${randomUUID().slice(0, 8)}`,
        title: dto.title,
        scope: dto.scope ?? 'FULL_SYSTEM',
        environment: dto.environment ?? 'LOCAL',
        status: 'RUNNING',
        startedByUserId: actorUserId,
        startedAt: new Date(),
      },
    });
    await this.audit.write({ actorUserId, action: 'qa.run.created', entityType: 'qa_test_run', entityId: run.id, metadata: { runKey: run.runKey } });
    return { success: true, data: run };
  }

  async runs(take = 50, skip = 0) {
    const rows = await (this.prisma as any).qaTestRun.findMany({
      include: { results: true },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(take, 1), 100),
      skip,
    });
    return { success: true, data: rows };
  }

  async runDetails(id: number) {
    const run = await (this.prisma as any).qaTestRun.findUnique({ where: { id }, include: { results: true } });
    if (!run) throw new NotFoundException({ message: 'QA run not found', error_code: 'QA_RUN_NOT_FOUND' });
    return { success: true, data: run };
  }

  async recordResult(actorUserId: number, runId: number, dto: RecordQaResultDto) {
    const run = await (this.prisma as any).qaTestRun.findUnique({ where: { id: runId } });
    if (!run) throw new NotFoundException({ message: 'QA run not found', error_code: 'QA_RUN_NOT_FOUND' });
    const result = await (this.prisma as any).qaTestResult.upsert({
      where: { runId_suite_caseKey: { runId, suite: dto.suite, caseKey: dto.caseKey } },
      update: {
        caseTitle: dto.caseTitle,
        status: dto.status,
        durationMs: dto.durationMs ?? null,
        errorMessage: dto.errorMessage ?? null,
      },
      create: {
        runId,
        suite: dto.suite,
        caseKey: dto.caseKey,
        caseTitle: dto.caseTitle,
        status: dto.status,
        durationMs: dto.durationMs ?? null,
        errorMessage: dto.errorMessage ?? null,
      },
    });
    const summary = await this.recalculateRun(runId);
    await this.audit.write({ actorUserId, action: 'qa.result.recorded', entityType: 'qa_test_result', entityId: result.id, metadata: { runId, status: dto.status, summary } });
    return { success: true, data: { result, summary } };
  }

  private async recalculateRun(runId: number) {
    const results = await (this.prisma as any).qaTestResult.findMany({ where: { runId } });
    const failed = results.filter((row: any) => row.status === 'FAILED').length;
    const blocked = results.filter((row: any) => row.status === 'BLOCKED').length;
    const passed = results.filter((row: any) => row.status === 'PASSED').length;
    const skipped = results.filter((row: any) => row.status === 'SKIPPED').length;
    const status = failed > 0 ? 'FAILED' : blocked > 0 ? 'BLOCKED' : results.length > 0 ? 'PASSED' : 'RUNNING';
    const summary = { total: results.length, passed, failed, blocked, skipped };
    await (this.prisma as any).qaTestRun.update({
      where: { id: runId },
      data: {
        status,
        summary: summary as Prisma.InputJsonValue,
        finishedAt: status === 'RUNNING' ? null : new Date(),
      },
    });
    return summary;
  }

  async releaseChecklist() {
    const rows = await (this.prisma as any).releaseChecklistItem.findMany({ orderBy: [{ moduleCode: 'asc' }, { itemKey: 'asc' }] });
    return { success: true, data: rows };
  }

  async updateReleaseChecklistItem(actorUserId: number, id: number, dto: UpdateReleaseChecklistItemDto) {
    const item = await (this.prisma as any).releaseChecklistItem.update({
      where: { id },
      data: {
        status: dto.status,
        evidenceUrl: dto.evidenceUrl ?? undefined,
        description: dto.description ?? undefined,
        verifiedByUserId: actorUserId,
        verifiedAt: ['PASSED', 'FAILED', 'WAIVED'].includes(dto.status) ? new Date() : null,
      },
    }).catch(() => null);
    if (!item) throw new NotFoundException({ message: 'Release checklist item not found', error_code: 'RELEASE_ITEM_NOT_FOUND' });
    await this.audit.write({ actorUserId, action: 'release.checklist.updated', entityType: 'release_checklist_item', entityId: id, metadata: { status: dto.status } });
    return { success: true, data: item };
  }

  async createDeployment(actorUserId: number, dto: CreateDeploymentRunDto) {
    const readiness = await this.readiness();
    if (dto.environment === 'PRODUCTION' && readiness.data.status !== 'READY') {
      throw new BadRequestException({ message: 'Production deployment is blocked until readiness is READY', error_code: 'PRODUCTION_NOT_READY', readiness: readiness.data });
    }
    const deployment = await (this.prisma as any).deploymentRun.create({
      data: {
        deploymentKey: `deploy_${Date.now()}_${randomUUID().slice(0, 8)}`,
        environment: dto.environment,
        version: dto.version,
        commitSha: dto.commitSha ?? null,
        releaseNotes: dto.releaseNotes ?? null,
        status: 'RUNNING',
        startedByUserId: actorUserId,
        startedAt: new Date(),
        metadata: { readiness: readiness.data } as Prisma.InputJsonValue,
      },
    });
    await this.audit.write({ actorUserId, action: 'deployment.created', entityType: 'deployment_run', entityId: deployment.id, metadata: { environment: dto.environment, version: dto.version } });
    return { success: true, data: deployment };
  }

  async deployments(take = 50, skip = 0) {
    const rows = await (this.prisma as any).deploymentRun.findMany({
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(take, 1), 100),
      skip,
    });
    return { success: true, data: rows };
  }

  async completeDeployment(actorUserId: number, id: number, status: CompleteDeploymentRunDto['status']) {
    const deployment = await (this.prisma as any).deploymentRun.update({
      where: { id },
      data: { status, completedAt: new Date() },
    }).catch(() => null);
    if (!deployment) throw new NotFoundException({ message: 'Deployment not found', error_code: 'DEPLOYMENT_NOT_FOUND' });
    await this.audit.write({ actorUserId, action: 'deployment.completed', entityType: 'deployment_run', entityId: id, metadata: { status } });
    return { success: true, data: deployment };
  }
}
