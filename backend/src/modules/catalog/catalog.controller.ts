import { Body, Controller, Get, Param, ParseIntPipe, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CatalogService } from './catalog.service';
import { AddProductCompatibilityDto, AddProductMediaDto, CreateCategoryDto, CreatePartBrandDto, CreateProductDto, ProductQueryDto } from './dto/catalog.dto';

@ApiTags('Catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Public() @Get('categories') categories() { return this.catalog.categories(); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('categories') createCategory(@Body() dto: CreateCategoryDto) { return this.catalog.createCategory(dto); }
  @Public() @Get('part-brands') partBrands() { return this.catalog.partBrands(); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('part-brands') createPartBrand(@Body() dto: CreatePartBrandDto) { return this.catalog.createPartBrand(dto); }
  @Public() @Get('products') products(@Query() query: ProductQueryDto) { return this.catalog.products(query); }
  @Public() @Get('products/:id') product(@Param('id', ParseIntPipe) id: number) { return this.catalog.product(id); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('products') createProduct(@Body() dto: CreateProductDto) { return this.catalog.createProduct(dto); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('products/:id/media') addMedia(@Param('id', ParseIntPipe) id: number, @Body() dto: AddProductMediaDto) { return this.catalog.addMedia(id, dto); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('products/:id/compatibilities') addCompatibility(@Param('id', ParseIntPipe) id: number, @Body() dto: AddProductCompatibilityDto) { return this.catalog.addCompatibility(id, dto); }
}
