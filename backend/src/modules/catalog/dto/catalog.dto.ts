import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsNumber, IsObject, IsOptional, IsString, Min, ValidateNested } from 'class-validator';

export class CreateCategoryDto {
  @ApiProperty({ example: 'فلاتر' })
  @IsString()
  nameAr!: string;
  @IsOptional() @IsString() nameEn?: string;
  @ApiProperty({ example: 'filters' })
  @IsString()
  slug!: string;
  @IsOptional() @Type(() => Number) @IsInt() parentId?: number;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() iconUrl?: string;
  @IsOptional() @Type(() => Number) @IsInt() sortOrder?: number;
}

export class CreatePartBrandDto {
  @ApiProperty({ example: 'ACDelco' })
  @IsString()
  nameAr!: string;
  @IsOptional() @IsString() nameEn?: string;
  @ApiProperty({ example: 'acdelco' })
  @IsString()
  slug!: string;
  @IsOptional() @IsString() countryCode?: string;
  @IsOptional() @IsString() logoUrl?: string;
}

export class CreateProductDto {
  @Type(() => Number) @IsInt() categoryId!: number;
  @IsOptional() @Type(() => Number) @IsInt() partBrandId?: number;
  @IsString() nameAr!: string;
  @IsOptional() @IsString() nameEn?: string;
  @IsString() slug!: string;
  @IsOptional() @IsString() sku?: string;
  @IsOptional() @IsString() oemNumber?: string;
  @IsOptional() @IsString() aftermarketCode?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsObject() specifications?: Record<string, unknown>;
  @IsOptional() @Type(() => Boolean) @IsBoolean() isUniversal?: boolean;

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => CreateProductMediaInputDto)
  media?: CreateProductMediaInputDto[];

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => CreateProductCompatibilityInputDto)
  compatibilities?: CreateProductCompatibilityInputDto[];

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => CreateProductSpecDto)
  specs?: CreateProductSpecDto[];
}

export class AddProductMediaDto {
  @IsString() mediaUrl!: string;
  @IsOptional() @IsString() mediaType?: string;
  @IsOptional() @IsString() altText?: string;
  @IsOptional() @Type(() => Number) @IsInt() sortOrder?: number;
}

export class AddProductCompatibilityDto {
  @Type(() => Number) @IsInt() makeId!: number;
  @IsOptional() @Type(() => Number) @IsInt() modelId?: number;
  @IsOptional() @Type(() => Number) @IsInt() variantId?: number;
  @IsOptional() @Type(() => Number) @IsInt() yearFrom?: number;
  @IsOptional() @Type(() => Number) @IsInt() yearTo?: number;
  @IsOptional() @IsString() engineCode?: string;
  @IsOptional() @IsString() notes?: string;
}

export class ProductQueryDto {
  @IsOptional() @IsString() q?: string;
  @IsOptional() @IsString() partNumber?: string;
  @IsOptional() @Type(() => Number) @IsInt() categoryId?: number;
  @IsOptional() @Type(() => Number) @IsInt() partBrandId?: number;
  @IsOptional() @Type(() => Number) @IsInt() makeId?: number;
  @IsOptional() @Type(() => Number) @IsInt() modelId?: number;
  @IsOptional() @Type(() => Number) @IsInt() year?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) limit?: number;
}


export class CreateProductSpecDto {
  @IsString() specKey!: string;
  @IsString() specValue!: string;
  @IsOptional() @Type(() => Number) @IsInt() sortOrder?: number;
}

export class CreateProductMediaInputDto extends AddProductMediaDto {}
export class CreateProductCompatibilityInputDto extends AddProductCompatibilityDto {}
