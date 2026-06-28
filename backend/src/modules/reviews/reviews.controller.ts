import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import {
  CreateMerchantReviewDto,
  CreateProductReviewDto,
  CreateServiceReviewDto,
  CreateWorkshopReviewDto,
  ModerateReviewDto,
  ReplyToReviewDto,
  ReportReviewDto,
} from './dto/reviews.dto';
import { ReviewsService } from './reviews.service';

@ApiTags('Reviews & Reputation')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Post('products')
  @RequirePermissions('reviews.create')
  createProduct(@CurrentUser() user: any, @Body() dto: CreateProductReviewDto) {
    return this.reviews.createProductReview(user.sub, dto);
  }

  @Post('merchants')
  @RequirePermissions('reviews.create')
  createMerchant(@CurrentUser() user: any, @Body() dto: CreateMerchantReviewDto) {
    return this.reviews.createMerchantReview(user.sub, dto);
  }

  @Post('workshops')
  @RequirePermissions('reviews.create')
  createWorkshop(@CurrentUser() user: any, @Body() dto: CreateWorkshopReviewDto) {
    return this.reviews.createWorkshopReview(user.sub, dto);
  }

  @Post('services')
  @RequirePermissions('reviews.create')
  createService(@CurrentUser() user: any, @Body() dto: CreateServiceReviewDto) {
    return this.reviews.createServiceReview(user.sub, dto);
  }

  @Get('my')
  @RequirePermissions('reviews.create')
  my(@CurrentUser() user: any) {
    return this.reviews.myReviews(user.sub);
  }

  @Post('reply')
  @RequirePermissions('reviews.reply.manage')
  reply(@CurrentUser() user: any, @Body() dto: ReplyToReviewDto) {
    return this.reviews.replyToReview(user.sub, dto);
  }

  @Post('report')
  @RequirePermissions('reviews.create')
  report(@CurrentUser() user: any, @Body() dto: ReportReviewDto) {
    return this.reviews.reportReview(user.sub, dto);
  }

  @Patch('moderation')
  @RequirePermissions('reviews.moderate')
  moderate(@CurrentUser() user: any, @Body() dto: ModerateReviewDto) {
    return this.reviews.moderateReview(user.sub, dto);
  }

  @Get('admin')
  @RequirePermissions('reviews.moderate')
  adminList(@Query('targetType') targetType?: string, @Query('status') status?: string) {
    return this.reviews.adminList({ targetType, status });
  }

  @Public()
  @Get('products/:productId')
  productReviews(@Param('productId', ParseIntPipe) productId: number) {
    return this.reviews.publicReviews('PRODUCT', productId);
  }

  @Public()
  @Get('merchants/:organizationId')
  merchantReviews(@Param('organizationId', ParseIntPipe) organizationId: number) {
    return this.reviews.publicReviews('MERCHANT', organizationId);
  }

  @Public()
  @Get('workshops/:organizationId')
  workshopReviews(@Param('organizationId', ParseIntPipe) organizationId: number) {
    return this.reviews.publicReviews('WORKSHOP', organizationId);
  }

  @Public()
  @Get('services/:workshopServiceId')
  serviceReviews(@Param('workshopServiceId', ParseIntPipe) workshopServiceId: number) {
    return this.reviews.publicReviews('SERVICE', workshopServiceId);
  }

  @Public()
  @Get('reputation/:targetType/:targetId')
  reputation(@Param('targetType') targetType: string, @Param('targetId', ParseIntPipe) targetId: number) {
    return this.reviews.reputation(targetType, targetId);
  }
}
