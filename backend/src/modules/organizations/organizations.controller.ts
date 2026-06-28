import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CreateBankAccountDto } from "./dto/create-bank-account.dto";
import { CreateBranchDto } from "./dto/create-branch.dto";
import { CreateOrganizationDto } from "./dto/create-organization.dto";
import { AddVerificationDocumentDto } from "./dto/add-verification-document.dto";
import { SubmitVerificationRequestDto } from "./dto/submit-verification-request.dto";
import { UpsertBusinessHoursDto } from "./dto/upsert-business-hours.dto";
import { UpsertMerchantProfileDto } from "./dto/upsert-merchant-profile.dto";
import { UpsertWorkshopProfileDto } from "./dto/upsert-workshop-profile.dto";
import { UpdateOrganizationDto } from "./dto/update-organization.dto";
import { UpdateBranchDto } from "./dto/update-branch.dto";
import { SetBranchClosureDto } from "./dto/set-branch-closure.dto";
import { OrganizationsService } from "./organizations.service";
import { AdminReviewVerificationDto } from "./dto/admin-review-verification.dto";

@ApiTags("Organizations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class OrganizationsController {
  constructor(private readonly organizationsService: OrganizationsService) {}

  @Post("organizations")
  create(
    @CurrentUser() user: { sub: number },
    @Body() dto: CreateOrganizationDto,
  ) {
    return this.organizationsService.create(user.sub, dto);
  }

  @Get("organizations/me")
  mine(@CurrentUser() user: { sub: number }) {
    return this.organizationsService.mine(user.sub);
  }

  @Get("organizations/:id")
  detail(@CurrentUser() user: { sub: number }, @Param("id") id: string) {
    return this.organizationsService.detailForMember(user.sub, id);
  }

  @Get("organizations/:id/audit-logs")
  auditLogs(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Query("limit") limit?: string,
    @Query("take") take?: string,
    @Query("skip") skip?: string,
    @Query("action") action?: string,
  ) {
    return this.organizationsService.listAuditLogs(user.sub, id, {
      take: Number(take || limit || 50),
      skip: Number(skip || 0),
      action,
    });
  }

  @Patch("organizations/:id")
  update(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: UpdateOrganizationDto,
  ) {
    return this.organizationsService.update(user.sub, id, dto);
  }

  @Post("organizations/:id/branches")
  createBranch(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: CreateBranchDto,
  ) {
    return this.organizationsService.createBranch(user.sub, id, dto);
  }

  @Get("organizations/:id/branches")
  listBranches(@CurrentUser() user: { sub: number }, @Param("id") id: string) {
    return this.organizationsService.listBranches(user.sub, id);
  }

  @Patch("organizations/:id/branches/:branchId")
  updateBranch(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Param("branchId") branchId: string,
    @Body() dto: UpdateBranchDto,
  ) {
    return this.organizationsService.updateBranch(user.sub, id, branchId, dto);
  }

  @Patch("organizations/:id/branches/:branchId/closure")
  setBranchClosure(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Param("branchId") branchId: string,
    @Body() dto: SetBranchClosureDto,
  ) {
    return this.organizationsService.setBranchClosure(
      user.sub,
      id,
      branchId,
      dto,
    );
  }

  @Put("organizations/:id/branches/:branchId/business-hours")
  upsertBranchBusinessHours(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Param("branchId") branchId: string,
    @Body() dto: UpsertBusinessHoursDto,
  ) {
    return this.organizationsService.upsertBranchBusinessHours(
      user.sub,
      id,
      branchId,
      dto,
    );
  }

  @Get("organizations/:id/business-hours")
  getBusinessHours(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
  ) {
    return this.organizationsService.getBusinessHours(user.sub, id);
  }

  @Put("organizations/:id/business-hours")
  upsertBusinessHours(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: UpsertBusinessHoursDto,
  ) {
    return this.organizationsService.upsertBusinessHours(user.sub, id, dto);
  }

  @Post("organizations/:id/merchant-profile")
  upsertMerchantProfile(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: UpsertMerchantProfileDto,
  ) {
    return this.organizationsService.upsertMerchantProfile(user.sub, id, dto);
  }

  @Post("organizations/:id/workshop-profile")
  upsertWorkshopProfile(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: UpsertWorkshopProfileDto,
  ) {
    return this.organizationsService.upsertWorkshopProfile(user.sub, id, dto);
  }

  @Get("organizations/:id/bank-accounts")
  listBankAccounts(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
  ) {
    return this.organizationsService.listBankAccounts(user.sub, id);
  }

  @Post("organizations/:id/bank-accounts")
  createBankAccount(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: CreateBankAccountDto,
  ) {
    return this.organizationsService.createBankAccount(user.sub, id, dto);
  }

  @Post("organizations/:id/verification-requests")
  submitVerificationRequest(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: SubmitVerificationRequestDto,
  ) {
    return this.organizationsService.submitVerificationRequest(
      user.sub,
      id,
      dto,
    );
  }

  @Get("verification-requests/:id")
  getVerificationRequest(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
  ) {
    return this.organizationsService.getVerificationRequest(user.sub, id);
  }

  @Post("verification-requests/:id/documents")
  addVerificationDocument(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: AddVerificationDocumentDto,
  ) {
    return this.organizationsService.addVerificationDocument(user.sub, id, dto);
  }

  @Get("admin/verifications")
  listForAdmin(
    @CurrentUser() user: { sub: number },
    @Query("status") status?: string,
  ) {
    return this.organizationsService.listVerificationRequestsForAdmin(
      user.sub,
      status,
    );
  }

  @Get("admin/verifications/:id")
  detailForAdmin(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
  ) {
    return this.organizationsService.getVerificationRequestForAdmin(
      user.sub,
      id,
    );
  }

  @Post("admin/verifications/:id/approve")
  approve(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: AdminReviewVerificationDto,
  ) {
    return this.organizationsService.reviewVerificationRequest(
      user.sub,
      id,
      "approve",
      dto,
    );
  }

  @Post("admin/verifications/:id/reject")
  reject(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: AdminReviewVerificationDto,
  ) {
    return this.organizationsService.reviewVerificationRequest(
      user.sub,
      id,
      "reject",
      dto,
    );
  }

  @Post("admin/verifications/:id/require-documents")
  requireDocuments(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: AdminReviewVerificationDto,
  ) {
    return this.organizationsService.reviewVerificationRequest(
      user.sub,
      id,
      "require_documents",
      dto,
    );
  }

  @Post("admin/verifications/:id/suspend")
  suspend(
    @CurrentUser() user: { sub: number },
    @Param("id") id: string,
    @Body() dto: AdminReviewVerificationDto,
  ) {
    return this.organizationsService.reviewVerificationRequest(
      user.sub,
      id,
      "suspend",
      dto,
    );
  }
}
