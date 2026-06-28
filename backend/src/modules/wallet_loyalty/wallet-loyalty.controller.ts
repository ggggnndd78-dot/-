import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
  ApplyReferralDto,
  AwardPointsDto,
  CreateCouponDto,
  CreateRetentionCampaignDto,
  QualifyReferralDto,
  RedeemCouponDto,
  RedeemPointsDto,
  ReversePointsDto,
  UpdateCouponStatusDto,
  ValidateCouponDto,
  WalletAdjustmentDto,
  WalletTopUpDto,
} from './dto/wallet-loyalty.dto';
import { WalletLoyaltyService } from './wallet-loyalty.service';

@ApiTags('Wallet')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletLoyalty: WalletLoyaltyService) {}

  @Get('me')
  me(@CurrentUser() user: any) { return this.walletLoyalty.myWallet(user.sub); }

  @Get('me/ledger')
  ledger(@CurrentUser() user: any, @Query('take') take?: string) { return this.walletLoyalty.myWalletLedger(user.sub, Number(take || 50)); }

  @Post('me/topups')
  topUp(@CurrentUser() user: any, @Body() dto: WalletTopUpDto) { return this.walletLoyalty.requestWalletTopUp(user.sub, dto); }

  @Patch('topups/:transactionId/approve')
  approveTopUp(@CurrentUser() user: any, @Param('transactionId', ParseIntPipe) id: number) { return this.walletLoyalty.approveWalletTopUp(user.sub, id); }

  @Post('orders/:id/pay')
  payOrder(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) { return this.walletLoyalty.payOrderWithWallet(user.sub, id); }

  @Post('service-orders/:id/pay')
  payServiceOrder(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) { return this.walletLoyalty.payServiceOrderWithWallet(user.sub, id); }

  @Post('admin/adjust')
  adjust(@CurrentUser() user: any, @Body() dto: WalletAdjustmentDto) { return this.walletLoyalty.adminAdjustWallet(user.sub, dto); }
}

@ApiTags('Loyalty')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('loyalty')
export class LoyaltyController {
  constructor(private readonly walletLoyalty: WalletLoyaltyService) {}

  @Get('me')
  me(@CurrentUser() user: any) { return this.walletLoyalty.myLoyalty(user.sub); }

  @Get('me/transactions')
  tx(@CurrentUser() user: any) { return this.walletLoyalty.myLoyaltyTransactions(user.sub); }

  @Post('redeem-to-wallet')
  redeem(@CurrentUser() user: any, @Body() dto: RedeemPointsDto) { return this.walletLoyalty.redeemPointsToWallet(user.sub, dto); }

  @Post('orders/:id/reward')
  rewardOrder(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: AwardPointsDto) { return this.walletLoyalty.awardOrderPoints(user.sub, id, dto); }

  @Post('orders/:id/reverse')
  reverseOrder(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReversePointsDto) { return this.walletLoyalty.reverseOrderPoints(user.sub, id, dto); }

  @Post('service-orders/:id/reward')
  rewardService(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: AwardPointsDto) { return this.walletLoyalty.awardServiceOrderPoints(user.sub, id, dto); }

  @Get('coupons')
  coupons() { return this.walletLoyalty.activeCoupons(); }

  @Get('coupons/manage')
  adminCoupons(@CurrentUser() user: any) { return this.walletLoyalty.adminCoupons(user.sub); }

  @Post('coupons')
  createCoupon(@CurrentUser() user: any, @Body() dto: CreateCouponDto) { return this.walletLoyalty.createCoupon(user.sub, dto); }

  @Patch('coupons/:id/status')
  updateCouponStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateCouponStatusDto) { return this.walletLoyalty.updateCouponStatus(user.sub, id, dto); }

  @Post('coupons/validate')
  validateCoupon(@CurrentUser() user: any, @Body() dto: ValidateCouponDto) { return this.walletLoyalty.validateCoupon(user.sub, dto); }

  @Post('orders/:id/coupons/redeem')
  redeemOrderCoupon(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: RedeemCouponDto) { return this.walletLoyalty.redeemOrderCoupon(user.sub, id, dto); }

  @Post('service-orders/:id/coupons/redeem')
  redeemServiceCoupon(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: RedeemCouponDto) { return this.walletLoyalty.redeemServiceOrderCoupon(user.sub, id, dto); }
}

@ApiTags('Referrals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('referrals')
export class ReferralController {
  constructor(private readonly walletLoyalty: WalletLoyaltyService) {}

  @Get('me')
  dashboard(@CurrentUser() user: any) { return this.walletLoyalty.myReferralDashboard(user.sub); }

  @Post('me/code')
  createCode(@CurrentUser() user: any) { return this.walletLoyalty.ensureReferralCode(user.sub); }

  @Post('apply')
  apply(@CurrentUser() user: any, @Body() dto: ApplyReferralDto) { return this.walletLoyalty.applyReferralCode(user.sub, dto); }

  @Post(':relationshipId/qualify')
  qualify(@CurrentUser() user: any, @Param('relationshipId', ParseIntPipe) id: number, @Body() dto: QualifyReferralDto) { return this.walletLoyalty.qualifyReferral(user.sub, id, dto); }
}

@ApiTags('Retention')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('retention')
export class RetentionController {
  constructor(private readonly walletLoyalty: WalletLoyaltyService) {}

  @Get('campaigns/manage')
  campaigns(@CurrentUser() user: any) { return this.walletLoyalty.manageCampaigns(user.sub); }

  @Post('campaigns')
  create(@CurrentUser() user: any, @Body() dto: CreateRetentionCampaignDto) { return this.walletLoyalty.createCampaign(user.sub, dto); }

  @Post('campaigns/:id/dispatch')
  dispatch(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) { return this.walletLoyalty.dispatchCampaign(user.sub, id); }
}
