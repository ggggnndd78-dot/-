import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateNotificationDto, RegisterDeviceDto } from './dto/notifications.dto';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('devices')
  registerDevice(@CurrentUser() user: any, @Body() dto: RegisterDeviceDto) {
    return this.notifications.registerDevice(user.sub, dto);
  }

  @Delete('devices/:id')
  deactivateDevice(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.notifications.deactivateDevice(user.sub, id);
  }

  @Get('my')
  mine(@CurrentUser() user: any) {
    return this.notifications.listMyNotifications(user.sub);
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() user: any) {
    return this.notifications.unreadCount(user.sub);
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.notifications.markRead(user.sub, id);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser() user: any) {
    return this.notifications.markAllRead(user.sub);
  }

  @Post('test')
  test(@CurrentUser() user: any, @Body() dto: CreateNotificationDto) {
    return this.notifications.createTestNotification(user.sub, dto);
  }
}
