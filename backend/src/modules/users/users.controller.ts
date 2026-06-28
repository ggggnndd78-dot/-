import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateUserLocaleDto } from '../system/dto/localization.dto';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getMe(@CurrentUser() user: { sub: number }) {
    return this.usersService.me(user.sub);
  }

  @Patch('profile')
  updateProfile(@CurrentUser() user: { sub: number }, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.sub, dto);
  }

  @Patch('locale')
  updateLocale(@CurrentUser() user: { sub: number }, @Body() dto: UpdateUserLocaleDto) {
    return this.usersService.updateLocale(user.sub, dto.locale);
  }

  @Patch('location')
  updateLocation(@CurrentUser() user: { sub: number }, @Body() dto: UpdateLocationDto) {
    return this.usersService.updateLocation(user.sub, dto);
  }
}
