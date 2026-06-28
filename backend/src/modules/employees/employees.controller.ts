import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import { UpdateEmployeePermissionsDto } from './dto/update-employee-permissions.dto';
import { UpdateEmployeeStatusDto } from './dto/update-employee-status.dto';
import { EmployeesService } from './employees.service';

@ApiTags('Organization Employees')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('organizations/:organizationId/employees')
export class EmployeesController {
  constructor(private readonly employees: EmployeesService) {}

  @Get('available-permissions')
  availablePermissions(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string) {
    return this.employees.availablePermissions(user.sub, organizationId);
  }

  @Get()
  list(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string) {
    return this.employees.listEmployees(user.sub, organizationId);
  }

  @Post()
  invite(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Body() dto: InviteEmployeeDto) {
    return this.employees.inviteEmployee(user.sub, organizationId, dto);
  }

  @Patch(':memberId/permissions')
  updatePermissions(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number, @Body() dto: UpdateEmployeePermissionsDto) {
    return this.employees.updatePermissions(user.sub, organizationId, memberId, dto);
  }

  @Put(':memberId/permissions')
  replacePermissions(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number, @Body() dto: UpdateEmployeePermissionsDto) {
    return this.employees.updatePermissions(user.sub, organizationId, memberId, dto);
  }

  @Put(':memberId/branch-access')
  updateBranchAccess(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number, @Body() dto: any) {
    return this.employees.updateBranchAccess(user.sub, organizationId, memberId, dto);
  }

  @Patch(':memberId/status')
  updateStatus(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number, @Body() dto: UpdateEmployeeStatusDto) {
    return this.employees.updateStatus(user.sub, organizationId, memberId, dto);
  }

  @Get(':memberId/activity')
  activity(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number) {
    return this.employees.activity(user.sub, organizationId, memberId);
  }

  @Delete(':memberId')
  remove(@CurrentUser() user: { sub: number }, @Param('organizationId') organizationId: string, @Param('memberId', ParseIntPipe) memberId: number) {
    return this.employees.removeEmployee(user.sub, organizationId, memberId);
  }
}
