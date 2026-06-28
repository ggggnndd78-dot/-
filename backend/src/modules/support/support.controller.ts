import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
  AddTicketMessageDto,
  AssignSupportTicketDto,
  CreateComplaintDto,
  CreateMerchantReviewDto,
  CreateProductReviewDto,
  CreateSupportTicketDto,
  CreateWorkshopReviewDto,
  ModerateReviewDto,
  UpdateComplaintStatusDto,
  UpdateSupportTicketStatusDto,
  UpsertFaqDto,
  UpsertHelpCenterArticleDto,
  UpsertHelpCenterCategoryDto,
  UpsertWhatsappSupportLinkDto,
} from './dto/support.dto';
import { SupportService } from './support.service';

@ApiTags('Support, Complaints & Reviews')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('support')
export class SupportController {
  constructor(private readonly support: SupportService) {}

  @Post('tickets')
  createTicket(@CurrentUser() user: any, @Body() dto: CreateSupportTicketDto) {
    return this.support.createTicket(user.sub, dto);
  }

  @Get('tickets/my')
  myTickets(@CurrentUser() user: any) {
    return this.support.myTickets(user.sub);
  }

  @Get('tickets/manage')
  manageTickets(@CurrentUser() user: any, @Query('status') status?: string) {
    return this.support.manageTickets(user.sub, status);
  }

  @Get('tickets/:id')
  ticketDetails(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.support.ticketDetails(user.sub, id);
  }

  @Post('tickets/:id/messages')
  addMessage(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: AddTicketMessageDto) {
    return this.support.addTicketMessage(user.sub, id, dto);
  }

  @Patch('tickets/:id/assign')
  assignTicket(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: AssignSupportTicketDto) {
    return this.support.assignTicket(user.sub, id, dto);
  }

