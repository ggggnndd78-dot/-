import { Body, Controller, Get, Param, Post, Query, Res, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ProductImportJobsQueryDto, ProductImportRowsQueryDto, UploadProductImportDto } from './dto/product-imports.dto';
import { ProductImportsService } from './product-imports.service';

@ApiTags('Product Imports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('product-imports')
export class ProductImportsController {
  constructor(private readonly imports: ProductImportsService) {}

  @Get('template')
  async template(@Res() res: Response) {
    const buffer = await this.imports.downloadTemplateBuffer();
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="ghiyarak-product-import-template.xlsx"');
    res.send(buffer);
  }

  @Get('jobs')
  jobs(@CurrentUser() user: any, @Query() query: ProductImportJobsQueryDto) {
    return this.imports.listJobs(Number(user.sub), query);
  }

  @Get('jobs/:id')
  job(@CurrentUser() user: any, @Param('id') id: string) {
    return this.imports.getJob(Number(user.sub), id);
  }

  @Get('jobs/:id/rows')
  rows(@CurrentUser() user: any, @Param('id') id: string, @Query() query: ProductImportRowsQueryDto) {
    return this.imports.getRows(Number(user.sub), id, query);
  }

  @Get('jobs/:id/errors')
  errors(@CurrentUser() user: any, @Param('id') id: string) {
    return this.imports.getErrors(Number(user.sub), id);
  }

  @Post('jobs/:id/confirm')
  confirm(@CurrentUser() user: any, @Param('id') id: string) {
    return this.imports.confirm(Number(user.sub), id);
  }

  @Post('jobs/upload')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        organizationId: { type: 'integer' },
        organizationPublicId: { type: 'string' },
        branchId: { type: 'integer' },
        file: { type: 'string', format: 'binary' },
      },
      required: ['branchId', 'file'],
    },
  })
  upload(@CurrentUser() user: any, @Body() dto: UploadProductImportDto, @UploadedFile() file: any) {
    return this.imports.upload(Number(user.sub), dto, file);
  }
}
