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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MerchantService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const audit_service_1 = require("../audit/audit.service");
const accounting_service_1 = require("../accounting/accounting.service");
const reviews_service_1 = require("../reviews/reviews.service");
const TERMINAL_ORDER_STATUSES = ["CANCELLED", "REFUNDED"];
const ALLOWED_MERCHANT_TRANSITIONS = {
    PENDING: ["CONFIRMED", "CANCELLED"],
    CONFIRMED: ["PROCESSING", "CANCELLED"],
    PROCESSING: ["READY_FOR_PICKUP", "OUT_FOR_DELIVERY", "CANCELLED"],
    READY_FOR_PICKUP: ["DELIVERED", "CANCELLED"],
    OUT_FOR_DELIVERY: ["DELIVERED", "CANCELLED"],
    DELIVERED: ["RETURN_REQUESTED"],
    RETURN_REQUESTED: ["REFUNDED"],
};
const MERCHANT_RETURN_STATUS_MAP = {
    REQUESTED: "PENDING",
    APPROVED: "APPROVED",
    PROCESSING: "RECEIVED",
    REFUNDED: "REFUNDED",
    REJECTED: "REJECTED",
    FAILED: "REJECTED",
};
const MERCHANT_DISPUTE_STATUS_MAP = {
    SUBMITTED: "OPEN",
    UNDER_REVIEW: "UNDER_REVIEW",
    INVESTIGATION: "UNDER_REVIEW",
    WAITING_CUSTOMER: "UNDER_REVIEW",
    WAITING_PROVIDER: "OPEN",
    RESOLVED: "RESOLVED",
    REJECTED: "REJECTED",
    CLOSED: "RESOLVED",
};
const MERCHANT_TICKET_STATUS_MAP = {
    OPEN: "OPEN",
    WAITING_CUSTOMER: "PENDING",
    WAITING_SUPPORT: "IN_PROGRESS",
    IN_PROGRESS: "IN_PROGRESS",
    RESOLVED: "RESOLVED",
    CLOSED: "CLOSED",
    ESCALATED: "IN_PROGRESS",
};
let MerchantService = class MerchantService {
    constructor(prisma, audit, accounting, reviewsService) {
        this.prisma = prisma;
        this.audit = audit;
        this.accounting = accounting;
        this.reviewsService = reviewsService;
    }
    get db() {
        return this.prisma;
    }
    async merchantOrganizationsForUser(userId) {
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId, status: "ACTIVE" },
            include: { organization: true, permissions: true },
        });
        return memberships
            .filter((membership) => membership.organization?.organizationType === "MERCHANT" &&
            membership.organization?.status === "APPROVED")
            .map((membership) => ({
            id: membership.organizationId,
            publicId: membership.organization.publicId,
            name: membership.organization.displayName,
            memberRole: membership.memberRole,
            permissions: membership.permissions?.map((p) => p.permissionCode) ?? [],
        }));
    }
    async merchantOrganizationIds(userId) {
        const organizations = await this.merchantOrganizationsForUser(userId);
        return organizations.map((organization) => organization.id);
    }
    organizationMatch(id) {
        const numericId = Number(id);
        return Number.isFinite(numericId) && numericId > 0
            ? { OR: [{ id: numericId }, { publicId: id }] }
            : { publicId: id };
    }
    caseMatch(id) {
        const numericId = Number(id);
        return Number.isFinite(numericId) && numericId > 0
            ? { OR: [{ id: numericId }, { publicId: id }] }
            : { publicId: id };
    }
    normalizeReturnStatus(status) {
        return MERCHANT_RETURN_STATUS_MAP[(status ?? "").toUpperCase()] ??
            ((status ?? "").toUpperCase() || "PENDING");
    }
    normalizeDisputeStatus(status) {
        return MERCHANT_DISPUTE_STATUS_MAP[(status ?? "").toUpperCase()] ??
            ((status ?? "").toUpperCase() || "OPEN");
    }
    normalizeTicketStatus(status) {
        return MERCHANT_TICKET_STATUS_MAP[(status ?? "").toUpperCase()] ??
            ((status ?? "").toUpperCase() || "OPEN");
    }
    ticketStatusToMerchant(value) {
        return MERCHANT_TICKET_STATUS_MAP[(value ?? "").toUpperCase()] ?? "OPEN";
    }
    merchantStatusToTicket(value) {
        const upper = (value ?? "").toUpperCase();
        if (upper == "PENDING")
            return "WAITING_CUSTOMER";
        if (upper == "IN_PROGRESS")
            return "IN_PROGRESS";
        if (upper == "RESOLVED")
            return "RESOLVED";
        if (upper == "CLOSED")
            return "CLOSED";
        return "OPEN";
    }
    merchantStatusToComplaint(value) {
        const upper = (value ?? "").toUpperCase();
        if (upper == "UNDER_REVIEW")
            return "UNDER_REVIEW";
        if (upper == "RESOLVED")
            return "RESOLVED";
        if (upper == "REJECTED")
            return "REJECTED";
        return "SUBMITTED";
    }
    refundStatusToMerchant(value) {
        return MERCHANT_RETURN_STATUS_MAP[(value ?? "").toUpperCase()] ?? "PENDING";
    }
    supportMessageAttachments(message) {
        const urls = new Set();
        for (const attachment of message?.attachmentRecords ?? []) {
            if (attachment?.fileUrl) {
                urls.add(String(attachment.fileUrl));
            }
        }
        if (Array.isArray(message?.attachments)) {
            for (const attachment of message.attachments) {
                const fileUrl = attachment?.fileUrl ?? attachment?.url ?? attachment?.attachmentUrl;
                if (fileUrl) {
                    urls.add(String(fileUrl));
                }
            }
        }
        return Array.from(urls);
    }
    mapSupportMessage(message) {
        return {
            id: String(message?.publicId ?? message?.id ?? ""),
            sender_name: message?.author?.displayName ?? "ط§ظ„ظ†ط¸ط§ظ…",
            sender_type: message?.messageType === "MERCHANT_MESSAGE"
                ? "MERCHANT"
                : message?.messageType === "SUPPORT_MESSAGE"
                    ? "SUPPORT"
                    : "CUSTOMER",
            message: message?.body ?? "",
            attachments: this.supportMessageAttachments(message),
            attachment_url: this.supportMessageAttachments(message)[0] ?? null,
            is_mine: message?.messageType === "MERCHANT_MESSAGE",
            created_at: message?.createdAt,
        };
    }
    mapSupportTimeline(messages, fallbackStatus, createdAt) {
        const timeline = messages
            .filter((message) => message?.messageType === "SYSTEM_NOTE" || message?.messageType === "SUPPORT_MESSAGE")
            .map((message) => ({
            status: fallbackStatus,
            note: message?.body ?? fallbackStatus,
            created_at: message?.createdAt,
            actor_name: message?.author?.displayName ?? "ط§ظ„ظ†ط¸ط§ظ…",
        }));
        if (timeline.length)
            return timeline;
        return [
            {
                status: fallbackStatus,
                note: fallbackStatus,
                created_at: createdAt,
                actor_name: "ط§ظ„ظ†ط¸ط§ظ…",
            },
        ];
    }
    mapMerchantReturn(refund) {
        const items = (refund?.order?.items ?? []).map((item) => ({
            product_name: item?.listing?.title ?? item?.listing?.product?.nameAr ?? "ظ…ظ†طھط¬",
            quantity: Number(item?.quantity ?? 0),
            unit_price: Number(item?.unitPrice ?? item?.lineTotal ?? 0),
            total_amount: Number(item?.lineTotal ?? 0),
            listing_id: item?.listing?.publicId ?? item?.listingId ?? "",
        }));
        const status = this.refundStatusToMerchant(refund?.status);
        const timeline = [
            {
                status: "PENDING",
                note: refund?.reason ?? "طھظ… ط·ظ„ط¨ ط§ظ„ط§ط³طھط±ط¯ط§ط¯",
                created_at: refund?.createdAt,
                actor_name: refund?.requestedBy?.displayName ??
                    refund?.order?.user?.displayName ??
                    "ط§ظ„ط¹ظ…ظٹظ„",
            },
        ];
        if (refund?.status === "APPROVED" || refund?.approvedByUserId) {
            timeline.push({
                status: "APPROVED",
                note: "طھظ…طھ ط§ظ„ظ…ظˆط§ظپظ‚ط© ط¹ظ„ظ‰ ط·ظ„ط¨ ط§ظ„ط¥ط±ط¬ط§ط¹",
                created_at: refund?.updatedAt,
                actor_name: refund?.approvedBy?.displayName ?? "ط§ظ„طھط§ط¬ط±",
            });
        }
        if (refund?.status === "PROCESSING") {
            timeline.push({
                status: "RECEIVED",
                note: "طھظ… ط§ط³طھظ„ط§ظ… ط§ظ„ظ…ظ†طھط¬ ط§ظ„ظ…ط±طھط¬ط¹",
                created_at: refund?.updatedAt,
                actor_name: refund?.approvedBy?.displayName ?? "ط§ظ„طھط§ط¬ط±",
            });
        }
        if (refund?.status === "REJECTED") {
            timeline.push({
                status: "REJECTED",
                note: "طھظ… ط±ظپط¶ ط·ظ„ط¨ ط§ظ„ط¥ط±ط¬ط§ط¹",
                created_at: refund?.updatedAt,
                actor_name: refund?.approvedBy?.displayName ?? "ط§ظ„طھط§ط¬ط±",
            });
        }
        if (refund?.status === "REFUNDED") {
            timeline.push({
                status: "REFUNDED",
                note: "طھظ… طھظ†ظپظٹط° ط§ظ„ط§ط³طھط±ط¯ط§ط¯ ط§ظ„ظ…ط§ظ„ظٹ",
                created_at: refund?.processedAt ?? refund?.updatedAt,
                actor_name: refund?.approvedBy?.displayName ?? "ط§ظ„ظ†ط¸ط§ظ…",
            });
        }
        return {
            id: refund?.publicId ?? String(refund?.id ?? ""),
            order_public_id: refund?.order?.publicId ?? "",
            order_number: refund?.order?.orderNumber ?? refund?.refundNumber ?? "",
            customer_name: refund?.order?.user?.displayName ??
                refund?.requestedBy?.displayName ??
                "ط¹ظ…ظٹظ„",
            customer_phone: refund?.order?.user?.phoneE164 ??
                refund?.requestedBy?.phoneE164 ??
                "",
            status,
            order_status: refund?.order?.status ?? "",
            payment_status: refund?.payment?.status ?? refund?.order?.paymentStatus ?? "",
            amount: Number(refund?.amount ?? 0),
            currency: refund?.currency ?? refund?.payment?.currency ?? "YER",
            reason: refund?.reason ?? "ط·ظ„ط¨ ط§ط³طھط±ط¯ط§ط¯",
            merchant_note: "",
            created_at: refund?.createdAt,
            updated_at: refund?.updatedAt,
            items,
            timeline,
        };
    }
    mapMerchantDispute(complaint) {
        const messages = (complaint?.ticket?.messages ?? [])
            .filter((message) => !message?.isInternal)
            .map((message) => ({
            id: String(message?.publicId ?? message?.id ?? ""),
            sender_name: message?.author?.displayName ?? "ط§ظ„ظ†ط¸ط§ظ…",
            message: message?.body ?? "",
            created_at: message?.createdAt,
            attachments: this.supportMessageAttachments(message),
        }));
        const status = this.normalizeDisputeStatus(complaint?.status);
        return {
            id: complaint?.publicId ?? String(complaint?.id ?? ""),
            ticket_public_id: complaint?.ticket?.publicId ?? "",
            order_public_id: complaint?.order?.publicId ?? "",
            order_number: complaint?.order?.orderNumber ?? "",
            customer_name: complaint?.requester?.displayName ?? "ط¹ظ…ظٹظ„",
            customer_phone: complaint?.requester?.phoneE164 ?? "",
            reason_code: complaint?.subject ?? "ط´ظƒظˆظ‰ ط¹ظ…ظٹظ„",
            description: complaint?.description ?? "",
            status,
            priority: complaint?.severity ?? "NORMAL",
            resolution_note: complaint?.resolutionNote ?? "",
            created_at: complaint?.createdAt,
            updated_at: complaint?.updatedAt,
            messages,
            timeline: this.mapSupportTimeline(complaint?.ticket?.messages ?? [], status, complaint?.createdAt),
        };
    }
    mapMerchantSupportTicket(ticket) {
        const messages = (ticket?.messages ?? [])
            .filter((message) => !message?.isInternal)
            .map((message) => this.mapSupportMessage(message));
        const lastVisibleMessage = [...(ticket?.messages ?? [])]
            .filter((message) => !message?.isInternal)
            .sort((a, b) => new Date(b?.createdAt ?? 0).getTime() -
            new Date(a?.createdAt ?? 0).getTime())[0] ?? null;
        const needsMerchantReply = lastVisibleMessage?.messageType === "CUSTOMER_MESSAGE" ||
            ["OPEN", "WAITING_CUSTOMER"].includes(ticket?.status);
        return {
            id: String(ticket?.id ?? ""),
            public_id: ticket?.publicId ?? "",
            subject: ticket?.subject ?? "ظ…ط­ط§ط¯ط«ط© ط¹ظ…ظٹظ„",
            status: this.ticketStatusToMerchant(ticket?.status),
            priority: ticket?.priority ?? "NORMAL",
            category: ticket?.category ?? "",
            customer_name: ticket?.requester?.displayName ?? "",
            customer_phone: ticket?.requester?.phoneE164 ?? "",
            order_number: ticket?.order?.orderNumber ?? "",
            product_name: ticket?.order?.items?.[0]?.listing?.title ??
                ticket?.order?.items?.[0]?.listing?.product?.nameAr ??
                "",
            last_message: lastVisibleMessage?.body ?? ticket?.description ?? "ظ„ط§ طھظˆط¬ط¯ ط±ط³ط§ظ„ط© ظ…ط®طھطµط±ط©.",
            channel: "APP",
            unread_count: needsMerchantReply ? 1 : 0,
            created_at: ticket?.createdAt,
            updated_at: ticket?.updatedAt,
            messages,
        };
    }
    async dashboardSummary(userId) {
        const organizations = await this.merchantOrganizationsForUser(userId);
        const organizationIds = organizations.map((organization) => organization.id);
        const primary = organizations[0];
        const [orders, listings, unreadNotifications] = await Promise.all([
            this.db.order.findMany({
                where: { organizationId: { in: organizationIds } },
                include: { items: true, user: true },
                orderBy: { createdAt: "desc" },
                take: 30,
            }),
            this.db.listing.findMany({
                where: { organizationId: { in: organizationIds } },
                include: { product: true },
                orderBy: { createdAt: "desc" },
                take: 200,
            }),
            this.db.notification
                .count({ where: { userId, status: "UNREAD" } })
                .catch(() => 0),
        ]);
        const deliveredSales = orders
            .filter((order) => order.status === "DELIVERED")
            .reduce((sum, order) => sum + Number(order.totalAmount ?? 0), 0);
        const lowStockThreshold = 3;
        const lowStock = listings.filter((listing) => Number(listing.availableQuantity ?? 0) -
            Number(listing.reservedQuantity ?? 0) <=
            lowStockThreshold).length;
        return {
            success: true,
            data: {
                period: "day",
                merchant: {
                    id: primary?.publicId ?? "",
                    name: primary?.name ?? "ظ…طھط¬ط± ط؛ظٹط§ط±ظƒ",
                    member_role: primary?.memberRole ?? "",
                    role_codes: ["merchant_owner"],
                    permissions: primary?.permissions ?? [],
                },
                summary: {
                    total_sales: deliveredSales,
                    new_orders: orders.filter((order) => order.status === "PENDING")
                        .length,
                    low_stock_products: lowStock,
                    low_stock_threshold: lowStockThreshold,
                    sales_growth_percentage: 0,
                    unread_notifications: unreadNotifications,
                    currency: orders[0]?.currency ?? "YER",
                },
                sales_chart: [],
                recent_orders: orders
                    .slice(0, 8)
                    .map((order) => ({
                    id: String(order.id),
                    public_id: order.publicId,
                    order_number: order.orderNumber,
                    status: order.status,
                    total_amount: Number(order.totalAmount ?? 0),
                    currency: order.currency ?? "YER",
                    payment_status: order.paymentStatus,
                    customer_name: order.user?.displayName ?? "ط¹ظ…ظٹظ„",
                    items_count: order.items?.length ?? 0,
                    created_at: order.createdAt,
                })),
            },
        };
    }
    async inventory(userId, filters = {}) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const search = (filters.search ?? "").trim();
        const branchNumericId = Number(filters.branchId);
        const listings = await this.db.listing
            .findMany({
            where: {
                organizationId: { in: organizationIds },
                ...(Number.isFinite(branchNumericId) && branchNumericId > 0
                    ? { branchId: branchNumericId }
                    : {}),
                ...(filters.branchPublicId
                    ? { branch: { publicId: filters.branchPublicId } }
                    : {}),
                ...(search
                    ? {
                        OR: [
                            { title: { contains: search } },
                            { product: { nameAr: { contains: search } } },
                            { product: { sku: { contains: search } } },
                            { product: { oemNumber: { contains: search } } },
                        ],
                    }
                    : {}),
            },
            include: {
                product: { include: { category: true, partBrand: true } },
                inventory: true,
                branch: true,
                stockMovements: {
                    orderBy: { createdAt: "desc" },
                    take: 1,
                },
            },
            orderBy: { updatedAt: "desc" },
        })
            .catch(() => []);
        const items = listings
            .map((listing) => {
            const inventory = listing.inventory;
            const onHand = Number(inventory?.availableQuantity ?? listing.availableQuantity ?? 0);
            const reserved = Number(inventory?.reservedQuantity ?? listing.reservedQuantity ?? 0);
            const available = onHand - reserved;
            const threshold = Number(inventory?.lowStockThreshold ?? 3);
            const rawStatus = listing.status === "ARCHIVED"
                ? "archived"
                : available <= 0
                    ? "out_of_stock"
                    : available <= threshold
                        ? "low_stock"
                        : "available";
            const lastMovement = listing.stockMovements?.[0];
            return {
                id: String(inventory?.id ?? listing.id),
                numeric_id: String(inventory?.id ?? listing.id),
                listing_id: listing.publicId,
                listing_numeric_id: String(listing.id),
                title: listing.title,
                sku: listing.product?.sku ??
                    listing.product?.oemNumber ??
                    listing.product?.aftermarketCode ??
                    "",
                branch_id: listing.branch?.publicId ?? "",
                branch_numeric_id: listing.branchId ? String(listing.branchId) : "",
                branch_name: listing.branch?.branchName ?? "ط§ظ„ظپط±ط¹ ط§ظ„ط±ط¦ظٹط³ظٹ",
                current_quantity: onHand,
                reserved_quantity: reserved,
                available_quantity: available,
                alert_threshold: threshold,
                status: rawStatus,
                updated_at: inventory?.updatedAt ?? listing.updatedAt,
                category_name: listing.product?.category?.nameAr ?? "",
                brand_name: listing.product?.partBrand?.nameAr ?? "",
                last_movement: lastMovement
                    ? {
                        type: lastMovement.movementType,
                        quantity: Number(lastMovement.quantity ?? 0),
                        created_at: lastMovement.createdAt,
                    }
                    : null,
            };
        })
            .filter((item) => {
            const filter = (filters.status ?? "").toLowerCase();
            if (!filter || filter === "all") {
                return true;
            }
            return item.status.toString().toLowerCase() === filter;
        });
        const branchesMap = new Map();
        for (const item of items) {
            const key = item.branch_id || item.branch_numeric_id || "default";
            const current = branchesMap.get(key) ?? {
                publicId: item.branch_id,
                branchId: item.branch_numeric_id,
                name: item.branch_name,
                totalProducts: 0,
                lowStock: 0,
                outOfStock: 0,
            };
            current.totalProducts += 1;
            if (item.status == "low_stock")
                current.lowStock += 1;
            if (item.status == "out_of_stock")
                current.outOfStock += 1;
            branchesMap.set(key, current);
        }
        const recentMovementsRaw = await this.db.stockMovement.findMany({
            where: { listing: { organizationId: { in: organizationIds } } },
            include: { listing: { include: { branch: true, product: true, inventory: true } } },
            orderBy: { createdAt: "desc" },
            take: 30,
        }).catch(() => []);
        const recentMovements = recentMovementsRaw.map((movement) => ({
            id: String(movement.id),
            inventory_item_id: String(movement.listing?.inventory?.id ?? movement.listingId),
            product_name: movement.listing?.title ?? movement.listing?.product?.nameAr ?? "ظ…ظ†طھط¬",
            sku: movement.listing?.product?.sku ??
                movement.listing?.product?.oemNumber ??
                movement.listing?.product?.aftermarketCode ??
                "",
            branch_name: movement.listing?.branch?.branchName ?? "ط§ظ„ظپط±ط¹ ط§ظ„ط±ط¦ظٹط³ظٹ",
            movement_type: movement.movementType,
            quantity: Number(movement.quantity ?? 0),
            before_quantity: movement.quantityBefore,
            after_quantity: movement.quantityAfter,
            reference_type: movement.referenceType,
            reference_id: movement.referenceId,
            note: movement.reason,
            created_by: "",
            created_at: movement.createdAt,
        }));
        const summary = {
            total_products: items.length,
            available_products: items.filter((item) => item.status == "available").length,
            low_stock: items.filter((item) => item.status == "low_stock").length,
            out_of_stock: items.filter((item) => item.status == "out_of_stock").length,
            movements_today: recentMovements.filter((movement) => {
                const createdAt = new Date(movement.created_at ?? 0);
                const now = new Date();
                return (createdAt.getUTCFullYear() == now.getUTCFullYear() &&
                    createdAt.getUTCMonth() == now.getUTCMonth() &&
                    createdAt.getUTCDate() == now.getUTCDate());
            }).length,
            reserved_quantity: items.reduce((sum, item) => sum + Number(item.reserved_quantity ?? 0), 0),
            total_on_hand: items.reduce((sum, item) => sum + Number(item.current_quantity ?? 0), 0),
            total_available: items.reduce((sum, item) => sum + Number(item.available_quantity ?? 0), 0),
            reorder_needed: items.filter((item) => item.status == "low_stock" || item.status == "out_of_stock").length,
        };
        return {
            success: true,
            data: {
                summary,
                branches: Array.from(branchesMap.values()),
                alerts: items.filter((item) => item.status == "low_stock" || item.status == "out_of_stock"),
                items,
                recent_movements: recentMovements,
            },
        };
    }
    async branches(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const data = await this.db.organizationBranch.findMany({
            where: { organizationId: { in: organizationIds } },
            orderBy: { createdAt: "desc" },
        });
        return { success: true, data };
    }
    async reports(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const [ordersCount, listingsCount, delivered] = await Promise.all([
            this.db.order.count({
                where: { organizationId: { in: organizationIds } },
            }),
            this.db.listing.count({
                where: { organizationId: { in: organizationIds } },
            }),
            this.db.order.findMany({
                where: {
                    organizationId: { in: organizationIds },
                    status: "DELIVERED",
                },
                select: { totalAmount: true },
            }),
        ]);
        return {
            success: true,
            data: {
                orders_count: ordersCount,
                listings_count: listingsCount,
                total_sales: delivered.reduce((sum, order) => sum + Number(order.totalAmount ?? 0), 0),
                currency: "YER",
            },
        };
    }
    async exportReports(userId, options = {}) {
        const format = (options.format ?? "csv").toLowerCase();
        if (format !== "csv") {
            throw new common_1.BadRequestException({
                message: "طµظٹط؛ط© ط§ظ„طھطµط¯ظٹط± ط؛ظٹط± ظ…ط¯ط¹ظˆظ…ط©",
                error_code: "REPORT_EXPORT_FORMAT_UNSUPPORTED",
            });
        }
        const report = await this.reports(userId);
        const data = report.data ?? {};
        const rows = [
            ["metric", "value"],
            ["period", options.period ?? "month"],
            ["type", options.type ?? "overview"],
            ["branch_id", options.branchId ?? "all"],
            ["date_from", options.dateFrom ?? ""],
            ["date_to", options.dateTo ?? ""],
            ["orders_count", String(data.orders_count ?? 0)],
            ["listings_count", String(data.listings_count ?? 0)],
            ["total_sales", String(data.total_sales ?? 0)],
            ["currency", String(data.currency ?? "YER")],
        ];
        const content = rows
            .map((row) => row.map((cell) => this.csvEscape(cell)).join(","))
            .join("\n");
        return {
            success: true,
            data: {
                filename: `merchant-report-${options.type ?? "overview"}-${options.period ?? "month"}.csv`,
                content,
            },
        };
    }
    async financeSummary(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const balances = await this.db.merchantBalance
            .findMany({
            where: { organizationId: { in: organizationIds } },
            include: { organization: true },
        })
            .catch(() => []);
        const sum = (field) => balances.reduce((total, balance) => total + Number(balance[field] ?? 0), 0);
        return {
            success: true,
            data: {
                pending_balance: sum("pendingBalance"),
                available_balance: sum("availableBalance"),
                settled_balance: sum("settledBalance"),
                lifetime_gross: sum("lifetimeGross"),
                lifetime_refunded: sum("lifetimeRefunded"),
                lifetime_settled: sum("lifetimeSettled"),
                currency: balances[0]?.currency ?? "YER",
                balances,
            },
        };
    }
    async financeLedger(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const data = await this.db.financialTransaction
            .findMany({
            where: { organizationId: { in: organizationIds } },
            include: { journalEntry: true, organization: true },
            orderBy: { createdAt: "desc" },
            take: 100,
        })
            .catch(() => []);
        return { success: true, data };
    }
    async payments(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const data = await this.db.paymentTransaction
            .findMany({
            where: { organizationId: { in: organizationIds } },
            orderBy: { createdAt: "desc" },
            take: 100,
        })
            .catch(() => []);
        return { success: true, data };
    }
    async settlements(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const data = await this.db.settlement
            .findMany({
            where: { organizationId: { in: organizationIds } },
            orderBy: { createdAt: "desc" },
            take: 100,
        })
            .catch(() => []);
        return { success: true, data };
    }
    async invoices(userId) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const data = await this.db.invoice
            .findMany({
            where: { organizationId: { in: organizationIds } },
            include: { order: true },
            orderBy: { createdAt: "desc" },
            take: 100,
        })
            .catch(() => []);
        return { success: true, data };
    }
    async notifications(userId) {
        const notifications = await this.db.notification
            .findMany({ where: { userId }, orderBy: { createdAt: "desc" }, take: 80 })
            .catch(() => []);
        const items = notifications.map((item) => ({
            key: String(item.id),
            category: "merchant",
            type: item.data?.type ?? "general",
            title: item.title,
            message: item.body,
            target_id: item.data?.target_id ?? null,
            target_number: item.data?.target_number ?? null,
            created_at: item.createdAt,
            is_read: item.status === "READ",
            is_urgent: item.data?.urgent === true,
        }));
        return {
            success: true,
            data: {
                items,
                unread_count: items.filter((item) => !item.is_read).length,
                urgent_count: items.filter((item) => item.is_urgent).length,
            },
        };
    }
    async markNotificationRead(userId, key) {
        const id = Number(key);
        if (!id)
            return { success: true };
        await this.db.notification
            .updateMany({
            where: { id, userId },
            data: { status: "READ", readAt: new Date() },
        })
            .catch(() => null);
        return { success: true };
    }
    async markAllNotificationsRead(userId) {
        await this.db.notification
            .updateMany({
            where: { userId, status: "UNREAD" },
            data: { status: "READ", readAt: new Date() },
        })
            .catch(() => null);
        return { success: true };
    }
    async returns(userId, filters = {}) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const query = (filters.query ?? "").trim();
        const refunds = await this.db.refundRequest.findMany({
            where: {
                OR: [
                    { order: { organizationId: { in: organizationIds } } },
                    { payment: { organizationId: { in: organizationIds } } },
                ],
                ...(filters.status && filters.status !== "ALL"
                    ? {
                        status: Object.entries(MERCHANT_RETURN_STATUS_MAP)
                            .filter((entry) => entry[1] == filters.status)
                            .map((entry) => entry[0])[0] ?? undefined,
                    }
                    : {}),
                ...(query
                    ? {
                        OR: [
                            { refundNumber: { contains: query } },
                            { reason: { contains: query } },
                            { order: { orderNumber: { contains: query } } },
                            { requestedBy: { displayName: { contains: query } } },
                        ],
                    }
                    : {}),
            },
            include: {
                order: {
                    include: {
                        user: true,
                        items: { include: { listing: { include: { product: true } } } },
                    },
                },
                payment: true,
                requestedBy: true,
                approvedBy: true,
            },
            orderBy: { createdAt: "desc" },
            take: 100,
        });
        const items = refunds.map((refund) => this.mapMerchantReturn(refund));
        const summary = {
            total: items.length,
            pending: items.filter((item) => item.status == "PENDING").length,
            approved: items.filter((item) => item.status == "APPROVED").length,
            rejected: items.filter((item) => item.status == "REJECTED").length,
            received: items.filter((item) => item.status == "RECEIVED").length,
            refunded: items.filter((item) => item.status == "REFUNDED").length,
            total_amount: items.reduce((sum, item) => sum + Number(item.amount ?? 0), 0),
            refunded_amount: items
                .filter((item) => item.status == "REFUNDED")
                .reduce((sum, item) => sum + Number(item.amount ?? 0), 0),
            currency: items[0]?.currency ?? "YER",
        };
        return { success: true, data: { summary, items } };
    }
    async returnDetails(userId, id) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const refund = await this.db.refundRequest.findFirst({
            where: {
                ...this.caseMatch(id),
                OR: [
                    { order: { organizationId: { in: organizationIds } } },
                    { payment: { organizationId: { in: organizationIds } } },
                ],
            },
            include: {
                order: {
                    include: {
                        user: true,
                        items: { include: { listing: { include: { product: true } } } },
                    },
                },
                payment: true,
                requestedBy: true,
                approvedBy: true,
            },
        });
        if (!refund) {
            throw new common_1.NotFoundException({
                message: "Return request not found",
                error_code: "MERCHANT_RETURN_NOT_FOUND",
            });
        }
        return { success: true, data: this.mapMerchantReturn(refund) };
    }
    async updateReturnStatus(userId, id, status, note) {
        const upper = (status ?? "").toUpperCase();
        if (upper == "REJECTED") {
            return this.decideReturn(userId, id, "REJECTED", note);
        }
        if (upper == "RECEIVED") {
            return this.receiveReturn(userId, id, note);
        }
        if (upper == "PAID" || upper == "REFUNDED") {
            return this.refundReturn(userId, id, note);
        }
        return this.decideReturn(userId, id, "APPROVED", note);
    }
    async decideReturn(userId, id, decision, note) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const refund = await this.db.refundRequest.findFirst({
            where: {
                ...this.caseMatch(id),
                OR: [
                    { order: { organizationId: { in: organizationIds } } },
                    { payment: { organizationId: { in: organizationIds } } },
                ],
            },
            include: { order: true },
        });
        if (!refund) {
            throw new common_1.NotFoundException({
                message: "Return request not found",
                error_code: "MERCHANT_RETURN_NOT_FOUND",
            });
        }
        const approve = (decision ?? "").toUpperCase() == "APPROVED";
        const data = await this.db.$transaction(async (tx) => {
            const updated = await tx.refundRequest.update({
                where: { id: refund.id },
                data: {
                    status: approve ? "APPROVED" : "REJECTED",
                    approvedByUserId: userId,
                },
            });
            if (!approve && refund.orderId) {
                await tx.order
                    .update({
                    where: { id: refund.orderId },
                    data: { status: "DELIVERED" },
                })
                    .catch(() => null);
            }
            return updated;
        });
        await this.audit
            .write({
            actorUserId: userId,
            action: approve
                ? "merchant.return.approved"
                : "merchant.return.rejected",
            entityType: "refund",
            entityId: refund.id,
            metadata: { note: note ?? null },
        })
            .catch(() => null);
        return { success: true, data };
    }
    async receiveReturn(userId, id, note) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const refund = await this.db.refundRequest.findFirst({
            where: {
                ...this.caseMatch(id),
                OR: [
                    { order: { organizationId: { in: organizationIds } } },
                    { payment: { organizationId: { in: organizationIds } } },
                ],
            },
        });
        if (!refund) {
            throw new common_1.NotFoundException({
                message: "Return request not found",
                error_code: "MERCHANT_RETURN_NOT_FOUND",
            });
        }
        const data = await this.db.refundRequest.update({
            where: { id: refund.id },
            data: {
                status: "PROCESSING",
                approvedByUserId: userId,
            },
        });
        await this.audit
            .write({
            actorUserId: userId,
            action: "merchant.return.received",
            entityType: "refund",
            entityId: refund.id,
            metadata: { note: note ?? null },
        })
            .catch(() => null);
        return { success: true, data };
    }
    async refundReturn(userId, id, note) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const refund = await this.db.refundRequest.findFirst({
            where: {
                ...this.caseMatch(id),
                OR: [
                    { order: { organizationId: { in: organizationIds } } },
                    { payment: { organizationId: { in: organizationIds } } },
                ],
            },
            include: {
                payment: true,
                order: true,
                serviceOrder: true,
            },
        });
        if (!refund) {
            throw new common_1.NotFoundException({
                message: "Return request not found",
                error_code: "MERCHANT_RETURN_NOT_FOUND",
            });
        }
        const data = await this.db.$transaction(async (tx) => {
            const updatedRefund = await tx.refundRequest.update({
                where: { id: refund.id },
                data: {
                    status: "REFUNDED",
                    approvedByUserId: userId,
                    processedAt: new Date(),
                },
            });
            if (refund.paymentId) {
                await tx.paymentTransaction
                    .update({
                    where: { id: refund.paymentId },
                    data: {
                        status: Number(refund.amount ?? 0) >= Number(refund.payment?.amount ?? 0)
                            ? "REFUNDED"
                            : "PARTIALLY_REFUNDED",
                        reviewNote: note ?? refund.payment?.reviewNote ?? null,
                    },
                })
                    .catch(() => null);
            }
            if (refund.invoiceId) {
                await tx.invoice
                    .update({
                    where: { id: refund.invoiceId },
                    data: { status: "REFUNDED" },
                })
                    .catch(() => null);
            }
            if (refund.orderId) {
                await tx.order
                    .update({
                    where: { id: refund.orderId },
                    data: { status: "REFUNDED", paymentStatus: "REFUNDED" },
                })
                    .catch(() => null);
            }
            await this.accounting.postRefundCompleted(tx, {
                ...updatedRefund,
                payment: refund.payment,
                order: refund.order,
                serviceOrder: refund.serviceOrder,
            }, userId);
            return updatedRefund;
        });
        await this.audit
            .write({
            actorUserId: userId,
            action: "merchant.return.refunded",
            entityType: "refund",
            entityId: refund.id,
            metadata: { note: note ?? null },
        })
            .catch(() => null);
        return { success: true, data };
    }
    async disputes(userId, filters = {}) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const query = (filters.query ?? "").trim();
        const complaints = await this.db.complaint.findMany({
            where: {
                organizationId: { in: organizationIds },
                ...(filters.status && filters.status !== "ALL"
                    ? {
                        status: this.merchantStatusToComplaint(filters.status),
                    }
                    : {}),
                ...(query
                    ? {
                        OR: [
                            { complaintNumber: { contains: query } },
                            { subject: { contains: query } },
                            { description: { contains: query } },
                            { requester: { displayName: { contains: query } } },
                            { order: { orderNumber: { contains: query } } },
                        ],
                    }
                    : {}),
            },
            include: {
                requester: true,
                order: true,
                ticket: {
                    include: {
                        messages: {
                            include: { author: true, attachmentRecords: true },
                            orderBy: { createdAt: "asc" },
                            take: 30,
                        },
                    },
                },
            },
            orderBy: [{ severity: "desc" }, { updatedAt: "desc" }],
            take: 100,
        });
        const items = complaints.map((complaint) => this.mapMerchantDispute(complaint));
        const summary = {
            total: items.length,
            open: items.filter((item) => item.status == "OPEN").length,
            under_review: items.filter((item) => item.status == "UNDER_REVIEW")
                .length,
            resolved: items.filter((item) => item.status == "RESOLVED").length,
            rejected: items.filter((item) => item.status == "REJECTED").length,
        };
        return { success: true, data: { summary, items } };
    }
    async disputeDetails(userId, id) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const complaint = await this.db.complaint.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
            include: {
                requester: true,
                order: true,
                ticket: {
                    include: {
                        messages: {
                            include: { author: true, attachmentRecords: true },
                            orderBy: { createdAt: "asc" },
                        },
                    },
                },
            },
        });
        if (!complaint) {
            throw new common_1.NotFoundException({
                message: "Complaint not found",
                error_code: "MERCHANT_DISPUTE_NOT_FOUND",
            });
        }
        return { success: true, data: this.mapMerchantDispute(complaint) };
    }
    async updateDisputeStatus(userId, id, status, note) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const complaint = await this.db.complaint.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
            include: { ticket: true },
        });
        if (!complaint) {
            throw new common_1.NotFoundException({
                message: "Complaint not found",
                error_code: "MERCHANT_DISPUTE_NOT_FOUND",
            });
        }
        const nextStatus = this.merchantStatusToComplaint(status);
        const data = await this.db.$transaction(async (tx) => {
            const updated = await tx.complaint.update({
                where: { id: complaint.id },
                data: {
                    status: nextStatus,
                    resolutionNote: note ?? complaint.resolutionNote ?? null,
                    ...(nextStatus == "RESOLVED" || nextStatus == "REJECTED"
                        ? { resolvedByUserId: userId, resolvedAt: new Date() }
                        : {}),
                },
            });
            if (complaint.ticketId) {
                await tx.supportTicket
                    .update({
                    where: { id: complaint.ticketId },
                    data: {
                        status: nextStatus == "RESOLVED"
                            ? "RESOLVED"
                            : nextStatus == "REJECTED"
                                ? "CLOSED"
                                : "IN_PROGRESS",
                    },
                })
                    .catch(() => null);
                if ((note ?? "").trim().length > 0) {
                    await tx.supportTicketMessage.create({
                        data: {
                            ticketId: complaint.ticketId,
                            authorUserId: userId,
                            messageType: "MERCHANT_MESSAGE",
                            body: note.trim(),
                            isInternal: false,
                        },
                    });
                }
            }
            return updated;
        });
        await this.audit
            .write({
            actorUserId: userId,
            action: "merchant.dispute.status_updated",
            entityType: "complaint",
            entityId: complaint.id,
            metadata: { status: nextStatus, note: note ?? null },
        })
            .catch(() => null);
        return { success: true, data };
    }
    async addDisputeMessage(userId, id, message) {
        if (!(message ?? "").trim()) {
            throw new common_1.BadRequestException({
                message: "Message is required",
                error_code: "MERCHANT_DISPUTE_MESSAGE_REQUIRED",
            });
        }
        const organizationIds = await this.merchantOrganizationIds(userId);
        const complaint = await this.db.complaint.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
        });
        if (!complaint?.ticketId) {
            throw new common_1.NotFoundException({
                message: "Complaint ticket not found",
                error_code: "MERCHANT_DISPUTE_TICKET_NOT_FOUND",
            });
        }
        const data = await this.db.$transaction(async (tx) => {
            const created = await tx.supportTicketMessage.create({
                data: {
                    ticketId: complaint.ticketId,
                    authorUserId: userId,
                    messageType: "MERCHANT_MESSAGE",
                    body: message.trim(),
                    isInternal: false,
                },
            });
            await tx.supportTicket
                .update({
                where: { id: complaint.ticketId },
                data: { status: "WAITING_CUSTOMER", lastMessageAt: new Date() },
            })
                .catch(() => null);
            return created;
        });
        return { success: true, data };
    }
    async resolveDispute(userId, id, resolution, note) {
        return this.updateDisputeStatus(userId, id, resolution == "MERCHANT_ACCEPTED" ? "RESOLVED" : "REJECTED", note);
    }
    async supportTickets(userId, filters = {}) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const query = (filters.query ?? "").trim();
        const tickets = await this.db.supportTicket.findMany({
            where: {
                organizationId: { in: organizationIds },
                category: { not: "COMPLAINT" },
                ...(filters.status && filters.status != "ALL"
                    ? { status: this.merchantStatusToTicket(filters.status) }
                    : {}),
                ...(query
                    ? {
                        OR: [
                            { ticketNumber: { contains: query } },
                            { subject: { contains: query } },
                            { description: { contains: query } },
                            { requester: { displayName: { contains: query } } },
                            { requester: { phoneE164: { contains: query } } },
                            { order: { orderNumber: { contains: query } } },
                        ],
                    }
                    : {}),
            },
            include: {
                requester: true,
                order: {
                    include: {
                        items: { include: { listing: { include: { product: true } } } },
                    },
                },
                messages: {
                    include: { author: true, attachmentRecords: true },
                    orderBy: { createdAt: "asc" },
                    take: 12,
                },
            },
            orderBy: [{ priority: "desc" }, { updatedAt: "desc" }],
            take: 100,
        });
        const items = tickets.map((ticket) => this.mapMerchantSupportTicket(ticket));
        return {
            success: true,
            data: {
                tickets: items,
                open_count: items.filter((item) => item.status == "OPEN").length,
                unread_count: items.reduce((sum, item) => sum + Number(item.unread_count ?? 0), 0),
                waiting_customer_count: items.filter((item) => Number(item.unread_count ?? 0) > 0).length,
                resolved_count: items.filter((item) => item.status == "RESOLVED" || item.status == "CLOSED").length,
            },
        };
    }
    async supportTicketDetails(userId, id) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const ticket = await this.db.supportTicket.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
            include: {
                requester: true,
                order: {
                    include: {
                        items: { include: { listing: { include: { product: true } } } },
                    },
                },
                messages: {
                    include: { author: true, attachmentRecords: true },
                    orderBy: { createdAt: "asc" },
                },
            },
        });
        if (!ticket) {
            throw new common_1.NotFoundException({
                message: "Support ticket not found",
                error_code: "MERCHANT_TICKET_NOT_FOUND",
            });
        }
        return { success: true, data: this.mapMerchantSupportTicket(ticket) };
    }
    async addSupportTicketMessage(userId, id, message, attachmentUrl) {
        if (!(message ?? "").trim()) {
            throw new common_1.BadRequestException({
                message: "Message is required",
                error_code: "MERCHANT_TICKET_MESSAGE_REQUIRED",
            });
        }
        const organizationIds = await this.merchantOrganizationIds(userId);
        const ticket = await this.db.supportTicket.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
        });
        if (!ticket) {
            throw new common_1.NotFoundException({
                message: "Support ticket not found",
                error_code: "MERCHANT_TICKET_NOT_FOUND",
            });
        }
        const data = await this.db.$transaction(async (tx) => {
            const created = await tx.supportTicketMessage.create({
                data: {
                    ticketId: ticket.id,
                    authorUserId: userId,
                    messageType: "MERCHANT_MESSAGE",
                    body: message.trim(),
                    attachments: attachmentUrl ? [{ fileUrl: attachmentUrl }] : undefined,
                    isInternal: false,
                },
            });
            await tx.supportTicket.update({
                where: { id: ticket.id },
                data: { status: "WAITING_CUSTOMER", lastMessageAt: new Date() },
            });
            return created;
        });
        return { success: true, data };
    }
    async markSupportTicketRead(userId, id) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const ticket = await this.db.supportTicket.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
        });
        if (!ticket) {
            throw new common_1.NotFoundException({
                message: "Support ticket not found",
                error_code: "MERCHANT_TICKET_NOT_FOUND",
            });
        }
        if (["OPEN", "WAITING_CUSTOMER"].includes(ticket.status)) {
            await this.db.supportTicket
                .update({
                where: { id: ticket.id },
                data: { status: "IN_PROGRESS" },
            })
                .catch(() => null);
        }
        return { success: true };
    }
    async updateSupportTicketStatus(userId, id, status, note) {
        const organizationIds = await this.merchantOrganizationIds(userId);
        const ticket = await this.db.supportTicket.findFirst({
            where: {
                ...this.caseMatch(id),
                organizationId: { in: organizationIds },
            },
        });
        if (!ticket) {
            throw new common_1.NotFoundException({
                message: "Support ticket not found",
                error_code: "MERCHANT_TICKET_NOT_FOUND",
            });
        }
        const nextStatus = this.merchantStatusToTicket(status);
        const data = await this.db.$transaction(async (tx) => {
            const updated = await tx.supportTicket.update({
                where: { id: ticket.id },
                data: {
                    status: nextStatus,
                    ...(nextStatus == "RESOLVED" ? { resolvedAt: new Date() } : {}),
                    ...(nextStatus == "CLOSED" ? { closedAt: new Date() } : {}),
                },
            });
            if ((note ?? "").trim().length > 0) {
                await tx.supportTicketMessage.create({
                    data: {
                        ticketId: ticket.id,
                        authorUserId: userId,
                        messageType: "SYSTEM_NOTE",
                        body: note.trim(),
                        isInternal: false,
                    },
                });
            }
            return updated;
        });
        return { success: true, data };
    }
    async reviews(userId) {
        const organizations = await this.merchantOrganizationsForUser(userId);
        const organizationIds = organizations.map((organization) => organization.id);
        if (organizationIds.length === 0) {
            return { success: true, data: { merchant: [], products: [] } };
        }
        const listings = await this.db.listing
            .findMany({
            where: { organizationId: { in: organizationIds } },
            select: { productId: true, organizationId: true },
        })
            .catch(() => []);
        const productOrganizationMap = new Map();
        for (const listing of listings) {
            if (listing.productId && !productOrganizationMap.has(listing.productId)) {
                productOrganizationMap.set(listing.productId, listing.organizationId);
            }
        }
        const productIds = Array.from(productOrganizationMap.keys());
        const [merchantReviews, productReviews] = await Promise.all([
            this.db.merchantReview
                .findMany({
                where: {
                    organizationId: { in: organizationIds },
                    status: "PUBLISHED",
                },
                include: {
                    user: true,
                    replies: {
                        where: { status: "PUBLISHED" },
                        orderBy: { createdAt: "desc" },
                        take: 1,
                    },
                },
                orderBy: { createdAt: "desc" },
                take: 100,
            })
                .catch(() => []),
            productIds.length === 0
                ? Promise.resolve([])
                : this.db.productReview
                    .findMany({
                    where: {
                        productId: { in: productIds },
                        status: "PUBLISHED",
                    },
                    include: {
                        user: true,
                        product: true,
                        replies: {
                            where: {
                                organizationId: { in: organizationIds },
                                status: "PUBLISHED",
                            },
                            orderBy: { createdAt: "desc" },
                            take: 1,
                        },
                    },
                    orderBy: { createdAt: "desc" },
                    take: 100,
                })
                    .catch(() => []),
        ]);
        return {
            success: true,
            data: {
                merchant: merchantReviews.map((review) => ({
                    id: review.id,
                    review_id: review.id,
                    public_id: review.publicId,
                    rating: review.rating,
                    title: review.title ?? "",
                    comment: review.body ?? review.title ?? "",
                    review_text: review.body ?? "",
                    customer_name: review.user?.displayName ?? review.user?.phoneNormalized ?? "ط¹ظ…ظٹظ„",
                    reply_text: review.replies?.[0]?.body ?? "",
                    status: review.status,
                    created_at: review.createdAt,
                })),
                products: productReviews.map((review) => ({
                    id: review.id,
                    review_id: review.id,
                    public_id: review.publicId,
                    rating: review.rating,
                    title: review.title ?? "",
                    comment: review.body ?? review.title ?? "",
                    review_text: review.body ?? "",
                    customer_name: review.user?.displayName ?? review.user?.phoneNormalized ?? "ط¹ظ…ظٹظ„",
                    product_name: review.product?.nameAr ??
                        review.product?.nameEn ??
                        review.product?.sku ??
                        "ظ…ظ†طھط¬",
                    reply_text: review.replies?.[0]?.body ?? "",
                    status: review.status,
                    created_at: review.createdAt,
                    organization_id: productOrganizationMap.get(review.productId) ?? null,
                })),
            },
        };
    }
    async replyToReview(userId, type, id, replyText) {
        const reviewId = Number(id);
        if (!Number.isFinite(reviewId) || reviewId <= 0) {
            throw new common_1.BadRequestException({
                message: "ظ…ط¹ط±ظپ ط§ظ„طھظ‚ظٹظٹظ… ط؛ظٹط± طµط§ظ„ط­",
                error_code: "REVIEW_ID_INVALID",
            });
        }
        const body = (replyText ?? "").trim();
        if (body.length < 2) {
            throw new common_1.BadRequestException({
                message: "ظ†طµ ط§ظ„ط±ط¯ ظ…ط·ظ„ظˆط¨",
                error_code: "REVIEW_REPLY_REQUIRED",
            });
        }
        const targetType = String(type).toUpperCase();
        const organizationIds = await this.merchantOrganizationIds(userId);
        if (organizationIds.length === 0) {
            throw new common_1.ForbiddenException({
                message: "ظ„ط§ طھظˆط¬ط¯ ظ…ط¤ط³ط³ط© طھط§ط¬ط± ظ…ط±طھط¨ط·ط© ط¨ط§ظ„ط­ط³ط§ط¨",
                error_code: "MERCHANT_ORGANIZATION_REQUIRED",
            });
        }
        let organizationId = null;
        if (targetType === "MERCHANT") {
            const review = await this.db.merchantReview.findUnique({
                where: { id: reviewId },
                select: { organizationId: true },
            });
            if (!review || !organizationIds.includes(review.organizationId)) {
                throw new common_1.ForbiddenException({
                    message: "ظ„ط§ ظٹظ…ظƒظ†ظƒ ط§ظ„ط±ط¯ ط¹ظ„ظ‰ ظ‡ط°ط§ ط§ظ„طھظ‚ظٹظٹظ…",
                    error_code: "REVIEW_REPLY_FORBIDDEN",
                });
            }
            organizationId = review.organizationId;
        }
        else if (targetType === "PRODUCT") {
            const review = await this.db.productReview.findUnique({
                where: { id: reviewId },
                select: { productId: true },
            });
            if (!review) {
                throw new common_1.NotFoundException({
                    message: "ط§ظ„طھظ‚ظٹظٹظ… ط؛ظٹط± ظ…ظˆط¬ظˆط¯",
                    error_code: "REVIEW_NOT_FOUND",
                });
            }
            const listing = await this.db.listing.findFirst({
                where: {
                    productId: review.productId,
                    organizationId: { in: organizationIds },
                },
                orderBy: { createdAt: "asc" },
                select: { organizationId: true },
            });
            if (!listing) {
                throw new common_1.ForbiddenException({
                    message: "ظ„ط§ ظٹظ…ظƒظ†ظƒ ط§ظ„ط±ط¯ ط¹ظ„ظ‰ ظ‡ط°ط§ ط§ظ„طھظ‚ظٹظٹظ…",
                    error_code: "REVIEW_REPLY_FORBIDDEN",
                });
            }
            organizationId = listing.organizationId;
        }
        else if (targetType === "WORKSHOP") {
            const review = await this.db.workshopReview.findUnique({
                where: { id: reviewId },
                select: { organizationId: true },
            });
            if (!review || !organizationIds.includes(review.organizationId)) {
                throw new common_1.ForbiddenException({
                    message: "ظ„ط§ ظٹظ…ظƒظ†ظƒ ط§ظ„ط±ط¯ ط¹ظ„ظ‰ ظ‡ط°ط§ ط§ظ„طھظ‚ظٹظٹظ…",
                    error_code: "REVIEW_REPLY_FORBIDDEN",
                });
            }
            organizationId = review.organizationId;
        }
        else if (targetType === "SERVICE") {
            const review = await this.db.serviceReview.findUnique({
                where: { id: reviewId },
                select: { organizationId: true },
            });
            if (!review || !organizationIds.includes(review.organizationId)) {
                throw new common_1.ForbiddenException({
                    message: "ظ„ط§ ظٹظ…ظƒظ†ظƒ ط§ظ„ط±ط¯ ط¹ظ„ظ‰ ظ‡ط°ط§ ط§ظ„طھظ‚ظٹظٹظ…",
                    error_code: "REVIEW_REPLY_FORBIDDEN",
                });
            }
            organizationId = review.organizationId;
        }
        else {
            throw new common_1.BadRequestException({
                message: "ظ†ظˆط¹ ط§ظ„طھظ‚ظٹظٹظ… ط؛ظٹط± ظ…ط¯ط¹ظˆظ…",
                error_code: "REVIEW_TARGET_UNSUPPORTED",
            });
        }
        if (organizationId == null) {
            throw new common_1.BadRequestException({
                message: "طھط¹ط°ط± طھط­ط¯ظٹط¯ ط§ظ„ظ…ط¤ط³ط³ط© ط§ظ„ظ…ط±طھط¨ط·ط© ط¨ط§ظ„ط±ط¯",
                error_code: "REVIEW_REPLY_ORGANIZATION_REQUIRED",
            });
        }
        return this.reviewsService.replyToReview(userId, {
            targetType: targetType,
            reviewId,
            organizationId,
            body,
        });
    }
    csvEscape(value) {
        const text = String(value ?? "");
        if (text.includes('"') || text.includes(",") || text.includes("\n")) {
            return `"${text.replace(/"/g, '""')}"`;
        }
        return text;
    }
    async assertMembership(userId, organizationId) {
        const member = await this.prisma.organizationMember.findFirst({
            where: { userId, organizationId },
        });
        if (!member)
            throw new common_1.ForbiddenException({
                message: "ظ„ظٹط³ ظ„ط¯ظٹظƒ طµظ„ط§ط­ظٹط© ط¹ظ„ظ‰ ظ‡ط°ظ‡ ط§ظ„ظ…ط¤ط³ط³ط©",
                error_code: "ORGANIZATION_ACCESS_DENIED",
            });
        return member;
    }
    async resolveOrganizationId(dto) {
        let organizationId = dto.organizationId;
        if (dto.organizationPublicId) {
            const org = await this.prisma.organization.findUnique({
                where: { publicId: dto.organizationPublicId },
            });
            if (!org)
                throw new common_1.NotFoundException({
                    message: "Organization not found",
                    error_code: "ORGANIZATION_NOT_FOUND",
                });
            organizationId = org.id;
        }
        if (!organizationId)
            throw new common_1.BadRequestException({
                message: "organizationId or organizationPublicId is required",
                error_code: "ORGANIZATION_REQUIRED",
            });
        return organizationId;
    }
    async createListing(userId, dto) {
        const organizationId = await this.resolveOrganizationId(dto);
        await this.assertMembership(userId, organizationId);
        const organization = await this.prisma.organization.findUnique({
            where: { id: organizationId },
        });
        if (!organization || organization.organizationType !== "MERCHANT") {
            throw new common_1.BadRequestException({
                message: "ظ‡ط°ظ‡ ط§ظ„ظ…ط¤ط³ط³ط© ظ„ظٹط³طھ ط­ط³ط§ط¨ طھط§ط¬ط±",
                error_code: "ORGANIZATION_NOT_MERCHANT",
            });
        }
        if (organization.status !== "APPROVED") {
            throw new common_1.BadRequestException({
                message: "ظ„ط§ ظٹظ…ظƒظ† ط¥ظ†ط´ط§ط، ط¹ط±ظˆط¶ ظ‚ط¨ظ„ ط§ط¹طھظ…ط§ط¯ ط­ط³ط§ط¨ ط§ظ„طھط§ط¬ط±",
                error_code: "MERCHANT_NOT_APPROVED",
            });
        }
        const product = await this.db.catalogProduct.findUnique({
            where: { id: dto.productId },
        });
        if (!product || !product.isActive) {
            throw new common_1.NotFoundException({
                message: "Product not found",
                error_code: "PRODUCT_NOT_FOUND",
            });
        }
        if (dto.branchId) {
            const branch = await this.prisma.organizationBranch.findFirst({
                where: { id: dto.branchId, organizationId },
            });
            if (!branch)
                throw new common_1.BadRequestException({
                    message: "ط§ظ„ظپط±ط¹ ظ„ط§ ظٹطھط¨ط¹ ظ‡ط°ظ‡ ط§ظ„ظ…ط¤ط³ط³ط©",
                    error_code: "BRANCH_ACCESS_DENIED",
                });
        }
        const data = await this.db.$transaction(async (tx) => {
            const listing = await tx.listing.create({
                data: {
                    productId: dto.productId,
                    organizationId,
                    branchId: dto.branchId ?? null,
                    cityId: dto.cityId ?? null,
                    title: dto.title,
                    description: dto.description ?? null,
                    condition: dto.condition ?? "NEW",
                    qualityType: dto.qualityType ?? "AFTERMARKET",
                    unitPrice: dto.unitPrice,
                    salePrice: dto.salePrice ?? null,
                    currency: dto.currency ?? "YER",
                    availableQuantity: dto.availableQuantity,
                    reservedQuantity: 0,
                    minOrderQuantity: dto.minOrderQuantity ?? 1,
                    warrantyDays: dto.warrantyDays ?? null,
                    supportsPickup: dto.supportsPickup ?? true,
                    supportsDelivery: dto.supportsDelivery ?? false,
                    createdByUserId: userId,
                    status: "DRAFT",
                    approvalStatus: "APPROVED",
                },
            });
            await tx.listingInventory
                .create({
                data: {
                    listingId: listing.id,
                    availableQuantity: dto.availableQuantity,
                    reservedQuantity: 0,
                },
            })
                .catch(() => null);
            await tx.listingPrice
                .create({
                data: {
                    listingId: listing.id,
                    unitPrice: dto.unitPrice,
                    salePrice: dto.salePrice ?? null,
                    currency: dto.currency ?? "YER",
                    isActive: true,
                },
            })
                .catch(() => null);
            await tx.stockMovement
                .create({
                data: {
                    listingId: listing.id,
                    movementType: "INITIAL_STOCK",
                    quantity: dto.availableQuantity,
                    quantityBefore: 0,
                    quantityAfter: dto.availableQuantity,
                    reason: "Initial listing stock",
                    createdByUserId: userId,
                },
            })
                .catch(() => null);
            return listing;
        });
        return { success: true, message: "Listing created", data };
    }
    async myListings(userId) {
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId },
            select: { organizationId: true },
        });
        const organizationIds = memberships.map((m) => m.organizationId);
        const data = await this.db.listing.findMany({
            where: { organizationId: { in: organizationIds } },
            include: {
                product: { include: { media: true, category: true, partBrand: true } },
                organization: true,
                branch: true,
            },
            orderBy: { createdAt: "desc" },
        });
        return { success: true, data };
    }
    async updateListing(userId, id, dto) {
        const listing = await this.db.listing.findUnique({ where: { id } });
        if (!listing)
            throw new common_1.NotFoundException({
                message: "Listing not found",
                error_code: "LISTING_NOT_FOUND",
            });
        await this.assertMembership(userId, listing.organizationId);
        if (dto.availableQuantity !== undefined &&
            dto.availableQuantity < listing.reservedQuantity) {
            throw new common_1.BadRequestException({
                message: "ظ„ط§ ظٹظ…ظƒظ† ط¬ط¹ظ„ ط§ظ„ظƒظ…ظٹط© ط£ظ‚ظ„ ظ…ظ† ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط­ط¬ظˆط²ط©",
                error_code: "AVAILABLE_LESS_THAN_RESERVED",
            });
        }
        const data = await this.db.$transaction(async (tx) => {
            const beforeQuantity = listing.availableQuantity;
            const updated = await tx.listing.update({ where: { id }, data: dto });
            if (dto.availableQuantity !== undefined &&
                dto.availableQuantity !== beforeQuantity) {
                await tx.listingInventory
                    .upsert({
                    where: { listingId: id },
                    update: {
                        availableQuantity: dto.availableQuantity,
                        reservedQuantity: listing.reservedQuantity,
                    },
                    create: {
                        listingId: id,
                        availableQuantity: dto.availableQuantity,
                        reservedQuantity: listing.reservedQuantity,
                    },
                })
                    .catch(() => null);
                await tx.stockMovement
                    .create({
                    data: {
                        listingId: id,
                        movementType: dto.availableQuantity > beforeQuantity
                            ? "STOCK_IN"
                            : "STOCK_ADJUSTMENT",
                        quantity: dto.availableQuantity - beforeQuantity,
                        quantityBefore: beforeQuantity,
                        quantityAfter: dto.availableQuantity,
                        reason: "Manual inventory update",
                        createdByUserId: userId,
                    },
                })
                    .catch(() => null);
            }
            if (dto.unitPrice !== undefined || dto.salePrice !== undefined) {
                await tx.listingPrice
                    .create({
                    data: {
                        listingId: id,
                        unitPrice: dto.unitPrice ?? listing.unitPrice,
                        salePrice: dto.salePrice ?? listing.salePrice,
                        currency: listing.currency,
                        isActive: true,
                    },
                })
                    .catch(() => null);
            }
            return updated;
        });
        return { success: true, message: "Listing updated", data };
    }
    async updateListingStatus(userId, id, dto) {
        const listing = await this.db.listing.findUnique({
            where: { id },
            include: { organization: true },
        });
        if (!listing)
            throw new common_1.NotFoundException({
                message: "Listing not found",
                error_code: "LISTING_NOT_FOUND",
            });
        await this.assertMembership(userId, listing.organizationId);
        if (dto.status === "ACTIVE") {
            if (listing.organization.status !== "APPROVED") {
                throw new common_1.BadRequestException({
                    message: "ظ„ط§ ظٹظ…ظƒظ† طھظپط¹ظٹظ„ ط§ظ„ط¹ط±ط¶ ظ‚ط¨ظ„ ط§ط¹طھظ…ط§ط¯ ط§ظ„طھط§ط¬ط±",
                    error_code: "MERCHANT_NOT_APPROVED",
                });
            }
            if (listing.availableQuantity <= listing.reservedQuantity) {
                throw new common_1.BadRequestException({
                    message: "ظ„ط§ ظٹظ…ظƒظ† طھظپط¹ظٹظ„ ط§ظ„ط¹ط±ط¶ ط¨ط¯ظˆظ† ظƒظ…ظٹط© ظ…طھط§ط­ط©",
                    error_code: "NO_AVAILABLE_STOCK",
                });
            }
        }
        const data = await this.db.listing.update({
            where: { id },
            data: {
                status: dto.status,
                publishedAt: dto.status === "ACTIVE" ? new Date() : listing.publishedAt,
            },
        });
        return { success: true, message: "Listing status updated", data };
    }
    async orders(userId) {
        const memberships = await this.prisma.organizationMember.findMany({
            where: { userId },
            select: { organizationId: true },
        });
        const organizationIds = memberships.map((m) => m.organizationId);
        const data = await this.db.order.findMany({
            where: { organizationId: { in: organizationIds } },
            include: {
                items: true,
                user: true,
                branch: true,
                statusHistory: { orderBy: { createdAt: "asc" } },
            },
            orderBy: { createdAt: "desc" },
        });
        return { success: true, data };
    }
    async orderDetails(userId, orderId) {
        const order = await this.db.order.findUnique({
            where: { id: orderId },
            include: {
                items: { include: { listing: { include: { product: true } } } },
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        phoneNormalized: true,
                        email: true,
                    },
                },
                organization: true,
                branch: true,
                invoices: true,
                fees: true,
                statusHistory: { orderBy: { createdAt: "asc" } },
            },
        });
        if (!order)
            throw new common_1.NotFoundException({
                message: "Order not found",
                error_code: "ORDER_NOT_FOUND",
            });
        await this.assertMembership(userId, order.organizationId);
        return { success: true, data: order };
    }
    validateOrderTransition(currentStatus, nextStatus) {
        if (TERMINAL_ORDER_STATUSES.includes(currentStatus)) {
            throw new common_1.BadRequestException({
                message: "ظ„ط§ ظٹظ…ظƒظ† طھط¹ط¯ظٹظ„ ط·ظ„ط¨ ظ…ط؛ظ„ظ‚",
                error_code: "ORDER_ALREADY_CLOSED",
            });
        }
        const allowed = ALLOWED_MERCHANT_TRANSITIONS[currentStatus] ?? [];
        if (!allowed.includes(nextStatus)) {
            throw new common_1.BadRequestException({
                message: `ط§ظ†طھظ‚ط§ظ„ ط­ط§ظ„ط© ط؛ظٹط± ظ…ط³ظ…ظˆط­ ظ…ظ† ${currentStatus} ط¥ظ„ظ‰ ${nextStatus}`,
                error_code: "INVALID_ORDER_STATUS_TRANSITION",
            });
        }
    }
    async releaseReservedStock(tx, order, userId) {
        for (const item of order.items) {
            const listing = await tx.listing.findUnique({
                where: { id: item.listingId },
            });
            const beforeReserved = Number(listing?.reservedQuantity ?? 0);
            const quantity = Number(item.quantity);
            await tx.listing.update({
                where: { id: item.listingId },
                data: { reservedQuantity: { decrement: quantity } },
            });
            await tx.listingInventory
                .update({
                where: { listingId: item.listingId },
                data: { reservedQuantity: { decrement: quantity } },
            })
                .catch(() => null);
            await tx.stockMovement
                .create({
                data: {
                    listingId: item.listingId,
                    movementType: "ORDER_RESERVATION_RELEASED",
                    quantity: -quantity,
                    quantityBefore: beforeReserved,
                    quantityAfter: Math.max(beforeReserved - quantity, 0),
                    reason: "Order cancelled by merchant",
                    referenceType: "ORDER",
                    referenceId: String(order.id),
                    createdByUserId: userId,
                },
            })
                .catch(() => null);
        }
    }
    async commitDeliveredStock(tx, order, userId) {
        for (const item of order.items) {
            const listing = await tx.listing.findUnique({
                where: { id: item.listingId },
            });
            const beforeAvailable = Number(listing?.availableQuantity ?? 0);
            const quantity = Number(item.quantity);
            await tx.listing.update({
                where: { id: item.listingId },
                data: {
                    reservedQuantity: { decrement: quantity },
                    availableQuantity: { decrement: quantity },
                },
            });
            await tx.listingInventory
                .update({
                where: { listingId: item.listingId },
                data: {
                    reservedQuantity: { decrement: quantity },
                    availableQuantity: { decrement: quantity },
                },
            })
                .catch(() => null);
            await tx.stockMovement
                .create({
                data: {
                    listingId: item.listingId,
                    movementType: "ORDER_SOLD",
                    quantity: -quantity,
                    quantityBefore: beforeAvailable,
                    quantityAfter: beforeAvailable - quantity,
                    reason: "Order delivered by merchant",
                    referenceType: "ORDER",
                    referenceId: String(order.id),
                    createdByUserId: userId,
                },
            })
                .catch(() => null);
        }
    }
    async updateOrderStatus(userId, orderId, dto) {
        const order = await this.db.order.findUnique({
            where: { id: orderId },
            include: { items: true },
        });
        if (!order)
            throw new common_1.NotFoundException({
                message: "Order not found",
                error_code: "ORDER_NOT_FOUND",
            });
        await this.assertMembership(userId, order.organizationId);
        this.validateOrderTransition(order.status, dto.status);
        const data = await this.db.$transaction(async (tx) => {
            const updatePayload = { status: dto.status };
            if (dto.status === "CANCELLED")
                updatePayload.cancellationReason = dto.note ?? null;
            const updated = await tx.order.update({
                where: { id: orderId },
                data: updatePayload,
            });
            await tx.orderStatusHistory.create({
                data: {
                    orderId,
                    status: dto.status,
                    changedByUserId: userId,
                    note: dto.note,
                },
            });
            if (dto.status === "DELIVERED") {
                await this.commitDeliveredStock(tx, order, userId);
                if (["CASH_ON_DELIVERY", "CASH_ON_PICKUP"].includes(order.paymentMethod)) {
                    await this.accounting.postCodDeliveredForOrder(tx, order, userId);
                }
            }
            if (dto.status === "CANCELLED") {
                await this.releaseReservedStock(tx, order, userId);
            }
            return updated;
        });
        await this.audit
            .write({
            actorUserId: userId,
            action: "merchant.order.status_updated",
            entityType: "order",
            entityId: orderId,
            metadata: {
                status: dto.status,
                note: dto.note ?? null,
                organization_id: order.organizationId,
            },
        })
            .catch(() => null);
        return { success: true, message: "Order status updated", data };
    }
};
exports.MerchantService = MerchantService;
exports.MerchantService = MerchantService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        audit_service_1.AuditService,
        accounting_service_1.AccountingService,
        reviews_service_1.ReviewsService])
], MerchantService);
