import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { VehiclesService } from './vehicles.service';

@ApiTags('Vehicles')
@Controller()
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Public()
  @Get('vehicles/makes')
  makes() { return this.vehiclesService.makes(); }

  @Public()
  @Get('vehicles/brands')
  brands() { return this.vehiclesService.makes(); }

  @Public()
  @Get('vehicles/models')
  models(@Query('makeId') makeId?: string, @Query('brandId') brandId?: string) {
    return this.vehiclesService.models(makeId ? Number(makeId) : brandId ? Number(brandId) : undefined);
  }

  @Public()
  @Get('vehicles/years')
  years(@Query('modelId') modelId?: string) {
    return this.vehiclesService.years(modelId ? Number(modelId) : undefined);
  }

  @Public()
  @Get('vehicles/variants')
  variants(@Query('modelId') modelId?: string, @Query('year') year?: string) {
    return this.vehiclesService.variants(modelId ? Number(modelId) : undefined, year ? Number(year) : undefined);
  }

  @Public()
  @Get('vehicles/trims')
  trims(@Query('modelId') modelId?: string, @Query('year') year?: string) {
    return this.vehiclesService.variants(modelId ? Number(modelId) : undefined, year ? Number(year) : undefined);
  }

  @Public()
  @Get('vehicles/engines')
  engines(@Query('modelId') modelId?: string, @Query('year') year?: string) {
    return this.vehiclesService.engines(modelId ? Number(modelId) : undefined, year ? Number(year) : undefined);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me/vehicles')
  myVehicles(@CurrentUser() user: { sub: number }) { return this.vehiclesService.myVehicles(user.sub); }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('me/vehicles')
  create(@CurrentUser() user: { sub: number }, @Body() dto: CreateVehicleDto) { return this.vehiclesService.create(user.sub, dto); }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Patch('me/vehicles/:id')
  update(@CurrentUser() user: { sub: number }, @Param('id') id: string, @Body() dto: UpdateVehicleDto) { return this.vehiclesService.update(user.sub, id, dto); }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('me/vehicles/:id')
  remove(@CurrentUser() user: { sub: number }, @Param('id') id: string) { return this.vehiclesService.remove(user.sub, id); }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('me/vehicles/:id/set-default')
  setDefault(@CurrentUser() user: { sub: number }, @Param('id') id: string) { return this.vehiclesService.setDefault(user.sub, id); }
}
