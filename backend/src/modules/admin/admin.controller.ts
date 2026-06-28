import { Body, Controller, Delete, Get, Param, ParseBoolPipe, ParseIntPipe, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { AdminService } from './admin.service';
import { UpdateOrderStatusDto } from '../orders/dto/orders.dto';
import { CreateAdminUserDto, ResolveSystemFindingDto, UpdateAdminLocaleDto, UpdateAdminUserDto, UpdateUserStatusDto, UpsertFeatureFlagDto, UpsertSystemSettingDto, UpsertTranslationEntryDto } from './dto/admin.dto';

@ApiTags('Admin Control Center')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}



  @Get('control-center')
  @RequirePermissions('view_admin_panel')
  controlCenter(@CurrentUser() user: any, @Query('locale') locale?: string) {
    return this.admin.controlCenter(user.sub, locale === 'en' ? 'en' : 'ar');
  }

  @Get('analytics/enterprise')
  @RequirePermissions('view_reports')
  enterpriseAnalytics() {
    return this.admin.enterpriseAnalytics();
  }

  @Get('localization')
  @RequirePermissions('manage_settings')
  localization() {
    return this.admin.localization();
  }

  @Patch('localization/default-locale')
  @RequirePermissions('manage_settings')
  updateDefaultLocale(@CurrentUser() user: any, @Body() dto: UpdateAdminLocaleDto) {
    return this.admin.updateDefaultLocale(user.sub, dto);
  }

  @Get('feature-flags')
  @RequirePermissions('manage_settings')
  featureFlags() {
    return this.admin.featureFlags();
  }

  @Put('feature-flags/:key')
  @RequirePermissions('manage_settings')
  upsertFeatureFlag(@CurrentUser() user: any, @Param('key') key: string, @Body() dto: UpsertFeatureFlagDto) {
    return this.admin.upsertFeatureFlag(user.sub, key, dto);
  }


  @Get('system-hardening/overview')
  @RequirePermissions('manage_settings')
  systemAuditOverview() {
    return this.admin.systemAuditOverview();
  }

  @Get('system-hardening/naming')
  @RequirePermissions('manage_settings')
  namingStandardReport() {
    return this.admin.namingStandardReport();
  }

  @Get('system-hardening/modules')
  @RequirePermissions('view_admin_panel')
  systemModules(@CurrentUser() user: any, @Query('locale') locale?: string) {
    return this.admin.systemModuleRegistry(user.sub, locale === 'en' ? 'en' : 'ar');
  }

  @Patch('system-hardening/findings/:id/resolve')
  @RequirePermissions('manage_settings')
  resolveSystemFinding(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ResolveSystemFindingDto) {
    return this.admin.resolveSystemFinding(user.sub, id, dto);
  }

  @Get('i18n/catalog')
  @RequirePermissions('manage_settings')
  translationCatalog(@Query('locale') locale?: string, @Query('namespace') namespace?: string, @Query('q') q?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.admin.translationCatalog({ locale, namespace, q, take: Number(take || 100), skip: Number(skip || 0) });
  }

  @Put('i18n/catalog/:key')
  @RequirePermissions('manage_settings')
  upsertTranslationEntry(@CurrentUser() user: any, @Param('key') key: string, @Body() dto: UpsertTranslationEntryDto) {
    return this.admin.upsertTranslationEntry(user.sub, key, dto);
  }

  @Get('analytics/snapshots')
  @RequirePermissions('view_reports')
  analyticsSnapshots(@Query('group') group?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.admin.analyticsSnapshots({ group, take: Number(take || 100), skip: Number(skip || 0) });
  }

  @Post('analytics/snapshots/refresh')
  @RequirePermissions('view_reports')
  refreshAnalyticsSnapshots(@CurrentUser() user: any) {
    return this.admin.refreshAnalyticsSnapshots(user.sub);
  }

  @Post('audit-logs/integrity-checkpoint')
  @RequirePermissions('view_audit_logs')
  auditIntegrityCheckpoint(@CurrentUser() user: any) {
    return this.admin.auditIntegrityCheckpoint(user.sub);
  }


  @Get('dashboard/summary')
  @RequirePermissions('view_admin_panel')
  summary() { return this.admin.dashboardSummary(); }

  @Get('analytics/orders')
  @RequirePermissions('view_reports')
  orderMetrics() { return this.admin.orderMetrics(); }

  @Get('analytics/revenue')
  @RequirePermissions('view_reports')
  revenueDaily() { return this.admin.revenueDaily(); }

  @Get('analytics/support')
  @RequirePermissions('view_reports')
  supportMetrics() { return this.admin.supportMetrics(); }

  @Get('analytics/merchants')
  @RequirePermissions('view_reports')
  merchantPerformance() { return this.admin.merchantPerformance(); }

  @Get('users')
  @RequirePermissions('manage_users')
  users(@Query('q') q?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.admin.users({ q, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Post('users')
  @RequirePermissions('manage_users')
  createUser(@CurrentUser() user: any, @Body() dto: CreateAdminUserDto) {
    return this.admin.createUser(user.sub, dto);
  }

  @Patch('users/:id')
  @RequirePermissions('manage_users')
  updateUser(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateAdminUserDto) {
    return this.admin.updateUser(user.sub, id, dto);
  }

  @Patch('users/:id/status')
  @RequirePermissions('manage_users')
  updateUserStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateUserStatusDto) {
    return this.admin.updateUserStatus(user.sub, id, dto);
  }

  @Delete('users/:id')
  @RequirePermissions('manage_users')
  deleteUser(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.admin.deleteUser(user.sub, id);
  }

  @Get('roles')
  @RequirePermissions('manage_users')
  roles() { return this.admin.roles(); }

  @Get('permissions')
  @RequirePermissions('manage_roles')
  permissions() { return this.admin.permissions(); }

  @Post('roles/:roleId/permissions/:permissionId')
  @RequirePermissions('manage_roles')
  grant(@CurrentUser() user: any, @Param('roleId', ParseIntPipe) roleId: number, @Param('permissionId', ParseIntPipe) permissionId: number) {
    return this.admin.grantPermission(user.sub, roleId, permissionId);
  }

  @Delete('roles/:roleId/permissions/:permissionId')
  @RequirePermissions('manage_roles')
  revoke(@CurrentUser() user: any, @Param('roleId', ParseIntPipe) roleId: number, @Param('permissionId', ParseIntPipe) permissionId: number) {
    return this.admin.revokePermission(user.sub, roleId, permissionId);
  }

  @Get('settings')
  @RequirePermissions('manage_settings')
  settings(@Query('publicOnly') publicOnly?: string) {
    return this.admin.settings(publicOnly === 'true');
  }

  @Put('settings/:key')
  @RequirePermissions('manage_settings')
  upsertSetting(@CurrentUser() user: any, @Param('key') key: string, @Body() dto: UpsertSystemSettingDto) {
    return this.admin.upsertSetting(user.sub, key, dto);
  }


  @Get('orders')
  @RequirePermissions('admin.orders.view')
  orders(@Query('status') status?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.admin.orders({ status, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Get('orders/:id')
  @RequirePermissions('admin.orders.view')
  orderDetails(@Param('id', ParseIntPipe) id: number) {
    return this.admin.orderDetails(id);
  }

  @Patch('orders/:id/status')
  @RequirePermissions('admin.orders.view')
  updateOrderStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateOrderStatusDto) {
    return this.admin.updateOrderStatus(user.sub, id, dto);
  }

  @Get('audit-logs')
  @RequirePermissions('view_audit_logs')
  auditLogs(@Query('take') take?: string, @Query('skip') skip?: string, @Query('actorUserId') actorUserId?: string, @Query('action') action?: string) {
    return this.admin.auditLogs({ take: Number(take || 50), skip: Number(skip || 0), actorUserId: actorUserId ? Number(actorUserId) : undefined, action });
  }
}
