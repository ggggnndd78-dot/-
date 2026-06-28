import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsEnum, IsInt, IsOptional, IsString, Length, Max, Min, ValidateNested } from 'class-validator';

export enum DtoSupportTicketCategory {
  GENERAL = 'GENERAL',
  ORDER = 'ORDER',
  PAYMENT = 'PAYMENT',
  DELIVERY = 'DELIVERY',
  WORKSHOP = 'WORKSHOP',
  MERCHANT = 'MERCHANT',
  TECHNICAL = 'TECHNICAL',
  COMPLAINT = 'COMPLAINT',
}

export enum DtoSupportTicketPriority {
  LOW = 'LOW',
  NORMAL = 'NORMAL',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export enum DtoSupportTicketStatus {
  OPEN = 'OPEN',
  IN_PROGRESS = 'IN_PROGRESS',
  WAITING_SUPPORT = 'WAITING_SUPPORT',
  WAITING_CUSTOMER = 'WAITING_CUSTOMER',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
  ESCALATED = 'ESCALATED',
}

export enum DtoComplaintStatus {
  SUBMITTED = 'SUBMITTED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  INVESTIGATION = 'INVESTIGATION',
  WAITING_CUSTOMER = 'WAITING_CUSTOMER',
  WAITING_PROVIDER = 'WAITING_PROVIDER',
  RESOLVED = 'RESOLVED',
  REJECTED = 'REJECTED',
  CLOSED = 'CLOSED',
}

export enum DtoComplaintSeverity {
  LOW = 'LOW',
  NORMAL = 'NORMAL',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}

export enum DtoReviewStatus {
  PENDING = 'PENDING',
  PUBLISHED = 'PUBLISHED',
  HIDDEN = 'HIDDEN',
  REJECTED = 'REJECTED',
}

export enum DtoSupportContentStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  ARCHIVED = 'ARCHIVED',
}

export enum DtoWhatsappSupportDepartment {
  SALES = 'SALES',
  SUPPORT = 'SUPPORT',
  COMPLAINTS = 'COMPLAINTS',
  TECHNICAL = 'TECHNICAL',
  FINANCE = 'FINANCE',
  GENERAL = 'GENERAL',
}

export class SupportAttachmentDto {
  @IsString()
  @Length(5, 500)
  fileUrl!: string;

  @IsOptional()
  @IsString()
  @Length(0, 255)
  fileName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  fileType?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  fileSizeBytes?: number;
}

export class CreateSupportTicketDto {
  @IsEnum(DtoSupportTicketCategory)
  category!: DtoSupportTicketCategory;

  @IsOptional()
  @IsEnum(DtoSupportTicketPriority)
  priority?: DtoSupportTicketPriority;

  @IsString()
  @Length(3, 180)
  subject!: string;

  @IsString()
  @Length(10, 5000)
  description!: string;

  @IsOptional()
  @IsInt()
  organizationId?: number;

  @IsInt()
  orderId!: number;

  @IsInt()
  serviceOrderId!: number;

  @IsOptional()
  @IsInt()
  paymentId?: number;

  @IsOptional()
  @IsInt()
  shipmentId?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SupportAttachmentDto)
  attachments?: SupportAttachmentDto[];
}

export class AddTicketMessageDto {
  @IsString()
  @Length(2, 5000)
  body!: string;

  @IsOptional()
  @IsBoolean()
  isInternal?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SupportAttachmentDto)
  attachments?: SupportAttachmentDto[];
}

export class UpdateSupportTicketStatusDto {
  @IsEnum(DtoSupportTicketStatus)
  status!: DtoSupportTicketStatus;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class AssignSupportTicketDto {
  @IsInt()
  assignedUserId!: number;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class CreateComplaintDto {
  @IsString()
  @Length(3, 180)
  subject!: string;

  @IsString()
  @Length(10, 5000)
  description!: string;

  @IsOptional()
  @IsEnum(DtoComplaintSeverity)
  severity?: DtoComplaintSeverity;

  @IsOptional()
  @IsInt()
  organizationId?: number;

  @IsInt()
  orderId!: number;

  @IsInt()
  serviceOrderId!: number;

  @IsOptional()
  @IsInt()
  paymentId?: number;

  @IsOptional()
  @IsInt()
  shipmentId?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SupportAttachmentDto)
  attachments?: SupportAttachmentDto[];
}

export class UpdateComplaintStatusDto {
  @IsEnum(DtoComplaintStatus)
  status!: DtoComplaintStatus;

  @IsOptional()
  @IsString()
  @Length(0, 1000)
  resolutionNote?: string;
}

export class UpsertHelpCenterCategoryDto {
  @IsString()
  @Length(2, 80)
  code!: string;

  @IsString()
  @Length(2, 160)
  titleAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  descriptionAr?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  descriptionEn?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  icon?: string;

  @IsOptional()
  @IsEnum(DtoSupportContentStatus)
  status?: DtoSupportContentStatus;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class UpsertHelpCenterArticleDto {
  @IsOptional()
  @IsInt()
  categoryId?: number;

  @IsString()
  @Length(3, 180)
  slug!: string;

  @IsString()
  @Length(3, 220)
  titleAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 220)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  summaryAr?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  summaryEn?: string;

  @IsString()
  @Length(10, 20000)
  bodyAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 20000)
  bodyEn?: string;

  @IsOptional()
  @IsEnum(DtoSupportContentStatus)
  status?: DtoSupportContentStatus;

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class UpsertFaqDto {
  @IsOptional()
  @IsInt()
  categoryId?: number;

  @IsString()
  @Length(3, 300)
  questionAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 300)
  questionEn?: string;

  @IsString()
  @Length(3, 10000)
  answerAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 10000)
  answerEn?: string;

  @IsOptional()
  @IsEnum(DtoSupportContentStatus)
  status?: DtoSupportContentStatus;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class UpsertWhatsappSupportLinkDto {
  @IsEnum(DtoWhatsappSupportDepartment)
  department!: DtoWhatsappSupportDepartment;

  @IsString()
  @Length(2, 160)
  titleAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  titleEn?: string;

  @IsString()
  @Length(8, 30)
  phoneE164!: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  messageTemplate?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class CreateProductReviewDto {
  @IsInt()
  productId!: number;

  @IsOptional()
  @IsInt()
  orderId?: number;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(0, 3000)
  body?: string;
}

export class CreateMerchantReviewDto {
  @IsInt()
  organizationId!: number;

  @IsOptional()
  @IsInt()
  orderId?: number;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(0, 3000)
  body?: string;
}

export class CreateWorkshopReviewDto {
  @IsInt()
  organizationId!: number;

  @IsInt()
  serviceOrderId!: number;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(0, 3000)
  body?: string;
}

export class ModerateReviewDto {
  @IsEnum(DtoReviewStatus)
  status!: DtoReviewStatus;
}
