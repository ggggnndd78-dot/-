import { Body, Controller, Delete, Get, Headers, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import { CreateGuestSessionDto } from './dto/create-guest-session.dto';
import { GuestSessionLocationDto } from './dto/guest-session-location.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterBusinessDto, RegisterCustomerDto } from './dto/registration.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { StartPhoneLoginDto, ValidateSessionDto, VerifyTrustedDeviceOtpDto } from './dto/trusted-device.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';

function requestMeta(req: Request, locale?: string) {
  return {
    ipAddress: (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || null,
    userAgent: req.headers['user-agent'] ?? null,
    locale: locale ?? null,
  };
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login/start')
  startPhoneLogin(@Body() dto: StartPhoneLoginDto, @Req() req: Request, @Headers('accept-language') locale?: string) {
    return this.authService.startPhoneLogin(dto, requestMeta(req, locale));
  }

  @Public()
  @Post('login/verify-device-otp')
  verifyTrustedDeviceOtp(@Body() dto: VerifyTrustedDeviceOtpDto, @Req() req: Request, @Headers('accept-language') locale?: string) {
    return this.authService.verifyTrustedDeviceOtp(dto, requestMeta(req, locale));
  }

  @Public()
  @Post('register/customer')
  registerCustomer(@Body() dto: RegisterCustomerDto, @Req() req: Request, @Headers('accept-language') locale?: string) {
    return this.authService.registerCustomer(dto, requestMeta(req, locale));
  }

  @Public()
  @Post('register/business')
  registerBusiness(@Body() dto: RegisterBusinessDto, @Req() req: Request, @Headers('accept-language') locale?: string) {
    return this.authService.registerBusiness(dto, requestMeta(req, locale));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('session/validate')
  validateSession(@CurrentUser() user: { sub: number }, @Body() dto: ValidateSessionDto, @Req() req: Request) {
    return this.authService.validateSession(user.sub, dto, requestMeta(req));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('devices')
  listTrustedDevices(@CurrentUser() user: { sub: number }) {
    return this.authService.listTrustedDevices(user.sub);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('devices/:id')
  revokeTrustedDevice(@CurrentUser() user: { sub: number }, @Param('id') id: string, @Req() req: Request) {
    return this.authService.revokeTrustedDevice(user.sub, id, requestMeta(req));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('logout-all-devices')
  logoutAllDevices(@CurrentUser() user: { sub: number }, @Req() req: Request) {
    return this.authService.logoutAllDevices(user.sub, requestMeta(req));
  }

  @Public()
  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto, @Headers('accept-language') locale?: string) {
    return this.authService.requestOtp(dto, locale);
  }

  @Public()
  @Post('verify-otp')
  verifyOtp(@Body() dto: VerifyOtpDto, @Headers('accept-language') locale?: string) {
    return this.authService.verifyOtp(dto, locale);
  }

  @Public()
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Public()
  @Post('guest-sessions')
  createGuestSession(@Body() dto: CreateGuestSessionDto = {}) {
    return this.authService.createGuestSession(dto);
  }

  @Public()
  @Patch('guest-sessions/location')
  updateGuestSessionLocation(@Body() dto: GuestSessionLocationDto) {
    return this.authService.updateGuestSessionLocation(dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('logout')
  logout(@CurrentUser() user: { sub: number }, @Body() dto?: Partial<RefreshTokenDto>) {
    return this.authService.logout(user.sub, dto?.refreshToken);
  }
}
