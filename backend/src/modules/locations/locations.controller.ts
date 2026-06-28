import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import {
  CreateAddressDto,
  UpdateAddressDto,
  UpsertCityDeliveryFeeDto,
  UpsertCityDto,
  UpsertDeliveryZoneDto,
  UpsertDistrictDto,
} from './dto/locations.dto';
import { LocationsService } from './locations.service';

@ApiTags('Locations')
@Controller('locations')
export class LocationsController {
  constructor(private readonly locationsService: LocationsService) {}

  @Public()
  @Get('countries')
  countries() {
    return this.locationsService.countries();
  }

  @Public()
  @Get('states')
  states(@Query('countryId') countryId?: string) {
    return this.locationsService.states(countryId ? Number(countryId) : undefined);
  }

  @Public()
  @Get('cities')
  cities(@Query('stateId') stateId?: string) {
    return this.locationsService.cities(stateId ? Number(stateId) : undefined);
  }

  @Public()
  @Get('districts')
  districts(@Query('cityId') cityId?: string) {
    return this.locationsService.districts(cityId ? Number(cityId) : undefined);
  }

  @Public()
  @Get('areas')
  areas(@Query('districtId') districtId?: string) {
    return this.locationsService.areas(districtId ? Number(districtId) : undefined);
  }

  @Public()
  @Get('delivery-fees')
  deliveryFees(@Query('cityId') cityId?: string) {
    return this.locationsService.deliveryFees(cityId ? Number(cityId) : undefined);
  }

  @Public()
  @Get('delivery-zones')
  deliveryZones(@Query('cityId') cityId?: string) {
    return this.locationsService.deliveryZones(cityId ? Number(cityId) : undefined);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('addresses/my')
  myAddresses(@CurrentUser() user: { sub: number }) {
    return this.locationsService.myAddresses(user.sub);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('addresses')
  createAddress(@CurrentUser() user: { sub: number }, @Body() dto: CreateAddressDto) {
    return this.locationsService.createAddress(user.sub, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Patch('addresses/:id')
  updateAddress(@CurrentUser() user: { sub: number }, @Param('id') id: string, @Body() dto: UpdateAddressDto) {
    return this.locationsService.updateAddress(user.sub, id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('addresses/:id')
  deleteAddress(@CurrentUser() user: { sub: number }, @Param('id') id: string) {
    return this.locationsService.deleteAddress(user.sub, id);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Get('admin/cities')
  adminCities() {
    return this.locationsService.adminCities();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Post('admin/cities')
  createCity(@Body() dto: UpsertCityDto) {
    return this.locationsService.createCity(dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Patch('admin/cities/:id')
  updateCity(@Param('id', ParseIntPipe) id: number, @Body() dto: UpsertCityDto) {
    return this.locationsService.updateCity(id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Post('admin/cities/:cityId/districts')
  createDistrict(@Param('cityId', ParseIntPipe) cityId: number, @Body() dto: UpsertDistrictDto) {
    return this.locationsService.createDistrict(cityId, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Patch('admin/districts/:id')
  updateDistrict(@Param('id', ParseIntPipe) id: number, @Body() dto: UpsertDistrictDto) {
    return this.locationsService.updateDistrict(id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Put('admin/cities/:cityId/delivery-fee')
  upsertCityDeliveryFee(@Param('cityId', ParseIntPipe) cityId: number, @Body() dto: UpsertCityDeliveryFeeDto) {
    return this.locationsService.upsertCityDeliveryFee(cityId, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Get('admin/delivery-zones')
  adminDeliveryZones() {
    return this.locationsService.adminDeliveryZones();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Post('admin/delivery-zones')
  createDeliveryZone(@Body() dto: UpsertDeliveryZoneDto) {
    return this.locationsService.createDeliveryZone(dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermissions('manage_location')
  @Patch('admin/delivery-zones/:id')
  updateDeliveryZone(@Param('id', ParseIntPipe) id: number, @Body() dto: UpsertDeliveryZoneDto) {
    return this.locationsService.updateDeliveryZone(id, dto);
  }
}
