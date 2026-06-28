import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { EventsService } from './events.service';

@ApiTags('Admin Domain Events')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('admin/events')
export class EventsController {
  constructor(private readonly events: EventsService) {}

  @Get('domain')
  @RequirePermissions('view_audit_logs')
  listDomainEvents(
    @CurrentUser() user: { sub: number },
    @Query('name') name?: string,
    @Query('aggregateType') aggregateType?: string,
    @Query('aggregateId') aggregateId?: string,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    return this.events.listDomainEvents(user.sub, { name, aggregateType, aggregateId, take, skip });
  }

  @Get('outbox')
  @RequirePermissions('view_audit_logs')
  listOutbox(
    @CurrentUser() user: { sub: number },
    @Query('status') status?: string,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    return this.events.listOutbox(user.sub, { status, take, skip });
  }

  @Get('logs')
  @RequirePermissions('view_audit_logs')
  listEventLogs(
    @CurrentUser() user: { sub: number },
    @Query('eventId') eventId?: string,
    @Query('status') status?: string,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    return this.events.listEventLogs(user.sub, { eventId, status, take, skip });
  }
}
