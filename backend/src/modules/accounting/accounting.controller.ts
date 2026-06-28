import { Body, Controller, Get, Param, ParseIntPipe, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { AccountingListQueryDto, InitializeChartDto } from './dto/accounting.dto';
import { AccountingService } from './accounting.service';

@ApiTags('Accounting')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('finance/accounting')
export class AccountingController {
  constructor(private readonly accounting: AccountingService) {}

  @Post('initialize-chart')
  @RequirePermissions('finance.accounting.manage')
  initializeChart(@CurrentUser() user: any, @Body() _dto: InitializeChartDto) {
    return this.accounting.initializeChartOfAccounts(user.sub);
  }

  @Get('accounts')
  @RequirePermissions('finance.accounting.manage')
  accounts() {
    return this.accounting.listAccounts();
  }

  @Get('journal-entries')
  @RequirePermissions('finance.accounting.manage')
  journalEntries(@Query() query: AccountingListQueryDto) {
    return this.accounting.journalEntries(query);
  }

  @Get('journal-entries/:id')
  @RequirePermissions('finance.accounting.manage')
  journalEntry(@Param('id', ParseIntPipe) id: number) {
    return this.accounting.journalEntryDetails(id);
  }

  @Get('accounts/:id/ledger')
  @RequirePermissions('finance.accounting.manage')
  accountLedger(@Param('id', ParseIntPipe) id: number, @Query() query: AccountingListQueryDto) {
    return this.accounting.accountLedger(id, query);
  }

  @Get('financial-transactions')
  @RequirePermissions('finance.accounting.manage')
  financialTransactions(@Query() query: AccountingListQueryDto) {
    return this.accounting.financialTransactions(query);
  }

  @Get('merchant-balances')
  @RequirePermissions('finance.accounting.manage')
  merchantBalances(@Query() query: AccountingListQueryDto) {
    return this.accounting.merchantBalances(query);
  }
}
