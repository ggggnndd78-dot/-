"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MerchantController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const current_user_decorator_1 = require("../../common/decorators/current-user.decorator");
const permissions_decorator_1 = require("../../common/decorators/permissions.decorator");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const permissions_guard_1 = require("../../common/guards/permissions.guard");
const listings_dto_1 = require("../listings/dto/listings.dto");
const orders_dto_1 = require("../orders/dto/orders.dto");
const merchant_service_1 = require("./merchant.service");
let MerchantController = class MerchantController {
    constructor(merchant) {
        this.merchant = merchant;
    }
    dashboardSummary(user) {
        return this.merchant.dashboardSummary(user.sub);
    }
    inventory(user, branchId, branchPublicId, status, search) {
        return this.merchant.inventory(user.sub, {
            branchId,
            branchPublicId,
            status,
            search,
        });
    }
    branches(user) {
        return this.merchant.branches(user.sub);
    }
    reports(user) {
        return this.merchant.reports(user.sub);
    }
    exportReports(user, period, type, format, branchId, dateFrom, dateTo) {
        return this.merchant.exportReports(user.sub, {
            period,
            type,
            format,
            branchId,
            dateFrom,
            dateTo,
        });
    }
    financeSummary(user) {
        return this.merchant.financeSummary(user.sub);
    }
    financeLedger(user) {
        return this.merchant.financeLedger(user.sub);
    }
    financeStatement(user) {
        return this.merchant.financeLedger(user.sub);
    }
    payments(user) {
        return this.merchant.payments(user.sub);
    }
    settlements(user) {
        return this.merchant.settlements(user.sub);
    }
    invoices(user) {
        return this.merchant.invoices(user.sub);
    }
    merchantNotifications(user) {
        return this.merchant.notifications(user.sub);
    }
    markNotificationRead(user, key) {
        return this.merchant.markNotificationRead(user.sub, key);
    }
    markAllNotificationsRead(user) {
        return this.merchant.markAllNotificationsRead(user.sub);
    }
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
    updateNotificationPreferences(dto) {
        return { success: true, data: dto ?? {} };
    }
    replaceNotificationPreferences(dto) {
        return { success: true, data: dto ?? {} };
    }
    returns(user, status, query) {
        return this.merchant.returns(user.sub, { status, query });
    }
    returnDetails(user, id) {
        return this.merchant.returnDetails(user.sub, id);
    }
    updateReturnStatus(user, id, status, note) {
        return this.merchant.updateReturnStatus(user.sub, id, status, note);
    }
    decideReturn(user, id, decision, note) {
        return this.merchant.decideReturn(user.sub, id, decision, note);
    }
    receiveReturn(user, id, note) {
        return this.merchant.receiveReturn(user.sub, id, note);
    }
    refundReturn(user, id, note) {
        return this.merchant.refundReturn(user.sub, id, note);
    }
    disputes(user, status, query) {
        return this.merchant.disputes(user.sub, { status, query });
    }
    disputeDetails(user, id) {
        return this.merchant.disputeDetails(user.sub, id);
    }
    updateDisputeStatus(user, id, status, note) {
        return this.merchant.updateDisputeStatus(user.sub, id, status, note);
    }
    addDisputeMessage(user, id, message) {
        return this.merchant.addDisputeMessage(user.sub, id, message);
    }
    resolveDispute(user, id, resolution, note) {
        return this.merchant.resolveDispute(user.sub, id, resolution, note);
    }
    supportTickets(user, status, query) {
        return this.merchant.supportTickets(user.sub, { status, query });
    }
    supportTicketDetails(user, id) {
        return this.merchant.supportTicketDetails(user.sub, id);
    }
    addSupportTicketMessage(user, id, message, attachmentUrl) {
        return this.merchant.addSupportTicketMessage(user.sub, id, message, attachmentUrl);
    }
    markSupportTicketRead(user, id) {
        return this.merchant.markSupportTicketRead(user.sub, id);
    }
    updateSupportTicketStatus(user, id, status, note) {
        return this.merchant.updateSupportTicketStatus(user.sub, id, status, note);
    }
    reviews(user) {
        return this.merchant.reviews(user.sub);
    }
    replyToReview(user, type, id, replyText) {
        return this.merchant.replyToReview(user.sub, type, id, replyText);
    }
    listings(user) {
        return this.merchant.myListings(user.sub);
    }
    createListing(user, dto) {
        return this.merchant.createListing(user.sub, dto);
    }
    updateListing(user, id, dto) {
        return this.merchant.updateListing(user.sub, id, dto);
    }
    updateListingStatus(user, id, dto) {
        return this.merchant.updateListingStatus(user.sub, id, dto);
    }
    orders(user) {
        return this.merchant.orders(user.sub);
    }
    orderDetails(user, id) {
        return this.merchant.orderDetails(user.sub, id);
    }
    updateOrderStatus(user, id, dto) {
        return this.merchant.updateOrderStatus(user.sub, id, dto);
    }
};
exports.MerchantController = MerchantController;
__decorate([
    (0, common_1.Get)("dashboard/summary"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "dashboardSummary", null);
__decorate([
    (0, common_1.Get)("inventory"),
    (0, permissions_decorator_1.RequirePermissions)("merchant.inventory.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("branchId")),
    __param(2, (0, common_1.Query)("branchPublicId")),
    __param(3, (0, common_1.Query)("status")),
    __param(4, (0, common_1.Query)("search")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "inventory", null);
__decorate([
    (0, common_1.Get)("branches"),
    (0, permissions_decorator_1.RequirePermissions)("merchant.branches.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "branches", null);
__decorate([
    (0, common_1.Get)("reports"),
    (0, permissions_decorator_1.RequirePermissions)("view_reports"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "reports", null);
__decorate([
    (0, common_1.Get)("reports/export"),
    (0, permissions_decorator_1.RequirePermissions)("view_reports"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("period")),
    __param(2, (0, common_1.Query)("type")),
    __param(3, (0, common_1.Query)("format")),
    __param(4, (0, common_1.Query)("branchId")),
    __param(5, (0, common_1.Query)("dateFrom")),
    __param(6, (0, common_1.Query)("dateTo")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "exportReports", null);
__decorate([
    (0, common_1.Get)("finance/summary"),
    (0, permissions_decorator_1.RequirePermissions)("finance.payments.review"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "financeSummary", null);
__decorate([
    (0, common_1.Get)("finance/ledger"),
    (0, permissions_decorator_1.RequirePermissions)("finance.accounting.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "financeLedger", null);
__decorate([
    (0, common_1.Get)("finance/statement"),
    (0, permissions_decorator_1.RequirePermissions)("finance.accounting.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "financeStatement", null);
__decorate([
    (0, common_1.Get)("payments"),
    (0, permissions_decorator_1.RequirePermissions)("finance.payments.review"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "payments", null);
__decorate([
    (0, common_1.Get)("settlements"),
    (0, permissions_decorator_1.RequirePermissions)("finance.payments.review"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "settlements", null);
__decorate([
    (0, common_1.Get)("invoices"),
    (0, permissions_decorator_1.RequirePermissions)("finance.payments.review"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "invoices", null);
__decorate([
    (0, common_1.Get)("notifications"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "merchantNotifications", null);
__decorate([
    (0, common_1.Patch)("notifications/read"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)("key")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "markNotificationRead", null);
__decorate([
    (0, common_1.Patch)("notifications/read-all"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "markAllNotificationsRead", null);
__decorate([
    (0, common_1.Get)("notifications/preferences"),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "notificationPreferences", null);
__decorate([
    (0, common_1.Patch)("notifications/preferences"),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateNotificationPreferences", null);
__decorate([
    (0, common_1.Put)("notifications/preferences"),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "replaceNotificationPreferences", null);
__decorate([
    (0, common_1.Get)("returns"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("status")),
    __param(2, (0, common_1.Query)("q")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "returns", null);
__decorate([
    (0, common_1.Get)("returns/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "returnDetails", null);
__decorate([
    (0, common_1.Patch)("returns/:id/status"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("status")),
    __param(3, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateReturnStatus", null);
__decorate([
    (0, common_1.Patch)("returns/:id/decision"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("decision")),
    __param(3, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "decideReturn", null);
__decorate([
    (0, common_1.Patch)("returns/:id/receive"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "receiveReturn", null);
__decorate([
    (0, common_1.Patch)("returns/:id/refund"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "refundReturn", null);
__decorate([
    (0, common_1.Get)("disputes"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("status")),
    __param(2, (0, common_1.Query)("q")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "disputes", null);
__decorate([
    (0, common_1.Get)("disputes/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "disputeDetails", null);
__decorate([
    (0, common_1.Patch)("disputes/:id/status"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("status")),
    __param(3, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateDisputeStatus", null);
__decorate([
    (0, common_1.Post)("disputes/:id/messages"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("message")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "addDisputeMessage", null);
__decorate([
    (0, common_1.Patch)("disputes/:id/resolve"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("resolution")),
    __param(3, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "resolveDispute", null);
__decorate([
    (0, common_1.Get)("support-tickets"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("status")),
    __param(2, (0, common_1.Query)("q")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "supportTickets", null);
__decorate([
    (0, common_1.Get)("support-tickets/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "supportTicketDetails", null);
__decorate([
    (0, common_1.Post)("support-tickets/:id/messages"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("message")),
    __param(3, (0, common_1.Body)("attachmentUrl")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "addSupportTicketMessage", null);
__decorate([
    (0, common_1.Patch)("support-tickets/:id/read"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "markSupportTicketRead", null);
__decorate([
    (0, common_1.Patch)("support-tickets/:id/status"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)("status")),
    __param(3, (0, common_1.Body)("note")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateSupportTicketStatus", null);
__decorate([
    (0, common_1.Get)("reviews"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "reviews", null);
__decorate([
    (0, common_1.Post)("reviews/:type/:id/replies"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("type")),
    __param(2, (0, common_1.Param)("id")),
    __param(3, (0, common_1.Body)("replyText")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "replyToReview", null);
__decorate([
    (0, common_1.Get)("listings"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "listings", null);
__decorate([
    (0, common_1.Post)("listings"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, listings_dto_1.CreateListingDto]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "createListing", null);
__decorate([
    (0, common_1.Patch)("listings/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id", common_1.ParseIntPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Number, listings_dto_1.UpdateListingDto]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateListing", null);
__decorate([
    (0, common_1.Patch)("listings/:id/status"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id", common_1.ParseIntPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Number, listings_dto_1.UpdateListingStatusDto]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateListingStatus", null);
__decorate([
    (0, common_1.Get)("orders"),
    (0, permissions_decorator_1.RequirePermissions)("merchant.orders.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "orders", null);
__decorate([
    (0, common_1.Get)("orders/:id"),
    (0, permissions_decorator_1.RequirePermissions)("merchant.orders.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id", common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Number]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "orderDetails", null);
__decorate([
    (0, common_1.Patch)("orders/:id/status"),
    (0, permissions_decorator_1.RequirePermissions)("merchant.orders.manage"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id", common_1.ParseIntPipe)),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Number, orders_dto_1.UpdateOrderStatusDto]),
    __metadata("design:returntype", void 0)
], MerchantController.prototype, "updateOrderStatus", null);
exports.MerchantController = MerchantController = __decorate([
    (0, swagger_1.ApiTags)("Merchant Operations"),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, permissions_guard_1.PermissionsGuard),
    (0, common_1.Controller)("merchant"),
    __metadata("design:paramtypes", [merchant_service_1.MerchantService])
], MerchantController);
