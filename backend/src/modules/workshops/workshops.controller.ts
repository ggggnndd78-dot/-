import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import {
  BookingSlotsQueryDto,
  CancelWorkshopBookingDto,
  CreateBookingSlotDto,
  CreateDiagnosticReportDto,
  CreateMaintenanceRecordDto,
  CreateServiceOrderFromBookingDto,
  CreateWorkshopBookingDto,
  CreateWorkshopServiceDto,
  CreateWorkshopTechnicianDto,
  SubmitWorkshopRatingDto,
  UpdateServiceOrderStatusDto,
  UpdateWorkshopBookingStatusDto,
  UpdateWorkshopServiceDto,
  UpdateWorkshopServiceStatusDto,
  WorkshopServicesQueryDto,
} from './dto/workshops.dto';
import { WorkshopsService } from './workshops.service';

@ApiTags('Workshop Services')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller()
export class WorkshopsController {
  constructor(private readonly workshops: WorkshopsService) {}


  @Get('workshops/service-categories')
  serviceCategories() {
    return this.workshops.serviceCategories();
  }

  @Get('workshops/catalog-services')
  catalogServices(@Query() query: WorkshopServicesQueryDto) {
    return this.workshops.serviceCatalog(query);
  }

  @Get('workshops/booking-slots')
  bookingSlots(@Query() query: BookingSlotsQueryDto) {
    return this.workshops.bookingSlots(query);
  }

  @Get('workshops/services')
  services(@Query() query: WorkshopServicesQueryDto) {
    return this.workshops.searchServices(query);
  }

  @Get('workshops/services/:id')
  serviceDetails(@Param('id', ParseIntPipe) id: number) {
    return this.workshops.serviceDetails(id);
  }

  @Post('workshops/bookings')
  @RequirePermissions('workshop.bookings.create')
  createBooking(@CurrentUser() user: { sub: number }, @Body() dto: CreateWorkshopBookingDto) {
    return this.workshops.createBooking(user.sub, dto);
  }

  @Get('workshops/bookings/my')
  @RequirePermissions('workshop.bookings.create')
  myBookings(@CurrentUser() user: { sub: number }) {
    return this.workshops.myBookings(user.sub);
  }

  @Get('workshops/bookings/:id')
  @RequirePermissions('workshop.bookings.create')
  bookingDetails(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number) {
    return this.workshops.customerBookingDetails(user.sub, id);
  }

  @Patch('workshops/bookings/:id/cancel')
  @RequirePermissions('workshop.bookings.create')
  cancelBooking(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: CancelWorkshopBookingDto) {
    return this.workshops.cancelBooking(user.sub, id, dto);
  }



  @Post('workshops/bookings/:id/rating')
  @RequirePermissions('workshop.bookings.create')
  submitRating(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: SubmitWorkshopRatingDto) {
    return this.workshops.submitRating(user.sub, id, dto);
  }

  @Get('workshops/maintenance-records/my')
  @RequirePermissions('workshop.bookings.create')
  myMaintenanceRecords(@CurrentUser() user: { sub: number }) {
    return this.workshops.myMaintenanceRecords(user.sub);
  }

  @Get('workshop/operations/services')
  @RequirePermissions('workshop.services.manage')
  myServices(@CurrentUser() user: { sub: number }) {
    return this.workshops.myWorkshopServices(user.sub);
  }

  @Post('workshop/operations/services')
  @RequirePermissions('workshop.services.manage')
  createService(@CurrentUser() user: { sub: number }, @Body() dto: CreateWorkshopServiceDto) {
    return this.workshops.createService(user.sub, dto);
  }

  @Patch('workshop/operations/services/:id')
  @RequirePermissions('workshop.services.manage')
  updateService(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateWorkshopServiceDto) {
    return this.workshops.updateService(user.sub, id, dto);
  }

  @Patch('workshop/operations/services/:id/status')
  @RequirePermissions('workshop.services.manage')
  updateServiceStatus(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateWorkshopServiceStatusDto) {
    return this.workshops.updateServiceStatus(user.sub, id, dto);
  }

  @Get('workshop/operations/technicians')
  @RequirePermissions('workshop.service_orders.manage')
  technicians(@CurrentUser() user: { sub: number }) {
    return this.workshops.myTechnicians(user.sub);
  }

  @Post('workshop/operations/technicians')
  @RequirePermissions('workshop.service_orders.manage')
  createTechnician(@CurrentUser() user: { sub: number }, @Body() dto: CreateWorkshopTechnicianDto) {
    return this.workshops.createTechnician(user.sub, dto);
  }


  @Get('workshop/operations/booking-slots')
  @RequirePermissions('workshop.bookings.manage')
  workshopBookingSlots(@CurrentUser() user: { sub: number }, @Query() query: Partial<BookingSlotsQueryDto>) {
    return this.workshops.myWorkshopBookingSlots(user.sub, query);
  }

  @Post('workshop/operations/booking-slots')
  @RequirePermissions('workshop.bookings.manage')
  createBookingSlot(@CurrentUser() user: { sub: number }, @Body() dto: CreateBookingSlotDto) {
    return this.workshops.createBookingSlot(user.sub, dto);
  }

  @Get('workshop/operations/bookings')
  @RequirePermissions('workshop.bookings.manage')
  workshopBookings(@CurrentUser() user: { sub: number }) {
    return this.workshops.workshopBookings(user.sub);
  }

  @Patch('workshop/operations/bookings/:id/status')
  @RequirePermissions('workshop.bookings.manage')
  updateBookingStatus(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateWorkshopBookingStatusDto) {
    return this.workshops.updateBookingStatus(user.sub, id, dto);
  }

  @Post('workshop/operations/bookings/:id/service-order')
  @RequirePermissions('workshop.service_orders.manage')
  createServiceOrderFromBooking(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateServiceOrderFromBookingDto) {
    return this.workshops.createServiceOrderFromBooking(user.sub, id, dto);
  }

  @Get('workshop/operations/service-orders')
  @RequirePermissions('workshop.service_orders.manage')
  serviceOrders(@CurrentUser() user: { sub: number }) {
    return this.workshops.workshopServiceOrders(user.sub);
  }

  @Patch('workshop/operations/service-orders/:id/status')
  @RequirePermissions('workshop.service_orders.manage')
  updateServiceOrderStatus(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateServiceOrderStatusDto) {
    return this.workshops.updateServiceOrderStatus(user.sub, id, dto);
  }

  @Post('workshop/operations/service-orders/:id/diagnostics')
  @RequirePermissions('workshop.service_orders.manage')
  createDiagnosticReport(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateDiagnosticReportDto) {
    return this.workshops.createDiagnosticReport(user.sub, id, dto);
  }

  @Post('workshop/operations/service-orders/:id/maintenance-record')
  @RequirePermissions('workshop.service_orders.manage')
  createMaintenanceRecord(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateMaintenanceRecordDto) {
    return this.workshops.createMaintenanceRecord(user.sub, id, dto);
  }
}
