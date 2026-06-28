import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { RequirePermissions } from "../../common/decorators/permissions.decorator";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { PermissionsGuard } from "../../common/guards/permissions.guard";
import {
  CreateListingDto,
  UpdateListingDto,
  UpdateListingStatusDto,
} from "../listings/dto/listings.dto";
import { UpdateOrderStatusDto } from "../orders/dto/orders.dto";
import { MerchantService } from "./merchant.service";

@ApiTags("Merchant Operations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller("merchant")
export class MerchantController {
  constructor(private readonly merchant: MerchantService) {}

  @Get("dashboard/summary")
  dashboardSummary(@CurrentUser() user: any) {
    return this.merchant.dashboardSummary(user.sub);
  }

  @Get("inventory")
  @RequirePermissions("merchant.inventory.manage")
  inventory(
    @CurrentUser() user: any,
    @Query("branchId") branchId?: string,
    @Query("branchPublicId") branchPublicId?: string,
    @Query("status") status?: string,
    @Query("search") search?: string,
  ) {
    return this.merchant.inventory(user.sub, {
      branchId,
      branchPublicId,
      status,
      search,
    });
  }

  @Get("branches")
  @RequirePermissions("merchant.branches.manage")
  branches(@CurrentUser() user: any) {
    return this.merchant.branches(user.sub);
  }

  @Get("reports")
  @RequirePermissions("view_reports")
  reports(@CurrentUser() user: any) {
    return this.merchant.reports(user.sub);
  }

  @Get("reports/export")
  @RequirePermissions("view_reports")
  exportReports(
    @CurrentUser() user: any,
    @Query("period") period?: string,
    @Query("type") type?: string,
    @Query("format") format?: string,
    @Query("branchId") branchId?: string,
    @Query("dateFrom") dateFrom?: string,
    @Query("dateTo") dateTo?: string,
  ) {
    return this.merchant.exportReports(user.sub, {
      period,
      type,
      format,
      branchId,
      dateFrom,
      dateTo,
    });
  }

  @Get("finance/summary")
  @RequirePermissions("finance.payments.review")
  financeSummary(@CurrentUser() user: any) {
    return this.merchant.financeSummary(user.sub);
  }

  @Get("finance/ledger")
  @RequirePermissions("finance.accounting.manage")
  financeLedger(@CurrentUser() user: any) {
    return this.merchant.financeLedger(user.sub);
  }

  @Get("finance/statement")
  @RequirePermissions("finance.accounting.manage")
  financeStatement(@CurrentUser() user: any) {
    return this.merchant.financeLedger(user.sub);
  }

  @Get("payments")
  @RequirePermissions("finance.payments.review")
  payments(@CurrentUser() user: any) {
    return this.merchant.payments(user.sub);
  }

  @Get("settlements")
  @RequirePermissions("finance.payments.review")
  settlements(@CurrentUser() user: any) {
    return this.merchant.settlements(user.sub);
  }

  @Get("invoices")
  @RequirePermissions("finance.payments.review")
  invoices(@CurrentUser() user: any) {
    return this.merchant.invoices(user.sub);
  }

  @Get("notifications")
  merchantNotifications(@CurrentUser() user: any) {
    return this.merchant.notifications(user.sub);
  }

  @Patch("notifications/read")
  markNotificationRead(@CurrentUser() user: any, @Body("key") key?: string) {
    return this.merchant.markNotificationRead(user.sub, key);
  }

  @Patch("notifications/read-all")
  markAllNotificationsRead(@CurrentUser() user: any) {
    return this.merchant.markAllNotificationsRead(user.sub);
  }

  @Get("notifications/preferences")
  notificationPreferences() {
    return {
      success: true,
      data: {
        order_updates: true,
        low_stock: true,
        finance: true,
        reviews: true,
        support: true,
      },
    };
  }

  @Patch("notifications/preferences")
  updateNotificationPreferences(@Body() dto: any) {
    return { success: true, data: dto ?? {} };
  }

  @Put("notifications/preferences")
  replaceNotificationPreferences(@Body() dto: any) {
    return { success: true, data: dto ?? {} };
  }

  @Get("returns")
  returns(
    @CurrentUser() user: any,
    @Query("status") status?: string,
    @Query("q") query?: string,
  ) {
    return this.merchant.returns(user.sub, { status, query });
  }

  @Get("returns/:id")
  returnDetails(@CurrentUser() user: any, @Param("id") id: string) {
    return this.merchant.returnDetails(user.sub, id);
  }

  @Patch("returns/:id/status")
  updateReturnStatus(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("status") status?: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.updateReturnStatus(user.sub, id, status, note);
  }

  @Patch("returns/:id/decision")
  decideReturn(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("decision") decision?: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.decideReturn(user.sub, id, decision, note);
  }

  @Patch("returns/:id/receive")
  receiveReturn(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.receiveReturn(user.sub, id, note);
  }

  @Patch("returns/:id/refund")
  refundReturn(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.refundReturn(user.sub, id, note);
  }

  @Get("disputes")
  disputes(
    @CurrentUser() user: any,
    @Query("status") status?: string,
    @Query("q") query?: string,
  ) {
    return this.merchant.disputes(user.sub, { status, query });
  }

  @Get("disputes/:id")
  disputeDetails(@CurrentUser() user: any, @Param("id") id: string) {
    return this.merchant.disputeDetails(user.sub, id);
  }

  @Patch("disputes/:id/status")
  updateDisputeStatus(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("status") status?: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.updateDisputeStatus(user.sub, id, status, note);
  }

  @Post("disputes/:id/messages")
  addDisputeMessage(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("message") message?: string,
  ) {
    return this.merchant.addDisputeMessage(user.sub, id, message);
  }

  @Patch("disputes/:id/resolve")
  resolveDispute(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("resolution") resolution?: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.resolveDispute(user.sub, id, resolution, note);
  }

  @Get("support-tickets")
  supportTickets(
    @CurrentUser() user: any,
    @Query("status") status?: string,
    @Query("q") query?: string,
  ) {
    return this.merchant.supportTickets(user.sub, { status, query });
  }

  @Get("support-tickets/:id")
  supportTicketDetails(@CurrentUser() user: any, @Param("id") id: string) {
    return this.merchant.supportTicketDetails(user.sub, id);
  }

  @Post("support-tickets/:id/messages")
  addSupportTicketMessage(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("message") message?: string,
    @Body("attachmentUrl") attachmentUrl?: string,
  ) {
    return this.merchant.addSupportTicketMessage(
      user.sub,
      id,
      message,
      attachmentUrl,
    );
  }

  @Patch("support-tickets/:id/read")
  markSupportTicketRead(@CurrentUser() user: any, @Param("id") id: string) {
    return this.merchant.markSupportTicketRead(user.sub, id);
  }

  @Patch("support-tickets/:id/status")
  updateSupportTicketStatus(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body("status") status?: string,
    @Body("note") note?: string,
  ) {
    return this.merchant.updateSupportTicketStatus(user.sub, id, status, note);
  }

  @Get("reviews")
  reviews(@CurrentUser() user: any) {
    return this.merchant.reviews(user.sub);
  }

  @Post("reviews/:type/:id/replies")
  replyToReview(
    @CurrentUser() user: any,
    @Param("type") type: string,
    @Param("id") id: string,
    @Body("replyText") replyText?: string,
  ) {
    return this.merchant.replyToReview(user.sub, type, id, replyText);
  }

  @Get("listings") listings(@CurrentUser() user: any) {
    return this.merchant.myListings(user.sub);
  }
  @Post("listings") createListing(
    @CurrentUser() user: any,
    @Body() dto: CreateListingDto,
  ) {
    return this.merchant.createListing(user.sub, dto);
  }
  @Patch("listings/:id") updateListing(
    @CurrentUser() user: any,
    @Param("id", ParseIntPipe) id: number,
    @Body() dto: UpdateListingDto,
  ) {
    return this.merchant.updateListing(user.sub, id, dto);
  }
  @Patch("listings/:id/status") updateListingStatus(
    @CurrentUser() user: any,
    @Param("id", ParseIntPipe) id: number,
    @Body() dto: UpdateListingStatusDto,
  ) {
    return this.merchant.updateListingStatus(user.sub, id, dto);
  }
  @Get("orders")
  @RequirePermissions("merchant.orders.manage")
  orders(@CurrentUser() user: any) {
    return this.merchant.orders(user.sub);
  }
  @Get("orders/:id")
  @RequirePermissions("merchant.orders.manage")
  orderDetails(
    @CurrentUser() user: any,
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.merchant.orderDetails(user.sub, id);
  }

  @Patch("orders/:id/status")
  @RequirePermissions("merchant.orders.manage")
  updateOrderStatus(
    @CurrentUser() user: any,
    @Param("id", ParseIntPipe) id: number,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.merchant.updateOrderStatus(user.sub, id, dto);
  }
}
