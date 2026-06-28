import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { ListingQueryDto } from './dto/listings.dto';
import { ListingsService } from './listings.service';

@ApiTags('Listings')
@Controller('listings')
export class ListingsController {
  constructor(private readonly listings: ListingsService) {}

  @Public()
  @Get()
  search(@Query() query: ListingQueryDto) { return this.listings.search(query); }

  @Public()
  @Get('compare/:productId')
  compare(@Param('productId', ParseIntPipe) productId: number, @Query() query: ListingQueryDto) {
    return this.listings.compare(productId, query);
  }

  @Public()
  @Get(':id/similar')
  similar(@Param('id', ParseIntPipe) id: number) { return this.listings.similar(id); }

  @Public()
  @Get(':id')
  details(@Param('id', ParseIntPipe) id: number) { return this.listings.details(id); }
}
