import { Body, Controller, Get, Headers, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import {
  CreateManualServicePaymentDto,
  CreateOrderPaymentDto,
  CreateRefundDto,
  CreateSettlementDto,
  MarkPaymentDto,
  PaymentWebhookDto,
  ReviewPaymentProofDto,
  ReviewRefundDto,
  UploadPaymentProofDto,
} from './dto/payments.dto';
import { PaymentsService } from './payments.service';

@ApiTags('Payments & Finance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller()
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Get('payments/methods')
  methods() { return this.payments.paymentMethods(); }

  @Post('payments/orders/:id/intents')
  @RequirePermissions('orders.view_own')
  createOrderPaymentIntent(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateOrderPaymentDto) {
    return this.payments.createOrderPayment(user.sub, id, dto);
  }

  // Backward-compatible endpoint used by existing Flutter pages.
  @Post('payments/orders/:id/transactions')
  @RequirePermissions('orders.view_own')
  createOrderPayment(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateOrderPaymentDto) {
    return this.payments.createOrderPayment(user.sub, id, dto);
  }

  @Get('payments/orders/:id/transactions')
  @RequirePermissions('orders.view_own')
  orderTransactions(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.payments.orderTransactions(user.sub, id);
  }

  @Get('payments/my')
  @RequirePermissions('orders.view_own')
  myPayments(@CurrentUser() user: any) {
    return this.payments.myPayments(user.sub);
  }

  @Post('payments/:id/proofs')
  @RequirePermissions('orders.view_own')
  uploadProof(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UploadPaymentProofDto) {
    return this.payments.uploadProof(user.sub, id, dto);
  }

  @Patch('payments/transactions/:id/paid')
  @RequirePermissions('finance.payments.review')
  markPaid(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: MarkPaymentDto) {
    return this.payments.markTransactionPaid(user.sub, id, dto);
  }

  @Patch('payments/transactions/:id/failed')
  @RequirePermissions('finance.payments.review')
  markFailed(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: MarkPaymentDto) {
    return this.payments.markTransactionFailed(user.sub, id, dto);
  }

  @Post('payments/service-orders/:id/transactions')
  @RequirePermissions('workshop.service_orders.manage')
  createServicePayment(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateManualServicePaymentDto) {
    return this.payments.createServiceOrderPayment(user.sub, id, dto);
  }

  @Public()
  @Post('payments/webhooks/:provider')
  webhook(@Param('provider') provider: string, @Body() dto: PaymentWebhookDto, @Headers('x-payment-signature') signature?: string) {
    return this.payments.receiveWebhook(provider, dto, signature);
  }

  @Get('finance/payments')
  @RequirePermissions('finance.payments.review')
  financePayments(@Query('status') status?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.payments.financePayments({ status, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Get('finance/payment-proofs')
  @RequirePermissions('finance.payments.review')
  financeProofs(@Query('status') status?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.payments.financeProofs({ status, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Post('finance/payment-proofs/:id/approve')
  @RequirePermissions('finance.payments.review')
  approveProof(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReviewPaymentProofDto) {
    return this.payments.approveProof(user.sub, id, dto);
  }

  @Post('finance/payment-proofs/:id/reject')
  @RequirePermissions('finance.payments.review')
  rejectProof(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReviewPaymentProofDto) {
    return this.payments.rejectProof(user.sub, id, dto);
  }

  @Post('refunds')
  @RequirePermissions('orders.view_own')
  requestRefund(@CurrentUser() user: any, @Body() dto: CreateRefundDto) {
    return this.payments.createRefund(user.sub, dto);
  }

  @Get('finance/refunds')
  @RequirePermissions('finance.payments.review')
  refunds(@Query('status') status?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.payments.financeRefunds({ status, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Post('finance/refunds/:id/approve')
  @RequirePermissions('finance.payments.review')
  approveRefund(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReviewRefundDto) {
    return this.payments.approveRefund(user.sub, id, dto);
  }

  @Post('finance/refunds/:id/reject')
  @RequirePermissions('finance.payments.review')
  rejectRefund(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReviewRefundDto) {
    return this.payments.rejectRefund(user.sub, id, dto);
  }

  @Post('finance/refunds/:id/mark-refunded')
  @RequirePermissions('finance.payments.review')
  markRefunded(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: ReviewRefundDto) {
    return this.payments.markRefunded(user.sub, id, dto);
  }

  @Get('finance/settlements')
  @RequirePermissions('finance.payments.review')
  settlements(@Query('status') status?: string, @Query('organizationId') organizationId?: string, @Query('take') take?: string, @Query('skip') skip?: string) {
    return this.payments.settlements({ status, organizationId: organizationId ? Number(organizationId) : undefined, take: Number(take || 50), skip: Number(skip || 0) });
  }

  @Post('finance/settlements')
  @RequirePermissions('finance.payments.review')
  createSettlement(@CurrentUser() user: any, @Body() dto: CreateSettlementDto) {
    return this.payments.createSettlement(user.sub, dto);
  }

  @Post('finance/settlements/:id/approve')
  @RequirePermissions('finance.payments.review')
  approveSettlement(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.payments.approveSettlement(user.sub, id);
  }

  @Post('finance/settlements/:id/mark-paid')
  @RequirePermissions('finance.payments.review')
  markSettlementPaid(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.payments.markSettlementPaid(user.sub, id);
  }
}
