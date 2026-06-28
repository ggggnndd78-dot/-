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
exports.OrganizationsService = void 0;
const common_1 = require("@nestjs/common");
const event_bus_service_1 = require("../../common/events/event-bus.service");
const audit_service_1 = require("../audit/audit.service");
const notifications_service_1 = require("../notifications/notifications.service");
const prisma_service_1 = require("../../prisma/prisma.service");
let OrganizationsService = class OrganizationsService {
    constructor(prisma, audit, notifications, eventBus) {
        this.prisma = prisma;
        this.audit = audit;
        this.notifications = notifications;
        this.eventBus = eventBus;
    }
    async getOrganizationForMember(userId, organizationPublicId) {
        const organization = await this.prisma.organization.findUnique({
            where: { publicId: organizationPublicId },
            include: {
                members: true,
                branches: {
                    include: {
                        city: true,
                        district: true,
                        area: true,
                        businessHours: true,
                    },
                    orderBy: [{ isHeadOffice: "desc" }, { createdAt: "asc" }],
                },
                merchantProfile: true,
                workshopProfile: true,
                bankAccounts: true,
                verificationRequests: {
                    include: { documents: true, submittedBy: true, reviewedBy: true },
                    orderBy: { createdAt: "desc" },
                },
            },
        });
        if (!organization)
            throw new common_1.NotFoundException("Organization not found");
        const member = organization.members.find((m) => m.userId === userId);
        if (!member) {
            throw new common_1.ForbiddenException("You are not a member of this organization");
        }
        return { organization, member };
    }
    ensureOwnerCanManageBranches(member) {
        if (![
            "owner",
            "merchant_owner",
            "workshop_owner",
            "warehouse_owner",
        ].includes(member.memberRole)) {
            throw new common_1.ForbiddenException({
                message: "Only organization owners can manage branches and employees",
                error_code: "ORG_OWNER_REQUIRED",
            });
        }
    }
    ensureMemberCanViewAuditLogs(member) {
        const isOwner = [
            "owner",
            "merchant_owner",
            "workshop_owner",
            "warehouse_owner",
        ].includes(member.memberRole);
        const permissionCodes = Array.isArray(member.permissions)
            ? member.permissions.map((item) => String(item.permissionCode))
            : [];
        if (isOwner || permissionCodes.includes("view_audit_logs")) {
            return;
        }
        throw new common_1.ForbiddenException({
            message: "You do not have permission to view organization audit logs",
            error_code: "ORG_AUDIT_LOG_PERMISSION_REQUIRED",
        });
    }
    readAuditMetadata(metadata) {
        if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
            return {};
        }
        return metadata;
    }
    mapBranch(branch) {
        return {
            id: branch.publicId,
            branch_name: branch.branchName,
            email: branch.email,
            phone: branch.phone,
            city_id: branch.cityId,
            city_name: branch.city?.nameAr,
            district_id: branch.districtId,
            district_name: branch.district?.nameAr,
            area_id: branch.areaId,
            area_name: branch.area?.nameAr,
            address_line_1: branch.addressLine1,
            latitude: branch.latitude?.toString() ?? null,
            longitude: branch.longitude?.toString() ?? null,
            map_url: branch.mapUrl ?? null,
            map_provider: branch.mapProvider ?? null,
            location_selected_at: branch.locationSelectedAt ?? null,
            is_head_office: branch.isHeadOffice,
            supports_pickup: branch.supportsPickup,
            supports_delivery: branch.supportsDelivery,
            supports_installation: branch.supportsInstallation,
            supports_mobile_service: branch.supportsMobileService,
            is_active: branch.isActive,
            temporarily_closed: branch.temporarilyClosed,
            closed_until: branch.closedUntil,
            closed_reason: branch.closedReason,
            business_hours: (branch.businessHours ?? []).map((item) => ({
                day_of_week: item.dayOfWeek,
                open_time: item.openTime,
                close_time: item.closeTime,
                is_closed: item.isClosed,
            })),
        };
    }
    async assertAdmin(userId) {
        const adminRole = await this.prisma.userRole.findFirst({
            where: {
                userId,
                OR: [
                    { role: { code: { in: ["admin_super", "admin_operations"] } } },
                    {
                        role: {
                            rolePermissions: {
                                some: {
                                    permission: {
                                        code: {
                                            in: [
                                                "review_verifications",
                                                "memberships.review",
                                                "memberships.documents.view",
                                            ],
                                        },
                                    },
                                },
                            },
                        },
                    },
                ],
            },
            include: { role: true },
        });
        if (!adminRole) {
            throw new common_1.ForbiddenException("You do not have admin permission for this action");
        }
        return adminRole.role.code;
    }
    async getOrganizationOwner(organizationId) {
        return this.prisma.organizationMember.findFirst({
            where: { organizationId, memberRole: "owner" },
            include: { user: true },
            orderBy: { createdAt: "asc" },
        });
    }
    arabicOrganizationType(type) {
        if (type === "MERCHANT")
            return "التاجر";
        if (type === "WORKSHOP")
            return "الورشة";
        if (type === "WAREHOUSE")
            return "المستودع";
        return "المنشأة";
    }
    async notifyOwnerByReviewResult(input) {
        const owner = await this.getOrganizationOwner(input.organizationId);
        if (!owner)
            return;
        const orgTypeLabel = this.arabicOrganizationType(input.organizationType);
        const messages = {
            APPROVED: {
                title: `تم اعتماد ${orgTypeLabel}`,
                body: input.organizationType === "MERCHANT"
                    ? "تم اعتماد حساب التاجر في غيارك بنجاح. يمكنك الآن الدخول إلى لوحة التاجر والبدء في إدارة أعمالك."
                    : input.organizationType === "WORKSHOP"
                        ? "تم اعتماد حساب الورشة في غيارك بنجاح. يمكنك الآن الدخول إلى لوحة الورشة والبدء في إدارة خدماتك."
                        : `تم اعتماد ${input.organizationName}. يمكنك الآن استخدام لوحة التحكم حسب صلاحياتك.`,
                event: "VerificationApproved",
            },
            REJECTED: {
                title: `تم رفض طلب اعتماد ${orgTypeLabel}`,
                body: input.notes ||
                    "تعذر اعتماد طلبك لأن المعلومات أو المستندات المقدمة لا تطابق متطلبات المنصة. يرجى تحديث البيانات وإرسال طلب جديد. للتواصل: ggggnndd78@gmail.com",
                event: "VerificationRejected",
            },
            DOCUMENTS_REQUIRED: {
                title: "مطلوب مستندات إضافية",
                body: input.notes ||
                    `يحتاج طلب اعتماد ${input.organizationName} إلى مستندات أو بيانات إضافية.`,
                event: "VerificationDocumentsRequired",
            },
            SUSPENDED: {
                title: `تم تعليق ${orgTypeLabel}`,
                body: input.notes ||
                    `تم تعليق ${input.organizationName}. تواصل مع الإدارة لمعرفة التفاصيل.`,
                event: "VerificationSuspended",
            },
        };
        const message = messages[input.status];
        if (!message)
            return;
        const channel = input.notificationChannel ?? "BOTH";
        await this.notifications.dispatchToUser(owner.userId, {
            title: message.title,
            body: message.body,
            data: {
                organization_id: input.organizationId,
                organization_name: input.organizationName,
                verification_status: input.status,
                event: message.event,
            },
            sendInApp: true,
            sendEmail: channel === "EMAIL" || channel === "BOTH",
            sendSms: channel === "SMS" || channel === "BOTH",
            sendPush: true,
            eventKey: message.event,
        });
    }
    mapOrganization(organization) {
        return {
            id: organization.publicId,
            organization_type: organization.organizationType,
            display_name: organization.displayName,
            legal_name: organization.legalName,
            primary_phone: organization.primaryPhone,
            status: organization.status,
            is_verified: organization.isVerified,
            submitted_at: organization.submittedAt,
            approved_at: organization.approvedAt,
            rejected_at: organization.rejectedAt,
            rejection_reason: organization.rejectionReason,
            merchant_profile: organization.merchantProfile
                ? {
                    business_category_code: organization.merchantProfile.businessCategoryCode,
                    average_preparation_minutes: organization.merchantProfile.averagePreparationMinutes,
                    warranty_policy_text: organization.merchantProfile.warrantyPolicyText,
                    return_policy_text: organization.merchantProfile.returnPolicyText,
                    delivery_policy_text: organization.merchantProfile.deliveryPolicyText,
                    min_order_amount: organization.merchantProfile.minOrderAmount?.toString(),
                }
                : null,
            workshop_profile: organization.workshopProfile
                ? {
                    service_mode_code: organization.workshopProfile.serviceModeCode,
                    accepts_diagnosis: organization.workshopProfile.acceptsDiagnosis,
                    accepts_installation: organization.workshopProfile.acceptsInstallation,
                    capacity_per_day: organization.workshopProfile.capacityPerDay,
                    supports_emergency_service: organization.workshopProfile.supportsEmergencyService,
                    default_diagnosis_fee: organization.workshopProfile.defaultDiagnosisFee?.toString(),
                }
                : null,
            branches: (organization.branches ?? []).map((branch) => ({
                id: branch.publicId,
                branch_name: branch.branchName,
                email: branch.email,
                phone: branch.phone,
                city_id: branch.cityId,
                city_name: branch.city?.nameAr,
                district_id: branch.districtId,
                district_name: branch.district?.nameAr,
                area_id: branch.areaId,
                area_name: branch.area?.nameAr,
                address_line_1: branch.addressLine1,
                latitude: branch.latitude?.toString() ?? null,
                longitude: branch.longitude?.toString() ?? null,
                map_url: branch.mapUrl ?? null,
                map_provider: branch.mapProvider ?? null,
                location_selected_at: branch.locationSelectedAt ?? null,
                is_head_office: branch.isHeadOffice,
                supports_pickup: branch.supportsPickup,
                supports_delivery: branch.supportsDelivery,
                supports_installation: branch.supportsInstallation,
                supports_mobile_service: branch.supportsMobileService,
                is_active: branch.isActive,
                temporarily_closed: branch.temporarilyClosed,
                closed_until: branch.closedUntil,
                closed_reason: branch.closedReason,
                business_hours: (branch.businessHours ?? []).map((item) => ({
                    day_of_week: item.dayOfWeek,
                    open_time: item.openTime,
                    close_time: item.closeTime,
                    is_closed: item.isClosed,
                })),
            })),
            bank_accounts: (organization.bankAccounts ?? []).map((bank) => ({
                id: bank.id,
                bank_name: bank.bankName,
                account_name: bank.accountName,
                account_number: bank.accountNumber,
                iban: bank.iban,
                is_primary: bank.isPrimary,
            })),
            verification_requests: (organization.verificationRequests ?? []).map((request) => ({
                id: request.publicId,
                status: request.status,
                notes: request.notes,
                review_notes: request.reviewNotes,
                submitted_at: request.submittedAt,
                reviewed_at: request.reviewedAt,
                submitted_by: request.submittedBy?.displayName ??
                    request.submittedBy?.phoneNormalized,
                reviewed_by: request.reviewedBy?.displayName ??
                    request.reviewedBy?.phoneNormalized,
                documents_count: request.documents?.length ?? 0,
            })),
        };
    }
    async create(userId, dto) {
        const created = await this.prisma.organization.create({
            data: {
                organizationType: dto.organizationType,
                displayName: dto.displayName,
                legalName: dto.legalName,
                primaryPhone: dto.primaryPhone,
                status: "DRAFT",
                members: {
                    create: {
                        userId,
                        memberRole: "owner",
                    },
                },
            },
        });
        return {
            success: true,
            message: "Organization created successfully",
            data: {
                id: created.publicId,
                organization_type: created.organizationType,
                display_name: created.displayName,
                status: created.status,
            },
        };
    }
    async mine(userId) {
        const organizations = await this.prisma.organizationMember.findMany({
            where: { userId },
            include: {
                organization: {
                    include: {
                        branches: true,
                        merchantProfile: true,
                        workshopProfile: true,
                        verificationRequests: { orderBy: { createdAt: "desc" }, take: 1 },
                    },
                },
            },
            orderBy: { createdAt: "desc" },
        });
        return {
            success: true,
            message: "Organizations retrieved successfully",
            data: organizations.map((item) => ({
                id: item.organization.publicId,
                display_name: item.organization.displayName,
                legal_name: item.organization.legalName,
                organization_type: item.organization.organizationType,
                status: item.organization.status,
                member_role: item.memberRole,
                has_merchant_profile: !!item.organization.merchantProfile,
                has_workshop_profile: !!item.organization.workshopProfile,
                latest_verification_status: item.organization.verificationRequests[0]?.status ?? null,
                branches_count: item.organization.branches.length,
            })),
        };
    }
    async detailForMember(userId, organizationPublicId) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        return {
            success: true,
            message: "Organization details retrieved successfully",
            data: this.mapOrganization(organization),
        };
    }
    async listAuditLogs(userId, organizationPublicId, query) {
        const organization = await this.prisma.organization.findUnique({
            where: { publicId: organizationPublicId },
            include: {
                members: {
                    where: { status: "ACTIVE" },
                    include: { permissions: true },
                },
            },
        });
        if (!organization) {
            throw new common_1.NotFoundException("Organization not found");
        }
        const member = organization.members.find((item) => item.userId === userId);
        if (!member) {
            throw new common_1.ForbiddenException("You are not a member of this organization");
        }
        this.ensureMemberCanViewAuditLogs(member);
        const take = Math.min(Math.max(query.take ?? 50, 1), 200);
        const skip = Math.max(query.skip ?? 0, 0);
        const fetchWindow = Math.min(Math.max((take + skip) * 8, 120), 1000);
        const memberUserIds = organization.members.map((item) => item.userId);
        const candidates = await this.prisma.auditLog.findMany({
            where: query.action
                ? { action: query.action }
                : {
                    OR: [
                        { actorUserId: { in: memberUserIds } },
                        { action: { startsWith: "organization." } },
                        { action: { startsWith: "merchant." } },
                        { action: { startsWith: "reviews." } },
                        { action: { startsWith: "orders." } },
                        { action: { startsWith: "delivery." } },
                    ],
                },
            orderBy: { createdAt: "desc" },
            take: fetchWindow,
        });
        const relevant = candidates.filter((log) => {
            if (log.actorUserId != null && memberUserIds.includes(log.actorUserId)) {
                return true;
            }
            const metadata = this.readAuditMetadata(log.metadata);
            const organizationMarkers = [
                metadata["organization_id"],
                metadata["organizationId"],
                metadata["organization_public_id"],
                metadata["organizationPublicId"],
            ]
                .filter((value) => value != null)
                .map((value) => String(value));
            return (organizationMarkers.includes(String(organization.id)) ||
                organizationMarkers.includes(organization.publicId));
        });
        return {
            success: true,
            data: relevant.slice(skip, skip + take),
        };
    }
    async update(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const updated = await this.prisma.organization.update({
            where: { id: organization.id },
            data: {
                displayName: dto.displayName ?? organization.displayName,
                legalName: dto.legalName ?? organization.legalName,
                primaryPhone: dto.primaryPhone ?? organization.primaryPhone,
            },
        });
        return {
            success: true,
            message: "Organization updated successfully",
            data: {
                id: updated.publicId,
                display_name: updated.displayName,
                legal_name: updated.legalName,
                primary_phone: updated.primaryPhone,
            },
        };
    }
    async createBranch(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        if (dto.isHeadOffice) {
            await this.prisma.organizationBranch.updateMany({
                where: { organizationId: organization.id },
                data: { isHeadOffice: false },
            });
        }
        const branch = await this.prisma.organizationBranch.create({
            data: {
                organizationId: organization.id,
                branchName: dto.branchName,
                email: dto.email,
                phone: dto.phone,
                cityId: dto.cityId,
                districtId: dto.districtId,
                areaId: dto.areaId,
                addressLine1: dto.addressLine1,
                latitude: dto.latitude,
                longitude: dto.longitude,
                mapUrl: dto.mapUrl ??
                    (dto.latitude != null && dto.longitude != null
                        ? `https://www.google.com/maps/search/?api=1&query=${dto.latitude},${dto.longitude}`
                        : undefined),
                mapProvider: "GOOGLE_MAPS",
                locationSelectedAt: dto.latitude != null && dto.longitude != null
                    ? new Date()
                    : undefined,
                isHeadOffice: dto.isHeadOffice ?? false,
                supportsPickup: dto.supportsPickup ?? true,
                supportsDelivery: dto.supportsDelivery ?? false,
                supportsInstallation: dto.supportsInstallation ?? false,
                supportsMobileService: dto.supportsMobileService ?? false,
            },
            include: { city: true, district: true, area: true },
        });
        await this.audit.write({
            actorUserId: userId,
            action: "organization.branch.created",
            entityType: "organization_branch",
            entityId: branch.publicId,
            metadata: { organization_id: organization.publicId },
        });
        return {
            success: true,
            message: "Branch created successfully",
            data: {
                id: branch.publicId,
                branch_name: branch.branchName,
                city_name: branch.city.nameAr,
                district_name: branch.district?.nameAr,
                area_name: branch.area?.nameAr,
            },
        };
    }
    async listBranches(userId, organizationPublicId) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const branches = await this.prisma.organizationBranch.findMany({
            where: { organizationId: organization.id },
            include: { city: true, district: true, area: true, businessHours: true },
            orderBy: [{ isHeadOffice: "desc" }, { createdAt: "asc" }],
        });
        return {
            success: true,
            message: "Branches retrieved successfully",
            data: branches.map((branch) => this.mapBranch(branch)),
        };
    }
    async updateBranch(userId, organizationPublicId, branchPublicId, dto) {
        const { organization, member } = await this.getOrganizationForMember(userId, organizationPublicId);
        this.ensureOwnerCanManageBranches(member);
        const branch = await this.prisma.organizationBranch.findFirst({
            where: { publicId: branchPublicId, organizationId: organization.id },
        });
        if (!branch)
            throw new common_1.NotFoundException({
                message: "Branch not found",
                error_code: "BRANCH_NOT_FOUND",
            });
        if (dto.isHeadOffice) {
            await this.prisma.organizationBranch.updateMany({
                where: { organizationId: organization.id, id: { not: branch.id } },
                data: { isHeadOffice: false },
            });
        }
        const updated = await this.prisma.organizationBranch.update({
            where: { id: branch.id },
            data: {
                branchName: dto.branchName ?? branch.branchName,
                email: dto.email ?? branch.email,
                phone: dto.phone ?? branch.phone,
                cityId: dto.cityId ?? branch.cityId,
                districtId: dto.districtId ?? branch.districtId,
                areaId: dto.areaId ?? branch.areaId,
                addressLine1: dto.addressLine1 ?? branch.addressLine1,
                latitude: dto.latitude ?? branch.latitude,
                longitude: dto.longitude ?? branch.longitude,
                mapUrl: dto.mapUrl ?? branch.mapUrl,
                mapProvider: dto.mapUrl ? "GOOGLE_MAPS" : branch.mapProvider,
                locationSelectedAt: dto.latitude != null && dto.longitude != null
                    ? new Date()
                    : branch.locationSelectedAt,
                isHeadOffice: dto.isHeadOffice ?? branch.isHeadOffice,
                supportsPickup: dto.supportsPickup ?? branch.supportsPickup,
                supportsDelivery: dto.supportsDelivery ?? branch.supportsDelivery,
                supportsInstallation: dto.supportsInstallation ?? branch.supportsInstallation,
                supportsMobileService: dto.supportsMobileService ?? branch.supportsMobileService,
            },
            include: { city: true, district: true, area: true, businessHours: true },
        });
        await this.audit.write({
            actorUserId: userId,
            action: "organization.branch.updated",
            entityType: "organization_branch",
            entityId: updated.publicId,
            metadata: { organization_id: organization.publicId },
        });
        return {
            success: true,
            message: "Branch updated successfully",
            data: this.mapBranch(updated),
        };
    }
    async setBranchClosure(userId, organizationPublicId, branchPublicId, dto) {
        const { organization, member } = await this.getOrganizationForMember(userId, organizationPublicId);
        this.ensureOwnerCanManageBranches(member);
        const branch = await this.prisma.organizationBranch.findFirst({
            where: { publicId: branchPublicId, organizationId: organization.id },
        });
        if (!branch)
            throw new common_1.NotFoundException({
                message: "Branch not found",
                error_code: "BRANCH_NOT_FOUND",
            });
        const updated = await this.prisma.organizationBranch.update({
            where: { id: branch.id },
            data: {
                temporarilyClosed: dto.temporarilyClosed,
                closedUntil: dto.temporarilyClosed && dto.closedUntil
                    ? new Date(dto.closedUntil)
                    : null,
                closedReason: dto.temporarilyClosed ? (dto.closedReason ?? null) : null,
            },
            include: { city: true, district: true, area: true, businessHours: true },
        });
        await this.audit.write({
            actorUserId: userId,
            action: dto.temporarilyClosed
                ? "organization.branch.closed"
                : "organization.branch.reopened",
            entityType: "organization_branch",
            entityId: updated.publicId,
            metadata: {
                organization_id: organization.publicId,
                reason: dto.closedReason ?? null,
            },
        });
        return {
            success: true,
            message: "Branch closure status updated successfully",
            data: this.mapBranch(updated),
        };
    }
    async upsertBranchBusinessHours(userId, organizationPublicId, branchPublicId, dto) {
        const { organization, member } = await this.getOrganizationForMember(userId, organizationPublicId);
        this.ensureOwnerCanManageBranches(member);
        const branch = await this.prisma.organizationBranch.findFirst({
            where: { publicId: branchPublicId, organizationId: organization.id },
        });
        if (!branch)
            throw new common_1.NotFoundException({
                message: "Branch not found",
                error_code: "BRANCH_NOT_FOUND",
            });
        const uniqueDays = new Set(dto.items.map((item) => item.dayOfWeek));
        if (uniqueDays.size !== dto.items.length)
            throw new common_1.BadRequestException("Each day of week must appear once only");
        await this.prisma.$transaction(dto.items.map((item) => this.prisma.branchBusinessHour.upsert({
            where: {
                branchId_dayOfWeek: {
                    branchId: branch.id,
                    dayOfWeek: item.dayOfWeek,
                },
            },
            update: {
                openTime: item.isClosed ? null : item.openTime,
                closeTime: item.isClosed ? null : item.closeTime,
                isClosed: item.isClosed,
            },
            create: {
                branchId: branch.id,
                dayOfWeek: item.dayOfWeek,
                openTime: item.isClosed ? null : item.openTime,
                closeTime: item.isClosed ? null : item.closeTime,
                isClosed: item.isClosed,
            },
        })));
        await this.audit.write({
            actorUserId: userId,
            action: "organization.branch.business_hours.updated",
            entityType: "organization_branch",
            entityId: branch.publicId,
            metadata: { organization_id: organization.publicId },
        });
        const updated = await this.prisma.organizationBranch.findUnique({
            where: { id: branch.id },
            include: { city: true, district: true, area: true, businessHours: true },
        });
        return {
            success: true,
            message: "Branch business hours saved successfully",
            data: this.mapBranch(updated),
        };
    }
    async getBusinessHours(userId, organizationPublicId) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const headOffice = organization.branches.find((b) => b.isHeadOffice) ??
            organization.branches[0];
        if (!headOffice) {
            throw new common_1.NotFoundException("Organization has no branch yet");
        }
        return {
            success: true,
            message: "Business hours retrieved successfully",
            data: {
                branch_id: headOffice.publicId,
                branch_name: headOffice.branchName,
                items: headOffice.businessHours.map((item) => ({
                    day_of_week: item.dayOfWeek,
                    open_time: item.openTime,
                    close_time: item.closeTime,
                    is_closed: item.isClosed,
                })),
            },
        };
    }
    async upsertBusinessHours(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const headOffice = organization.branches.find((b) => b.isHeadOffice) ??
            organization.branches[0];
        if (!headOffice) {
            throw new common_1.NotFoundException("Organization has no branch yet");
        }
        const uniqueDays = new Set(dto.items.map((item) => item.dayOfWeek));
        if (uniqueDays.size !== dto.items.length) {
            throw new common_1.BadRequestException("Each day of week must appear once only");
        }
        await this.prisma.$transaction(dto.items.map((item) => this.prisma.branchBusinessHour.upsert({
            where: {
                branchId_dayOfWeek: {
                    branchId: headOffice.id,
                    dayOfWeek: item.dayOfWeek,
                },
            },
            update: {
                openTime: item.isClosed ? null : item.openTime,
                closeTime: item.isClosed ? null : item.closeTime,
                isClosed: item.isClosed,
            },
            create: {
                branchId: headOffice.id,
                dayOfWeek: item.dayOfWeek,
                openTime: item.isClosed ? null : item.openTime,
                closeTime: item.isClosed ? null : item.closeTime,
                isClosed: item.isClosed,
            },
        })));
        return this.getBusinessHours(userId, organizationPublicId);
    }
    async upsertMerchantProfile(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        if (organization.organizationType !== "MERCHANT") {
            throw new common_1.BadRequestException("This organization is not a merchant");
        }
        const profile = await this.prisma.merchantProfile.upsert({
            where: { organizationId: organization.id },
            update: {
                businessCategoryCode: dto.businessCategoryCode,
                averagePreparationMinutes: dto.averagePreparationMinutes,
                warrantyPolicyText: dto.warrantyPolicyText,
                returnPolicyText: dto.returnPolicyText,
                deliveryPolicyText: dto.deliveryPolicyText,
                minOrderAmount: dto.minOrderAmount,
            },
            create: {
                organizationId: organization.id,
                businessCategoryCode: dto.businessCategoryCode,
                averagePreparationMinutes: dto.averagePreparationMinutes,
                warrantyPolicyText: dto.warrantyPolicyText,
                returnPolicyText: dto.returnPolicyText,
                deliveryPolicyText: dto.deliveryPolicyText,
                minOrderAmount: dto.minOrderAmount,
            },
        });
        return {
            success: true,
            message: "Merchant profile saved successfully",
            data: {
                organization_id: organization.publicId,
                business_category_code: profile.businessCategoryCode,
                average_preparation_minutes: profile.averagePreparationMinutes,
                min_order_amount: profile.minOrderAmount?.toString() ?? null,
            },
        };
    }
    async upsertWorkshopProfile(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        if (organization.organizationType !== "WORKSHOP") {
            throw new common_1.BadRequestException("This organization is not a workshop");
        }
        const profile = await this.prisma.workshopProfile.upsert({
            where: { organizationId: organization.id },
            update: {
                serviceModeCode: dto.serviceModeCode,
                acceptsDiagnosis: dto.acceptsDiagnosis,
                acceptsInstallation: dto.acceptsInstallation,
                capacityPerDay: dto.capacityPerDay,
                supportsEmergencyService: dto.supportsEmergencyService,
                defaultDiagnosisFee: dto.defaultDiagnosisFee,
            },
            create: {
                organizationId: organization.id,
                serviceModeCode: dto.serviceModeCode,
                acceptsDiagnosis: dto.acceptsDiagnosis ?? true,
                acceptsInstallation: dto.acceptsInstallation ?? true,
                capacityPerDay: dto.capacityPerDay,
                supportsEmergencyService: dto.supportsEmergencyService ?? false,
                defaultDiagnosisFee: dto.defaultDiagnosisFee,
            },
        });
        return {
            success: true,
            message: "Workshop profile saved successfully",
            data: {
                organization_id: organization.publicId,
                service_mode_code: profile.serviceModeCode,
                accepts_diagnosis: profile.acceptsDiagnosis,
                accepts_installation: profile.acceptsInstallation,
                capacity_per_day: profile.capacityPerDay,
                default_diagnosis_fee: profile.defaultDiagnosisFee?.toString() ?? null,
            },
        };
    }
    async listBankAccounts(userId, organizationPublicId) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const items = await this.prisma.bankAccount.findMany({
            where: { organizationId: organization.id },
            orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }],
        });
        return {
            success: true,
            message: "Bank accounts retrieved successfully",
            data: items.map((item) => ({
                id: item.id,
                bank_name: item.bankName,
                account_name: item.accountName,
                account_number: item.accountNumber,
                iban: item.iban,
                is_primary: item.isPrimary,
            })),
        };
    }
    async createBankAccount(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        if (dto.isPrimary) {
            await this.prisma.bankAccount.updateMany({
                where: { organizationId: organization.id },
                data: { isPrimary: false },
            });
        }
        const account = await this.prisma.bankAccount.create({
            data: {
                organizationId: organization.id,
                bankName: dto.bankName,
                accountName: dto.accountName,
                accountNumber: dto.accountNumber,
                iban: dto.iban,
                isPrimary: dto.isPrimary ?? false,
            },
        });
        return {
            success: true,
            message: "Bank account created successfully",
            data: {
                id: account.id,
                bank_name: account.bankName,
                is_primary: account.isPrimary,
            },
        };
    }
    async submitVerificationRequest(userId, organizationPublicId, dto) {
        const { organization } = await this.getOrganizationForMember(userId, organizationPublicId);
        const existingOpenRequest = await this.prisma.verificationRequest.findFirst({
            where: {
                organizationId: organization.id,
                status: {
                    in: [
                        "SUBMITTED",
                        "PENDING_REVIEW",
                        "UNDER_REVIEW",
                        "DOCUMENTS_REQUIRED",
                    ],
                },
            },
        });
        if (existingOpenRequest) {
            throw new common_1.BadRequestException("There is already an active verification request for this organization");
        }
        const now = new Date();
        const request = await this.prisma.$transaction(async (tx) => {
            const created = await tx.verificationRequest.create({
                data: {
                    organizationId: organization.id,
                    submittedByUserId: userId,
                    status: "PENDING_REVIEW",
                    notes: dto.notes,
                    submittedAt: now,
                },
            });
            await tx.organization.update({
                where: { id: organization.id },
                data: {
                    status: "PENDING_REVIEW",
                    submittedAt: now,
                    approvedAt: null,
                    rejectedAt: null,
                    rejectionReason: null,
                    isVerified: false,
                },
            });
            await tx.verificationStatusHistory.create({
                data: {
                    verificationRequestId: created.id,
                    organizationId: organization.id,
                    fromStatus: "DRAFT",
                    toStatus: "PENDING_REVIEW",
                    changedByUserId: userId,
                    reason: dto.notes ?? "Provider submitted verification request",
                },
            });
            if (dto.notes) {
                await tx.verificationReviewNote.create({
                    data: {
                        verificationRequestId: created.id,
                        organizationId: organization.id,
                        actorUserId: userId,
                        noteType: "SUBMISSION",
                        note: dto.notes,
                    },
                });
            }
            await tx.approvalAction.create({
                data: {
                    organizationId: organization.id,
                    verificationRequestId: created.id,
                    actedByUserId: userId,
                    actionCode: "submitted",
                    notes: dto.notes,
                },
            });
            return created;
        });
        await this.eventBus.publish({
            name: `${organization.organizationType}OnboardingSubmitted`,
            aggregateType: "verification_request",
            aggregateId: request.publicId,
            actorUserId: userId,
            payload: {
                organization_id: organization.publicId,
                organization_type: organization.organizationType,
                request_status: request.status,
            },
        });
        await this.audit.write({
            actorUserId: userId,
            action: "verification.request.submitted",
            entityType: "verification_request",
            entityId: request.publicId,
            metadata: {
                organization_id: organization.publicId,
                organization_type: organization.organizationType,
            },
        });
        return {
            success: true,
            message: "Verification request submitted successfully",
            data: {
                id: request.publicId,
                status: request.status,
                submitted_at: request.submittedAt,
            },
        };
    }
    async getVerificationRequest(userId, requestPublicId) {
        const request = await this.prisma.verificationRequest.findUnique({
            where: { publicId: requestPublicId },
            include: {
                organization: { include: { members: true } },
                documents: true,
                reviewNotesList: {
                    include: { actor: true },
                    orderBy: { createdAt: "desc" },
                },
                statusHistory: {
                    include: { changedBy: true },
                    orderBy: { createdAt: "desc" },
                },
                submittedBy: true,
                reviewedBy: true,
            },
        });
        if (!request)
            throw new common_1.NotFoundException("Verification request not found");
        const isMember = request.organization.members.some((m) => m.userId === userId);
        if (!isMember)
            throw new common_1.ForbiddenException("You do not have access to this verification request");
        return {
            success: true,
            message: "Verification request retrieved successfully",
            data: {
                id: request.publicId,
                organization_id: request.organization.publicId,
                status: request.status,
                notes: request.notes,
                review_notes: request.reviewNotes,
                submitted_at: request.submittedAt,
                reviewed_at: request.reviewedAt,
                documents: request.documents.map((doc) => ({
                    id: doc.id,
                    document_type: doc.documentType,
                    file_name: doc.fileName,
                    file_url: doc.fileUrl,
                    mime_type: doc.mimeType,
                    file_size_bytes: doc.fileSizeBytes ?? null,
                    storage_provider: doc.storageProvider ?? null,
                    upload_status: doc.uploadStatus ?? null,
                    side: doc.side ?? null,
                    preview_base64: doc.fileContentBase64 ?? null,
                    notes: doc.notes,
                })),
                review_notes_history: request.reviewNotesList?.map((note) => ({
                    id: note.id,
                    note_type: note.noteType,
                    note: note.note,
                    actor: note.actor?.displayName ?? note.actor?.phoneNormalized ?? null,
                    created_at: note.createdAt,
                })) ?? [],
                status_history: request.statusHistory?.map((history) => ({
                    id: history.id,
                    from_status: history.fromStatus,
                    to_status: history.toStatus,
                    reason: history.reason,
                    changed_by: history.changedBy?.displayName ??
                        history.changedBy?.phoneNormalized ??
                        null,
                    created_at: history.createdAt,
                })) ?? [],
            },
        };
    }
    async addVerificationDocument(userId, requestPublicId, dto) {
        const request = await this.prisma.verificationRequest.findUnique({
            where: { publicId: requestPublicId },
            include: { organization: { include: { members: true } } },
        });
        if (!request)
            throw new common_1.NotFoundException("Verification request not found");
        const isMember = request.organization.members.some((m) => m.userId === userId);
        if (!isMember)
            throw new common_1.ForbiddenException("You do not have access to this verification request");
        const documentEditableStatuses = [
            "DRAFT",
            "SUBMITTED",
            "PENDING_REVIEW",
            "UNDER_REVIEW",
            "DOCUMENTS_REQUIRED",
        ];
        if (!documentEditableStatuses.includes(request.status)) {
            throw new common_1.BadRequestException("Cannot add documents to this verification request in its current status");
        }
        const document = await this.prisma.verificationDocument.create({
            data: {
                verificationRequestId: request.id,
                documentType: dto.documentType,
                fileName: dto.fileName,
                fileUrl: dto.fileUrl ?? "",
                mimeType: dto.mimeType,
                fileSizeBytes: dto.fileSizeBytes,
                fileContentBase64: dto.fileContentBase64,
                storageProvider: dto.fileContentBase64 ? "DATABASE" : "EXTERNAL",
                storageKey: dto.fileContentBase64
                    ? `${request.publicId}/${dto.documentType}/${dto.side ?? "MAIN"}/${dto.fileName}`
                    : dto.fileUrl,
                uploadStatus: "UPLOADED",
                side: dto.side ?? "MAIN",
                notes: dto.notes,
            },
        });
        await this.prisma.verificationReviewNote.create({
            data: {
                verificationRequestId: request.id,
                organizationId: request.organizationId,
                actorUserId: userId,
                noteType: "DOCUMENT_UPLOADED",
                note: dto.notes ?? `Uploaded document ${dto.documentType}: ${dto.fileName}`,
            },
        });
        await this.audit.write({
            actorUserId: userId,
            action: "verification.document.uploaded",
            entityType: "verification_document",
            entityId: document.id,
            metadata: {
                verification_request_id: request.publicId,
                document_type: dto.documentType,
            },
        });
        await this.eventBus.publish({
            name: "VerificationDocumentUploaded",
            aggregateType: "verification_request",
            aggregateId: request.publicId,
            actorUserId: userId,
            payload: {
                organization_id: request.organization.publicId,
                document_id: document.id,
                document_type: dto.documentType,
                file_name: dto.fileName,
            },
        });
        return {
            success: true,
            message: "Verification document added successfully",
            data: {
                id: document.id,
                document_type: document.documentType,
                file_name: document.fileName,
                file_url: document.fileUrl,
                storage_provider: document.storageProvider ?? null,
                upload_status: document.uploadStatus ?? null,
                side: document.side ?? null,
            },
        };
    }
    async listVerificationRequestsForAdmin(userId, status) {
        await this.assertAdmin(userId);
        const requests = await this.prisma.verificationRequest.findMany({
            where: status ? { status: status } : undefined,
            include: {
                organization: true,
                submittedBy: true,
                reviewedBy: true,
                documents: true,
            },
            orderBy: [{ updatedAt: "desc" }, { createdAt: "desc" }],
        });
        return {
            success: true,
            message: "Verification requests retrieved successfully",
            data: requests.map((request) => ({
                id: request.publicId,
                organization_id: request.organization.publicId,
                organization_name: request.organization.displayName,
                organization_type: request.organization.organizationType,
                organization_status: request.organization.status,
                request_status: request.status,
                submitted_at: request.submittedAt,
                reviewed_at: request.reviewedAt,
                documents_count: request.documents.length,
                submitted_by: request.submittedBy.displayName ??
                    request.submittedBy.phoneNormalized,
                can_review: [
                    "SUBMITTED",
                    "PENDING_REVIEW",
                    "UNDER_REVIEW",
                    "DOCUMENTS_REQUIRED",
                ].includes(request.status),
            })),
        };
    }
    async getVerificationRequestForAdmin(userId, requestPublicId) {
        await this.assertAdmin(userId);
        const request = await this.prisma.verificationRequest.findUnique({
            where: { publicId: requestPublicId },
            include: {
                organization: {
                    include: {
                        branches: {
                            include: {
                                city: true,
                                district: true,
                                area: true,
                                businessHours: true,
                            },
                        },
                        merchantProfile: true,
                        workshopProfile: true,
                        bankAccounts: true,
                    },
                },
                documents: true,
                reviewNotesList: {
                    include: { actor: true },
                    orderBy: { createdAt: "desc" },
                },
                statusHistory: {
                    include: { changedBy: true },
                    orderBy: { createdAt: "desc" },
                },
                submittedBy: true,
                reviewedBy: true,
                approvalActions: {
                    include: { actedBy: true },
                    orderBy: { createdAt: "desc" },
                },
            },
        });
        if (!request)
            throw new common_1.NotFoundException("Verification request not found");
        return {
            success: true,
            message: "Verification request details retrieved successfully",
            data: {
                id: request.publicId,
                status: request.status,
                notes: request.notes,
                review_notes: request.reviewNotes,
                submitted_at: request.submittedAt,
                reviewed_at: request.reviewedAt,
                organization: this.mapOrganization(request.organization),
                documents: request.documents.map((doc) => ({
                    id: doc.id,
                    document_type: doc.documentType,
                    file_name: doc.fileName,
                    file_url: doc.fileUrl,
                    mime_type: doc.mimeType,
                    file_size_bytes: doc.fileSizeBytes ?? null,
                    storage_provider: doc.storageProvider ?? null,
                    upload_status: doc.uploadStatus ?? null,
                    side: doc.side ?? null,
                    preview_base64: doc.fileContentBase64 ?? null,
                    notes: doc.notes,
                })),
                approval_actions: request.approvalActions.map((action) => ({
                    id: action.id,
                    action_code: action.actionCode,
                    notes: action.notes,
                    acted_by: action.actedBy.displayName ?? action.actedBy.phoneNormalized,
                    created_at: action.createdAt,
                })),
                review_notes_history: request.reviewNotesList?.map((note) => ({
                    id: note.id,
                    note_type: note.noteType,
                    note: note.note,
                    actor: note.actor?.displayName ?? note.actor?.phoneNormalized ?? null,
                    created_at: note.createdAt,
                })) ?? [],
                status_history: request.statusHistory?.map((history) => ({
                    id: history.id,
                    from_status: history.fromStatus,
                    to_status: history.toStatus,
                    reason: history.reason,
                    changed_by: history.changedBy?.displayName ??
                        history.changedBy?.phoneNormalized ??
                        null,
                    created_at: history.createdAt,
                })) ?? [],
            },
        };
    }
    async reviewVerificationRequest(userId, requestPublicId, action, dto) {
        await this.assertAdmin(userId);
        const request = await this.prisma.verificationRequest.findUnique({
            where: { publicId: requestPublicId },
            include: { organization: true },
        });
        if (!request)
            throw new common_1.NotFoundException("Verification request not found");
        const now = new Date();
        let requestStatus;
        let organizationStatus;
        let isVerified = false;
        let eventName = "VerificationReviewed";
        switch (action) {
            case "approve":
                requestStatus = "APPROVED";
                organizationStatus = "APPROVED";
                isVerified = true;
                eventName = "VerificationApproved";
                break;
            case "reject":
                requestStatus = "REJECTED";
                organizationStatus = "REJECTED";
                eventName = "VerificationRejected";
                break;
            case "require_documents":
                requestStatus = "DOCUMENTS_REQUIRED";
                organizationStatus = "DOCUMENTS_REQUIRED";
                eventName = "VerificationDocumentsRequired";
                break;
            case "suspend":
                requestStatus = "SUSPENDED";
                organizationStatus = "SUSPENDED";
                eventName = "VerificationSuspended";
                break;
            default:
                throw new common_1.BadRequestException("Unsupported review action");
        }
        const openStatuses = [
            "SUBMITTED",
            "PENDING_REVIEW",
            "UNDER_REVIEW",
            "DOCUMENTS_REQUIRED",
        ];
        if (!openStatuses.includes(request.status) && action !== "suspend") {
            throw new common_1.BadRequestException("This verification request is not reviewable in its current status");
        }
        await this.prisma.$transaction(async (tx) => {
            await tx.verificationRequest.update({
                where: { id: request.id },
                data: {
                    status: requestStatus,
                    reviewedAt: now,
                    reviewedByUserId: userId,
                    reviewNotes: dto.notes,
                },
            });
            await tx.organization.update({
                where: { id: request.organizationId },
                data: {
                    status: organizationStatus,
                    isVerified,
                    approvedAt: action === "approve" ? now : null,
                    rejectedAt: action === "reject" ? now : null,
                    rejectionReason: action === "approve" ? null : dto.notes,
                },
            });
            await tx.verificationStatusHistory.create({
                data: {
                    verificationRequestId: request.id,
                    organizationId: request.organizationId,
                    fromStatus: request.status,
                    toStatus: requestStatus,
                    changedByUserId: userId,
                    reason: dto.notes ?? action,
                },
            });
            await tx.verificationReviewNote.create({
                data: {
                    verificationRequestId: request.id,
                    organizationId: request.organizationId,
                    actorUserId: userId,
                    noteType: action.toUpperCase(),
                    note: dto.notes ?? action,
                },
            });
            if (action === "approve") {
                const roleCode = request.organization.organizationType === "MERCHANT"
                    ? "merchant_owner"
                    : request.organization.organizationType === "WORKSHOP"
                        ? "workshop_owner"
                        : "warehouse_owner";
                const ownerMember = await tx.organizationMember.findFirst({
                    where: {
                        organizationId: request.organizationId,
                        memberRole: "owner",
                    },
                    orderBy: { createdAt: "asc" },
                });
                const role = await tx.role.findUnique({ where: { code: roleCode } });
                if (ownerMember && role) {
                    await tx.userRole.upsert({
                        where: {
                            userId_roleId: { userId: ownerMember.userId, roleId: role.id },
                        },
                        update: {},
                        create: { userId: ownerMember.userId, roleId: role.id },
                    });
                }
            }
            await tx.approvalAction.create({
                data: {
                    organizationId: request.organizationId,
                    verificationRequestId: request.id,
                    actedByUserId: userId,
                    actionCode: action,
                    notes: dto.notes,
                },
            });
        });
        await this.eventBus.publish({
            name: eventName,
            aggregateType: "verification_request",
            aggregateId: request.publicId,
            actorUserId: userId,
            payload: {
                organization_id: request.organization.publicId,
                organization_type: request.organization.organizationType,
                organization_status: organizationStatus,
                request_status: requestStatus,
                notes: dto.notes ?? null,
                notification_channel: dto.notificationChannel ?? "BOTH",
            },
        });
        await this.notifyOwnerByReviewResult({
            organizationId: request.organizationId,
            organizationName: request.organization.displayName,
            organizationType: request.organization.organizationType,
            status: requestStatus,
            notes: dto.notes,
            notificationChannel: dto.notificationChannel ?? "BOTH",
        });
        await this.audit.write({
            actorUserId: userId,
            action: `verification.request.${action}`,
            entityType: "verification_request",
            entityId: request.publicId,
            metadata: {
                organization_id: request.organization.publicId,
                organization_type: request.organization.organizationType,
                request_status: requestStatus,
                organization_status: organizationStatus,
            },
        });
        return {
            success: true,
            message: "membership.review_action_completed",
            data: {
                verification_request_id: request.publicId,
                request_status: requestStatus,
                organization_status: organizationStatus,
                is_verified: isVerified,
            },
        };
    }
};
exports.OrganizationsService = OrganizationsService;
exports.OrganizationsService = OrganizationsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        audit_service_1.AuditService,
        notifications_service_1.NotificationsService,
        event_bus_service_1.EventBusService])
], OrganizationsService);
