import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { CancelOrderDto, CheckoutPreviewDto, CreateOrderDto } from './dto/orders.dto';
import { OrdersService } from './orders.service';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller()
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post('checkout/preview')
  @RequirePermissions('orders.create')
  preview(@CurrentUser() user: { sub: number }, @Body() dto: CheckoutPreviewDto) {
    return this.orders.checkoutPreview(user.sub, dto);
  }

  @Post('orders')
  @RequirePermissions('orders.create')
  create(@CurrentUser() user: { sub: number }, @Body() dto: CreateOrderDto) {
    return this.orders.createOrder(user.sub, dto);
  }

  @Get('orders/my')
  @RequirePermissions('orders.view_own')
  my(@CurrentUser() user: { sub: number }) {
    return this.orders.myOrders(user.sub);
  }

  @Get('orders/:id')
  @RequirePermissions('orders.view_own')
  details(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number) {
    return this.orders.details(user.sub, id);
  }

  @Patch('orders/:id/cancel')
  @RequirePermissions('orders.view_own')
  cancel(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: CancelOrderDto) {
    return this.orders.cancelByCustomer(user.sub, id, dto);
  }
}
