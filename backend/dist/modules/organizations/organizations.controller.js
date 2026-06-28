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
exports.OrganizationsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const current_user_decorator_1 = require("../../common/decorators/current-user.decorator");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const create_bank_account_dto_1 = require("./dto/create-bank-account.dto");
const create_branch_dto_1 = require("./dto/create-branch.dto");
const create_organization_dto_1 = require("./dto/create-organization.dto");
const add_verification_document_dto_1 = require("./dto/add-verification-document.dto");
const submit_verification_request_dto_1 = require("./dto/submit-verification-request.dto");
const upsert_business_hours_dto_1 = require("./dto/upsert-business-hours.dto");
const upsert_merchant_profile_dto_1 = require("./dto/upsert-merchant-profile.dto");
const upsert_workshop_profile_dto_1 = require("./dto/upsert-workshop-profile.dto");
const update_organization_dto_1 = require("./dto/update-organization.dto");
const update_branch_dto_1 = require("./dto/update-branch.dto");
const set_branch_closure_dto_1 = require("./dto/set-branch-closure.dto");
const organizations_service_1 = require("./organizations.service");
const admin_review_verification_dto_1 = require("./dto/admin-review-verification.dto");
let OrganizationsController = class OrganizationsController {
    constructor(organizationsService) {
        this.organizationsService = organizationsService;
    }
    create(user, dto) {
        return this.organizationsService.create(user.sub, dto);
    }
    mine(user) {
        return this.organizationsService.mine(user.sub);
    }
    detail(user, id) {
        return this.organizationsService.detailForMember(user.sub, id);
    }
    auditLogs(user, id, limit, take, skip, action) {
        return this.organizationsService.listAuditLogs(user.sub, id, {
            take: Number(take || limit || 50),
            skip: Number(skip || 0),
            action,
        });
    }
    update(user, id, dto) {
        return this.organizationsService.update(user.sub, id, dto);
    }
    createBranch(user, id, dto) {
        return this.organizationsService.createBranch(user.sub, id, dto);
    }
    listBranches(user, id) {
        return this.organizationsService.listBranches(user.sub, id);
    }
    updateBranch(user, id, branchId, dto) {
        return this.organizationsService.updateBranch(user.sub, id, branchId, dto);
    }
    setBranchClosure(user, id, branchId, dto) {
        return this.organizationsService.setBranchClosure(user.sub, id, branchId, dto);
    }
    upsertBranchBusinessHours(user, id, branchId, dto) {
        return this.organizationsService.upsertBranchBusinessHours(user.sub, id, branchId, dto);
    }
    getBusinessHours(user, id) {
        return this.organizationsService.getBusinessHours(user.sub, id);
    }
    upsertBusinessHours(user, id, dto) {
        return this.organizationsService.upsertBusinessHours(user.sub, id, dto);
    }
    upsertMerchantProfile(user, id, dto) {
        return this.organizationsService.upsertMerchantProfile(user.sub, id, dto);
    }
    upsertWorkshopProfile(user, id, dto) {
        return this.organizationsService.upsertWorkshopProfile(user.sub, id, dto);
    }
    listBankAccounts(user, id) {
        return this.organizationsService.listBankAccounts(user.sub, id);
    }
    createBankAccount(user, id, dto) {
        return this.organizationsService.createBankAccount(user.sub, id, dto);
    }
    submitVerificationRequest(user, id, dto) {
        return this.organizationsService.submitVerificationRequest(user.sub, id, dto);
    }
    getVerificationRequest(user, id) {
        return this.organizationsService.getVerificationRequest(user.sub, id);
    }
    addVerificationDocument(user, id, dto) {
        return this.organizationsService.addVerificationDocument(user.sub, id, dto);
    }
    listForAdmin(user, status) {
        return this.organizationsService.listVerificationRequestsForAdmin(user.sub, status);
    }
    detailForAdmin(user, id) {
        return this.organizationsService.getVerificationRequestForAdmin(user.sub, id);
    }
    approve(user, id, dto) {
        return this.organizationsService.reviewVerificationRequest(user.sub, id, "approve", dto);
    }
    reject(user, id, dto) {
        return this.organizationsService.reviewVerificationRequest(user.sub, id, "reject", dto);
    }
    requireDocuments(user, id, dto) {
        return this.organizationsService.reviewVerificationRequest(user.sub, id, "require_documents", dto);
    }
    suspend(user, id, dto) {
        return this.organizationsService.reviewVerificationRequest(user.sub, id, "suspend", dto);
    }
};
exports.OrganizationsController = OrganizationsController;
__decorate([
    (0, common_1.Post)("organizations"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_organization_dto_1.CreateOrganizationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)("organizations/me"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "mine", null);
__decorate([
    (0, common_1.Get)("organizations/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "detail", null);
__decorate([
    (0, common_1.Get)("organizations/:id/audit-logs"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Query)("limit")),
    __param(3, (0, common_1.Query)("take")),
    __param(4, (0, common_1.Query)("skip")),
    __param(5, (0, common_1.Query)("action")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "auditLogs", null);
__decorate([
    (0, common_1.Patch)("organizations/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, update_organization_dto_1.UpdateOrganizationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "update", null);
__decorate([
    (0, common_1.Post)("organizations/:id/branches"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, create_branch_dto_1.CreateBranchDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "createBranch", null);
__decorate([
    (0, common_1.Get)("organizations/:id/branches"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "listBranches", null);
__decorate([
    (0, common_1.Patch)("organizations/:id/branches/:branchId"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Param)("branchId")),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, update_branch_dto_1.UpdateBranchDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "updateBranch", null);
__decorate([
    (0, common_1.Patch)("organizations/:id/branches/:branchId/closure"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Param)("branchId")),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, set_branch_closure_dto_1.SetBranchClosureDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "setBranchClosure", null);
__decorate([
    (0, common_1.Put)("organizations/:id/branches/:branchId/business-hours"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Param)("branchId")),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, upsert_business_hours_dto_1.UpsertBusinessHoursDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "upsertBranchBusinessHours", null);
__decorate([
    (0, common_1.Get)("organizations/:id/business-hours"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "getBusinessHours", null);
__decorate([
    (0, common_1.Put)("organizations/:id/business-hours"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, upsert_business_hours_dto_1.UpsertBusinessHoursDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "upsertBusinessHours", null);
__decorate([
    (0, common_1.Post)("organizations/:id/merchant-profile"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, upsert_merchant_profile_dto_1.UpsertMerchantProfileDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "upsertMerchantProfile", null);
__decorate([
    (0, common_1.Post)("organizations/:id/workshop-profile"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, upsert_workshop_profile_dto_1.UpsertWorkshopProfileDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "upsertWorkshopProfile", null);
__decorate([
    (0, common_1.Get)("organizations/:id/bank-accounts"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "listBankAccounts", null);
__decorate([
    (0, common_1.Post)("organizations/:id/bank-accounts"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, create_bank_account_dto_1.CreateBankAccountDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "createBankAccount", null);
__decorate([
    (0, common_1.Post)("organizations/:id/verification-requests"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, submit_verification_request_dto_1.SubmitVerificationRequestDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "submitVerificationRequest", null);
__decorate([
    (0, common_1.Get)("verification-requests/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "getVerificationRequest", null);
__decorate([
    (0, common_1.Post)("verification-requests/:id/documents"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, add_verification_document_dto_1.AddVerificationDocumentDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "addVerificationDocument", null);
__decorate([
    (0, common_1.Get)("admin/verifications"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)("status")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "listForAdmin", null);
__decorate([
    (0, common_1.Get)("admin/verifications/:id"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "detailForAdmin", null);
__decorate([
    (0, common_1.Post)("admin/verifications/:id/approve"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, admin_review_verification_dto_1.AdminReviewVerificationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "approve", null);
__decorate([
    (0, common_1.Post)("admin/verifications/:id/reject"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, admin_review_verification_dto_1.AdminReviewVerificationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "reject", null);
__decorate([
    (0, common_1.Post)("admin/verifications/:id/require-documents"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, admin_review_verification_dto_1.AdminReviewVerificationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "requireDocuments", null);
__decorate([
    (0, common_1.Post)("admin/verifications/:id/suspend"),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)("id")),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, admin_review_verification_dto_1.AdminReviewVerificationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "suspend", null);
exports.OrganizationsController = OrganizationsController = __decorate([
    (0, swagger_1.ApiTags)("Organizations"),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [organizations_service_1.OrganizationsService])
], OrganizationsController);
