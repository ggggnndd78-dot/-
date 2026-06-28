import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import {
  AssignShipmentDto,
  CreateDriverDto,
  CreateShipmentFromOrderDto,
  CreateShippingCompanyDto,
  UpdateDriverDto,
  UpdateShipmentStatusDto,
  UpdateShippingCompanyDto,
  UpsertDeliveryFeeDto,
} from './dto/delivery.dto';
import { DeliveryService } from './delivery.service';

@ApiTags('Delivery')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('delivery')
export class DeliveryController {
  constructor(private readonly delivery: DeliveryService) {}

  @Get('methods')
  methods() { return this.delivery.methods(); }

  @Get('fees')
  deliveryFees(@Query('cityId') cityId?: string, @Query('branchId') branchId?: string, @Query('deliveryMethodId') deliveryMethodId?: string) {
    return this.delivery.deliveryFees({ cityId: cityId ? Number(cityId) : undefined, branchId: branchId ? Number(branchId) : undefined, deliveryMethodId: deliveryMethodId ? Number(deliveryMethodId) : undefined });
  }

  @Post('fees')
  @RequirePermissions('delivery.fees.manage')
  upsertDeliveryFee(@CurrentUser() user: any, @Body() dto: UpsertDeliveryFeeDto) {
    return this.delivery.upsertDeliveryFee(user.sub, dto);
  }

  @Get('shipping-companies')
  shippingCompanies(@Query('cityId') cityId?: string, @Query('organizationId') organizationId?: string) {
    return this.delivery.shippingCompanies({ cityId: cityId ? Number(cityId) : undefined, organizationId: organizationId ? Number(organizationId) : undefined });
  }

  @Post('shipping-companies')
  @RequirePermissions('delivery.companies.manage')
  createShippingCompany(@CurrentUser() user: any, @Body() dto: CreateShippingCompanyDto) {
    return this.delivery.createShippingCompany(user.sub, dto);
  }

  @Patch('shipping-companies/:id')
  @RequirePermissions('delivery.companies.manage')
  updateShippingCompany(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateShippingCompanyDto) {
    return this.delivery.updateShippingCompany(user.sub, id, dto);
  }

  @Get('drivers')
  @RequirePermissions('delivery.drivers.manage')
  drivers(@CurrentUser() user: any, @Query('organizationId') organizationId?: string) {
    return this.delivery.drivers(user.sub, organizationId ? Number(organizationId) : undefined);
  }

  @Post('drivers')
  @RequirePermissions('delivery.drivers.manage')
  createDriver(@CurrentUser() user: any, @Body() dto: CreateDriverDto) {
    return this.delivery.createDriver(user.sub, dto);
  }

  @Patch('drivers/:id')
  @RequirePermissions('delivery.drivers.manage')
  updateDriver(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateDriverDto) {
    return this.delivery.updateDriver(user.sub, id, dto);
  }

  @Post('orders/:id/shipments')
  @RequirePermissions('delivery.shipments.manage')
  createFromOrder(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateShipmentFromOrderDto) {
    return this.delivery.createFromOrder(user.sub, id, dto);
  }

  @Get('shipments/my')
  myShipments(@CurrentUser() user: any) { return this.delivery.myShipments(user.sub); }

  @Get('driver/shipments')
  @RequirePermissions('delivery.shipments.manage')
  driverShipments(@CurrentUser() user: any) { return this.delivery.driverShipments(user.sub); }

  @Get('merchant/shipments')
  @RequirePermissions('delivery.shipments.manage')
  merchantShipments(@CurrentUser() user: any) { return this.delivery.merchantShipments(user.sub); }

  @Get('admin/shipments')
  @RequirePermissions('delivery.shipments.manage')
  adminShipments(@Query('status') status?: string, @Query('cityId') cityId?: string, @Query('driverId') driverId?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.delivery.adminShipments({ status, cityId: cityId ? Number(cityId) : undefined, driverId: driverId ? Number(driverId) : undefined, take: take ? Number(take) : undefined, skip: skip ? Number(skip) : undefined });
  }

  @Get('shipments/:id')
  details(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) { return this.delivery.details(user.sub, id); }

  @Patch('shipments/:id/assign')
  @RequirePermissions('delivery.shipments.manage')
  assignShipment(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: AssignShipmentDto) {
    return this.delivery.assignShipment(user.sub, id, dto);
  }

  @Patch('shipments/:id/reschedule')
  @RequirePermissions('delivery.shipments.manage')
  rescheduleShipment(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: { scheduledAt?: string; note?: string }) {
    return this.delivery.rescheduleShipment(user.sub, id, dto);
  }

  @Patch('shipments/:id/driver-accept')
  @RequirePermissions('delivery.shipments.manage')
  driverAccept(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body('note') note?: string) {
    return this.delivery.driverAcceptShipment(user.sub, id, note);
  }

  @Patch('shipments/:id/status')
  @RequirePermissions('delivery.shipments.manage')
  updateStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateShipmentStatusDto) {
    return this.delivery.updateStatus(user.sub, id, dto);
  }
}
