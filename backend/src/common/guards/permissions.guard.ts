import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { REQUIRED_PERMISSIONS_KEY } from '../decorators/permissions.decorator';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>(REQUIRED_PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass(),
    ]) ?? [];

    if (required.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const userId = Number(request.user?.sub);
    if (!userId) {
      throw new ForbiddenException({ message: 'Access denied', error_code: 'FORBIDDEN' });
    }

    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: {
        role: {
          include: {
            rolePermissions: { include: { permission: true } },
          },
        },
      },
    });

    if (roles.some((entry) => entry.role.code === 'admin_super')) return true;

    const userPermissions = new Set<string>();
    for (const entry of roles) {
      for (const rolePermission of entry.role.rolePermissions) {
        userPermissions.add(rolePermission.permission.code);
      }
    }

    const directOrganizationPermissions = await this.prisma.organizationMemberPermission.findMany({
      where: {
        member: {
          userId,
          status: 'ACTIVE',
          organization: { status: 'APPROVED' },
        },
      },
      select: { permissionCode: true },
    });
    for (const permission of directOrganizationPermissions) {
      userPermissions.add(permission.permissionCode);
    }

    const allowed = required.every((permission) => userPermissions.has(permission));
    if (!allowed) {
      throw new ForbiddenException({
        message: 'You do not have permission to perform this action',
        error_code: 'PERMISSION_DENIED',
        required_permissions: required,
      });
    }

    return true;
  }
}
