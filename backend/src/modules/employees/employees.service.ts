import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EventBusService } from '../../common/events/event-bus.service';
import { AuditService } from '../audit/audit.service';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import { UpdateEmployeePermissionsDto } from './dto/update-employee-permissions.dto';
import { UpdateEmployeeStatusDto } from './dto/update-employee-status.dto';

const PERMISSIONS_BY_ORG_TYPE: Record<string, string[]> = {
  MERCHANT: ['merchant.products.manage', 'merchant.inventory.manage', 'product_imports.manage', 'merchant.orders.manage', 'merchant.branches.manage', 'merchant.employees.manage', 'view_reports'],
  WORKSHOP: ['product_imports.manage', 'workshop.services.manage', 'workshop.bookings.manage', 'workshop.service_orders.manage', 'workshop.branches.manage', 'workshop.employees.manage', 'view_reports'],
  WAREHOUSE: ['warehouse.inventory.manage', 'product_imports.manage', 'warehouse.employees.manage', 'view_reports'],
};

@Injectable()
export class EmployeesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
    private readonly audit: AuditService,
  ) {}

  private get db() { return this.prisma as any; }
  private normalizePhone(phone: string) { return phone.replace(/\D/g, ''); }
  private normalizeEmail(email: string) { return email.trim().toLowerCase(); }

  private async getOwnerOrganization(userId: number, organizationPublicId: string) {
    const organization = await this.db.organization.findUnique({ where: { publicId: organizationPublicId }, include: { members: true, branches: true } });
    if (!organization) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
    const owner = organization.members.find((m: any) => m.userId === userId && ['owner', 'merchant_owner', 'workshop_owner', 'warehouse_owner'].includes(m.memberRole));
    if (!owner) throw new ForbiddenException({ message: 'Only organization owner can manage employees', error_code: 'ORG_OWNER_REQUIRED' });
    if (organization.status !== 'APPROVED') throw new ForbiddenException({ message: 'Organization must be approved before adding employees', error_code: 'ORGANIZATION_NOT_APPROVED' });
    return organization;
  }

  private employeeRoleForOrganization(type: string) {
    if (type === 'MERCHANT') return 'merchant_employee';
    if (type === 'WORKSHOP') return 'workshop_employee';
    if (type === 'WAREHOUSE') return 'warehouse_employee';
    throw new BadRequestException({ message: 'Unsupported organization type', error_code: 'UNSUPPORTED_ORGANIZATION_TYPE' });
  }

  private validatePermissions(type: string, permissions: string[]) {
    const allowed = new Set(PERMISSIONS_BY_ORG_TYPE[type] ?? []);
    const invalid = permissions.filter((permission) => !allowed.has(permission));
    if (invalid.length > 0) throw new BadRequestException({ message: 'Some employee permissions are not allowed for this organization type', error_code: 'INVALID_EMPLOYEE_PERMISSIONS', invalid_permissions: invalid, allowed_permissions: Array.from(allowed) });
  }

  private async ensureValidBranches(organizationId: number, branchPublicIds: string[]) {
    if (branchPublicIds.length === 0) return [];
    const branches = await this.db.organizationBranch.findMany({ where: { organizationId, publicId: { in: branchPublicIds } } });
    if (branches.length !== new Set(branchPublicIds).size) throw new BadRequestException({ message: 'One or more branches do not belong to this organization', error_code: 'INVALID_BRANCH_ACCESS' });
    return branches;
  }

  private async ensureUserForEmployee(dto: InviteEmployeeDto) {
    const email = dto.email ? this.normalizeEmail(dto.email) : null;
    const phone = dto.phone ? this.normalizePhone(dto.phone) : null;
    if (!email && !phone) throw new BadRequestException({ message: 'Employee email or phone is required', error_code: 'EMPLOYEE_TARGET_REQUIRED' });
    let user = await this.db.user.findFirst({ where: email ? { email } : { phoneNormalized: phone } });
    if (!user) user = await this.db.user.create({ data: { email, phoneE164: phone, phoneNormalized: phone, displayName: dto.displayName, status: 'ACTIVE', isPhoneVerified: !!phone } });
    return user;
  }

  async availablePermissions(ownerUserId: number, organizationPublicId: string) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    return { success: true, data: (PERMISSIONS_BY_ORG_TYPE[organization.organizationType] ?? []).map((code) => ({ code, name: code })) };
  }

  async inviteEmployee(ownerUserId: number, organizationPublicId: string, dto: InviteEmployeeDto) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const permissions = Array.from(new Set(dto.permissions ?? []));
    this.validatePermissions(organization.organizationType, permissions);
    const allBranches = dto.allBranches ?? ((dto.branchIds ?? []).length === 0);
    const branches = await this.ensureValidBranches(organization.id, allBranches ? [] : (dto.branchIds ?? []));
    const user = await this.ensureUserForEmployee(dto);
    const roleCode = this.employeeRoleForOrganization(organization.organizationType);
    const role = await this.db.role.upsert({ where: { code: roleCode }, update: {}, create: { code: roleCode, name: roleCode } });
    await this.db.userRole.upsert({ where: { userId_roleId: { userId: user.id, roleId: role.id } }, update: {}, create: { userId: user.id, roleId: role.id } });
    const member = await this.db.organizationMember.upsert({
      where: { organizationId_userId: { organizationId: organization.id, userId: user.id } },
      update: { memberRole: roleCode, status: 'ACTIVE', createdByUserId: ownerUserId, allBranches },
      create: { organizationId: organization.id, userId: user.id, memberRole: roleCode, status: 'ACTIVE', createdByUserId: ownerUserId, allBranches },
    });
    await this.db.organizationMemberPermission.deleteMany({ where: { organizationMemberId: member.id } });
    for (const permissionCode of permissions) await this.db.organizationMemberPermission.create({ data: { organizationMemberId: member.id, permissionCode } });
    await this.db.organizationMemberBranchAccess.deleteMany({ where: { organizationMemberId: member.id } });
    if (!allBranches) for (const branch of branches) await this.db.organizationMemberBranchAccess.create({ data: { organizationMemberId: member.id, branchId: branch.id } });
    await this.db.employeeInvitation.create({ data: { organizationId: organization.id, invitedEmail: dto.email ? this.normalizeEmail(dto.email) : null, invitedPhone: dto.phone ? this.normalizePhone(dto.phone) : null, displayName: dto.displayName ?? null, memberRole: roleCode, status: 'ACCEPTED', invitedByUserId: ownerUserId, acceptedByUserId: user.id, expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), acceptedAt: new Date() } });
    await this.eventBus.publish({ name: 'EmployeeInvited', aggregateType: 'organization', aggregateId: organization.publicId, actorUserId: ownerUserId, payload: { employee_user_id: user.publicId, role: roleCode, permissions, all_branches: allBranches } });
    await this.audit.write({ actorUserId: ownerUserId, action: 'organization.employee.added', entityType: 'organization_member', entityId: String(member.id), metadata: { organization_id: organization.publicId, employee_user_id: user.publicId, permissions, all_branches: allBranches } });
    return { success: true, message: 'Employee added successfully', data: { id: member.id, user_id: user.publicId, role: roleCode, permissions, all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } };
  }

  async listEmployees(ownerUserId: number, organizationPublicId: string) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const members = await this.db.organizationMember.findMany({ where: { organizationId: organization.id, memberRole: { not: 'owner' } }, include: { user: true, permissions: true, branchAccess: { include: { branch: true } } }, orderBy: { createdAt: 'desc' } });
    return { success: true, data: members.map((member: any) => ({ id: member.id, user_id: member.user.publicId, display_name: member.user.displayName, phone: member.user.phoneNormalized, email: member.user.email, role: member.memberRole, status: member.status, all_branches: member.allBranches, permissions: member.permissions.map((p: any) => p.permissionCode), branches: member.branchAccess.map((b: any) => ({ id: b.branch.publicId, name: b.branch.branchName })) })) };
  }

  async updatePermissions(ownerUserId: number, organizationPublicId: string, memberId: number, dto: UpdateEmployeePermissionsDto) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const member = await this.db.organizationMember.findFirst({ where: { id: memberId, organizationId: organization.id } });
    if (!member) throw new NotFoundException({ message: 'Employee not found', error_code: 'EMPLOYEE_NOT_FOUND' });
    if (member.memberRole === 'owner') throw new BadRequestException({ message: 'Owner permissions cannot be changed here', error_code: 'OWNER_PERMISSION_LOCKED' });
    const permissions = Array.from(new Set(dto.permissions ?? []));
    this.validatePermissions(organization.organizationType, permissions);
    const allBranches = dto.allBranches ?? member.allBranches ?? ((dto.branchIds ?? []).length === 0);
    const branches = await this.ensureValidBranches(organization.id, allBranches ? [] : (dto.branchIds ?? []));
    await this.db.organizationMember.update({ where: { id: member.id }, data: { allBranches } });
    await this.db.organizationMemberPermission.deleteMany({ where: { organizationMemberId: member.id } });
    for (const permissionCode of permissions) await this.db.organizationMemberPermission.create({ data: { organizationMemberId: member.id, permissionCode } });
    await this.db.organizationMemberBranchAccess.deleteMany({ where: { organizationMemberId: member.id } });
    if (!allBranches) for (const branch of branches) await this.db.organizationMemberBranchAccess.create({ data: { organizationMemberId: member.id, branchId: branch.id } });
    await this.eventBus.publish({ name: 'EmployeePermissionsUpdated', aggregateType: 'organization_member', aggregateId: member.id, actorUserId: ownerUserId, payload: { permissions, all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } });
    await this.audit.write({ actorUserId: ownerUserId, action: 'organization.employee.permissions.updated', entityType: 'organization_member', entityId: String(member.id), metadata: { organization_id: organization.publicId, permissions, all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } });
    return { success: true, message: 'Employee permissions updated successfully', data: { id: member.id, permissions, all_branches: allBranches } };
  }

  async updateStatus(ownerUserId: number, organizationPublicId: string, memberId: number, dto: UpdateEmployeeStatusDto) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const member = await this.db.organizationMember.findFirst({ where: { id: memberId, organizationId: organization.id }, include: { user: true } });
    if (!member) throw new NotFoundException({ message: 'Employee not found', error_code: 'EMPLOYEE_NOT_FOUND' });
    if (member.memberRole === 'owner') throw new BadRequestException({ message: 'Owner cannot be suspended here', error_code: 'OWNER_STATUS_LOCKED' });
    const updated = await this.db.organizationMember.update({ where: { id: member.id }, data: { status: dto.status } });
    await this.eventBus.publish({ name: dto.status === 'SUSPENDED' ? 'EmployeeSuspended' : 'EmployeeStatusUpdated', aggregateType: 'organization_member', aggregateId: member.id, actorUserId: ownerUserId, payload: { status: dto.status, reason: dto.reason ?? null } });
    await this.audit.write({ actorUserId: ownerUserId, action: 'organization.employee.status.updated', entityType: 'organization_member', entityId: String(member.id), metadata: { organization_id: organization.publicId, employee_user_id: member.user.publicId, status: dto.status, reason: dto.reason ?? null } });
    return { success: true, message: 'Employee status updated successfully', data: { id: updated.id, status: updated.status } };
  }


  async updateBranchAccess(ownerUserId: number, organizationPublicId: string, memberId: number, dto: { items?: Array<{ branchId?: string; canView?: boolean; canManage?: boolean }>; allBranches?: boolean; branchIds?: string[] }) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const member = await this.db.organizationMember.findFirst({ where: { id: memberId, organizationId: organization.id } });
    if (!member) throw new NotFoundException({ message: 'Employee not found', error_code: 'EMPLOYEE_NOT_FOUND' });
    if (member.memberRole === 'owner') throw new BadRequestException({ message: 'Owner branch access cannot be changed here', error_code: 'OWNER_BRANCH_ACCESS_LOCKED' });
    const itemBranchIds = (dto.items ?? [])
      .filter((item) => item.canView || item.canManage)
      .map((item) => item.branchId)
      .filter((value): value is string => typeof value === 'string' && value.trim().length > 0);
    const branchIds = Array.from(new Set([...(dto.branchIds ?? []), ...itemBranchIds]));
    const allBranches = dto.allBranches ?? branchIds.length === 0;
    const branches = await this.ensureValidBranches(organization.id, allBranches ? [] : branchIds);
    await this.db.organizationMember.update({ where: { id: member.id }, data: { allBranches } });
    await this.db.organizationMemberBranchAccess.deleteMany({ where: { organizationMemberId: member.id } });
    if (!allBranches) for (const branch of branches) await this.db.organizationMemberBranchAccess.create({ data: { organizationMemberId: member.id, branchId: branch.id } });
    await this.eventBus.publish({ name: 'EmployeeBranchAccessUpdated', aggregateType: 'organization_member', aggregateId: member.id, actorUserId: ownerUserId, payload: { all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } });
    await this.audit.write({ actorUserId: ownerUserId, action: 'organization.employee.branch_access.updated', entityType: 'organization_member', entityId: String(member.id), metadata: { organization_id: organization.publicId, all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } });
    return { success: true, message: 'Employee branch access updated successfully', data: { id: member.id, all_branches: allBranches, branch_ids: branches.map((b: any) => b.publicId) } };
  }

  async removeEmployee(ownerUserId: number, organizationPublicId: string, memberId: number) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const member = await this.db.organizationMember.findFirst({ where: { id: memberId, organizationId: organization.id }, include: { user: true } });
    if (!member) throw new NotFoundException({ message: 'Employee not found', error_code: 'EMPLOYEE_NOT_FOUND' });
    if (member.memberRole === 'owner') throw new BadRequestException({ message: 'Owner cannot be removed here', error_code: 'OWNER_REMOVE_LOCKED' });
    await this.db.organizationMember.update({ where: { id: member.id }, data: { status: 'REMOVED' } });
    await this.eventBus.publish({ name: 'EmployeeRemoved', aggregateType: 'organization_member', aggregateId: member.id, actorUserId: ownerUserId, payload: { employee_user_id: member.user.publicId } });
    await this.audit.write({ actorUserId: ownerUserId, action: 'organization.employee.removed', entityType: 'organization_member', entityId: String(member.id), metadata: { organization_id: organization.publicId, employee_user_id: member.user.publicId } });
    return { success: true, message: 'Employee removed successfully', data: { id: member.id, status: 'REMOVED' } };
  }

  async activity(ownerUserId: number, organizationPublicId: string, memberId: number) {
    const organization = await this.getOwnerOrganization(ownerUserId, organizationPublicId);
    const member = await this.db.organizationMember.findFirst({ where: { id: memberId, organizationId: organization.id }, include: { user: true } });
    if (!member) throw new NotFoundException({ message: 'Employee not found', error_code: 'EMPLOYEE_NOT_FOUND' });
    const logs = await this.db.auditLog.findMany({ where: { actorUserId: member.userId }, orderBy: { createdAt: 'desc' }, take: 50 }).catch(() => []);
    return { success: true, data: logs.map((log: any) => ({ id: log.publicId, action: log.action, entity_type: log.entityType, entity_id: log.entityId, metadata: log.metadata, created_at: log.createdAt })) };
  }
}
