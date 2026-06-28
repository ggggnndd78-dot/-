import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export enum DtoWorkshopServiceStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  ARCHIVED = 'ARCHIVED',
}

export enum DtoWorkshopBookingStatus {
  REQUESTED = 'REQUESTED',
  CONFIRMED = 'CONFIRMED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  REJECTED = 'REJECTED',
}

export enum DtoServiceOrderStatus {
  OPEN = 'OPEN',
  DIAGNOSIS_IN_PROGRESS = 'DIAGNOSIS_IN_PROGRESS',
  WAITING_CUSTOMER_APPROVAL = 'WAITING_CUSTOMER_APPROVAL',
  WAITING_PARTS = 'WAITING_PARTS',
  IN_REPAIR = 'IN_REPAIR',
  READY_FOR_DELIVERY = 'READY_FOR_DELIVERY',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum DtoServiceOrderPriority {
  LOW = 'LOW',
  NORMAL = 'NORMAL',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export enum DtoBookingSlotStatus {
  AVAILABLE = 'AVAILABLE',
  FULL = 'FULL',
  CLOSED = 'CLOSED',
}

export class WorkshopServicesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cityId?: number;

  @IsOptional()
  @IsString()
  categoryCode?: string;

  @IsOptional()
  @IsString()
  q?: string;
}

export class CreateWorkshopServiceDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  organizationId?: number;

  @IsOptional()
  @IsString()
  organizationPublicId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  branchId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  serviceId?: number;

  @IsString()
  @Length(2, 180)
  nameAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 180)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @Length(0, 60)
  categoryCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(5)
  estimatedDurationMinutes?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  basePrice?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsBoolean()
  requiresDiagnosis?: boolean;

  @IsOptional()
  @IsBoolean()
  supportsMobileService?: boolean;
}

export class UpdateWorkshopServiceDto {
  @IsOptional()
  @IsString()
  @Length(2, 180)
  nameAr?: string;

  @IsOptional()
  @IsString()
  @Length(0, 180)
  nameEn?: string;


  @IsOptional()
  @Type(() => Number)
  @IsInt()
  serviceId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 60)
  categoryCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(5)
  estimatedDurationMinutes?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  basePrice?: number;

  @IsOptional()
  @IsBoolean()
  requiresDiagnosis?: boolean;

  @IsOptional()
  @IsBoolean()
  supportsMobileService?: boolean;
}

export class UpdateWorkshopServiceStatusDto {
  @IsEnum(DtoWorkshopServiceStatus)
  status!: DtoWorkshopServiceStatus;
}

export class CreateWorkshopTechnicianDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  organizationId?: number;

  @IsOptional()
  @IsString()
  organizationPublicId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  branchId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  userId?: number;

  @IsString()
  @Length(2, 140)
  fullName!: string;

  @IsOptional()
  @IsString()
  @Length(0, 20)
  phone?: string;

  @IsOptional()
  specializations?: string[];

  @IsOptional()
  @IsInt()
  @Min(1)
  maxJobsPerDay?: number;
}

export class CreateWorkshopBookingDto {
  @Type(() => Number)
  @IsInt()
  workshopServiceId!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  bookingSlotId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  customerVehicleId?: number;

  @IsDateString()
  preferredDate!: string;

  @IsOptional()
  @IsString()
  @Length(0, 60)
  preferredTimeWindow?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  customerProblemDescription?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  customerNote?: string;
}

export class UpdateWorkshopBookingStatusDto {
  @IsEnum(DtoWorkshopBookingStatus)
  status!: DtoWorkshopBookingStatus;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  technicianId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  estimatedAmount?: number;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class CancelWorkshopBookingDto {
  @IsOptional()
  @IsString()
  @Length(0, 500)
  reason?: string;
}


export class BookingSlotsQueryDto {
  @Type(() => Number)
  @IsInt()
  workshopServiceId!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  branchId?: number;

  @IsDateString()
  date!: string;
}

export class CreateBookingSlotDto {
  @Type(() => Number)
  @IsInt()
  workshopServiceId!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  branchId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  technicianId?: number;

  @IsDateString()
  date!: string;

  @IsString()
  @Length(4, 5)
  startTime!: string;

  @IsString()
  @Length(4, 5)
  endTime!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  capacity?: number;

  @IsOptional()
  @IsEnum(DtoBookingSlotStatus)
  status?: DtoBookingSlotStatus;
}

export class SubmitWorkshopRatingDto {
  @Type(() => Number)
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
  @MaxLength(2000)
  body?: string;
}

export class CreateServiceOrderFromBookingDto {
  @IsOptional()
  @IsEnum(DtoServiceOrderPriority)
  priority?: DtoServiceOrderPriority;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  technicianId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  estimatedAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  problemDescription?: string;
}

export class UpdateServiceOrderStatusDto {
  @IsEnum(DtoServiceOrderStatus)
  status!: DtoServiceOrderStatus;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  finalAmount?: number;
}

export class CreateDiagnosticReportDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  technicianId?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  symptoms?: string;

  @IsString()
  @Length(3, 4000)
  findings!: string;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  recommendedActions?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  estimatedRepairCost?: number;

  @IsOptional()
  @IsBoolean()
  requiresParts?: boolean;
}

export class CreateMaintenanceRecordDto {
  @Type(() => Number)
  @IsInt()
  customerVehicleId!: number;

  @IsString()
  @Length(2, 180)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  mileage?: number;

  @IsOptional()
  @IsDateString()
  serviceDate?: string;

  @IsOptional()
  @IsDateString()
  nextServiceDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  costAmount?: number;
}
