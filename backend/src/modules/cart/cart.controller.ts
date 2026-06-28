import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { AddCartItemDto, UpdateCartItemDto } from './dto/cart.dto';
import { CartService } from './cart.service';

@ApiTags('Cart')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@RequirePermissions('cart.manage')
@Controller('cart')
export class CartController {
  constructor(private readonly cart: CartService) {}
  @Get() getCart(@CurrentUser() user: any) { return this.cart.getCart(user.sub); }
  @Post('items') addItem(@CurrentUser() user: any, @Body() dto: AddCartItemDto) { return this.cart.addItem(user.sub, dto); }
  @Patch('items/:id') updateItem(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateCartItemDto) { return this.cart.updateItem(user.sub, id, dto); }
  @Delete('items/:id') removeItem(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) { return this.cart.removeItem(user.sub, id); }
  @Delete() clear(@CurrentUser() user: any) { return this.cart.clear(user.sub); }
}