  @Patch('tickets/:id/status')
  updateTicketStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateSupportTicketStatusDto) {
    return this.support.updateTicketStatus(user.sub, id, dto);
  }

  @Patch('tickets/:id/reopen')
  reopenTicket(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.support.reopenTicket(user.sub, id);
  }

  @Post('complaints')
  createComplaint(@CurrentUser() user: any, @Body() dto: CreateComplaintDto) {
    return this.support.createComplaint(user.sub, dto);
  }

  @Get('complaints/my')
  myComplaints(@CurrentUser() user: any) {
    return this.support.myComplaints(user.sub);
  }

  @Get('complaints/manage')
  manageComplaints(@CurrentUser() user: any, @Query('status') status?: string) {
    return this.support.manageComplaints(user.sub, status);
  }

  @Get('complaints/:id')
  complaintDetails(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number) {
    return this.support.complaintDetails(user.sub, id);
  }

  @Patch('complaints/:id/status')
  updateComplaintStatus(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateComplaintStatusDto) {
    return this.support.updateComplaintStatus(user.sub, id, dto);
  }

  @Public()
  @Get('help/categories')
  helpCategories() {
    return this.support.listHelpCategories(true);
  }

  @Get('help/categories/manage')
  manageHelpCategories(@CurrentUser() user: any) {
    return this.support.manageHelpCategories(user.sub);
  }

  @Post('help/categories')
  createHelpCategory(@CurrentUser() user: any, @Body() dto: UpsertHelpCenterCategoryDto) {
    return this.support.upsertHelpCategory(user.sub, dto);
  }

  @Patch('help/categories/:id')
  updateHelpCategory(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpsertHelpCenterCategoryDto) {
    return this.support.upsertHelpCategory(user.sub, dto, id);
  }

  @Public()
  @Get('help/articles')
  helpArticles(@Query('q') q?: string, @Query('categoryId') categoryId?: string) {
    return this.support.listHelpArticles({ q, categoryId: categoryId ? Number(categoryId) : undefined, publicOnly: true });
  }

  @Get('help/articles/manage')
  manageHelpArticles(@CurrentUser() user: any, @Query('q') q?: string, @Query('categoryId') categoryId?: string) {
    return this.support.manageHelpArticles(user.sub, { q, categoryId: categoryId ? Number(categoryId) : undefined });
  }

  @Public()
  @Get('help/articles/:slug')
  helpArticleDetails(@Param('slug') slug: string) {
    return this.support.helpArticleDetails(slug, true);
  }

  @Post('help/articles')
  createHelpArticle(@CurrentUser() user: any, @Body() dto: UpsertHelpCenterArticleDto) {
    return this.support.upsertHelpArticle(user.sub, dto);
  }

  @Patch('help/articles/:id')
  updateHelpArticle(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpsertHelpCenterArticleDto) {
    return this.support.upsertHelpArticle(user.sub, dto, id);
  }

  @Public()
  @Get('faqs')
  faqs(@Query('q') q?: string, @Query('categoryId') categoryId?: string) {
    return this.support.listFaqs({ q, categoryId: categoryId ? Number(categoryId) : undefined, publicOnly: true });
  }

  @Get('faqs/manage')
  manageFaqs(@CurrentUser() user: any, @Query('q') q?: string, @Query('categoryId') categoryId?: string) {
    return this.support.manageFaqs(user.sub, { q, categoryId: categoryId ? Number(categoryId) : undefined });
  }

  @Post('faqs')
  createFaq(@CurrentUser() user: any, @Body() dto: UpsertFaqDto) {
    return this.support.upsertFaq(user.sub, dto);
  }

  @Patch('faqs/:id')
  updateFaq(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpsertFaqDto) {
    return this.support.upsertFaq(user.sub, dto, id);
  }

  @Public()
  @Get('whatsapp-links')
  whatsappLinks() {
    return this.support.listWhatsappLinks(true);
  }

  @Get('whatsapp-links/manage')
  manageWhatsappLinks(@CurrentUser() user: any) {
    return this.support.manageWhatsappLinks(user.sub);
  }

  @Post('whatsapp-links')
  createWhatsappLink(@CurrentUser() user: any, @Body() dto: UpsertWhatsappSupportLinkDto) {
    return this.support.upsertWhatsappLink(user.sub, dto);
  }

  @Patch('whatsapp-links/:id')
  updateWhatsappLink(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpsertWhatsappSupportLinkDto) {
    return this.support.upsertWhatsappLink(user.sub, dto, id);
  }

  @Post('reviews/products')
  createProductReview(@CurrentUser() user: any, @Body() dto: CreateProductReviewDto) {
    return this.support.createProductReview(user.sub, dto);
  }

  @Post('reviews/merchants')
  createMerchantReview(@CurrentUser() user: any, @Body() dto: CreateMerchantReviewDto) {
    return this.support.createMerchantReview(user.sub, dto);
  }

  @Post('reviews/workshops')
  createWorkshopReview(@CurrentUser() user: any, @Body() dto: CreateWorkshopReviewDto) {
    return this.support.createWorkshopReview(user.sub, dto);
  }

  @Get('reviews/my')
  myReviews(@CurrentUser() user: any) {
    return this.support.myReviews(user.sub);
  }

  @Public()
  @Get('reviews/products/:productId')
  productReviews(@Param('productId', ParseIntPipe) productId: number) {
    return this.support.productReviews(productId);
  }

  @Public()
  @Get('reviews/merchants/:organizationId')
  merchantReviews(@Param('organizationId', ParseIntPipe) organizationId: number) {
    return this.support.merchantReviews(organizationId);
  }

  @Public()
  @Get('reviews/workshops/:organizationId')
  workshopReviews(@Param('organizationId', ParseIntPipe) organizationId: number) {
    return this.support.workshopReviews(organizationId);
  }

  @Patch('reviews/:type/:id/status')
  moderateReview(@CurrentUser() user: any, @Param('type') type: string, @Param('id', ParseIntPipe) id: number, @Body() dto: ModerateReviewDto) {
    return this.support.moderateReview(user.sub, type, id, dto);
  }
}
