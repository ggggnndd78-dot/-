
import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { CompleteDeploymentRunDto, CreateDeploymentRunDto, CreateQaRunDto, RecordQaResultDto, UpdateReleaseChecklistItemDto } from './dto/quality.dto';
import { QualityService } from './quality.service';

@ApiTags('Quality and Release Readiness')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('quality')
export class QualityController {
  constructor(private readonly quality: QualityService) {}

  @Get('readiness')
  @RequirePermissions('quality.readiness.view')
  readiness() {
    return this.quality.readiness();
  }

  @Post('runs')
  @RequirePermissions('quality.runs.manage')
  createRun(@CurrentUser() user: any, @Body() dto: CreateQaRunDto) {
    return this.quality.createRun(Number(user.sub), dto);
  }

  @Get('runs')
  @RequirePermissions('quality.runs.view')
  runs(@Query('take') take?: string, @Query('skip') skip?: string) {
    return this.quality.runs(Number(take || 50), Number(skip || 0));
  }

  @Get('runs/:id')
  @RequirePermissions('quality.runs.view')
  runDetails(@Param('id', ParseIntPipe) id: number) {
    return this.quality.runDetails(id);
  }

  @Post('runs/:id/results')
  @RequirePermissions('quality.runs.manage')
  recordResult(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: RecordQaResultDto) {
    return this.quality.recordResult(Number(user.sub), id, dto);
  }

  @Get('release-checklist')
  @RequirePermissions('release.manage')
  releaseChecklist() {
    return this.quality.releaseChecklist();
  }

  @Patch('release-checklist/:id')
  @RequirePermissions('release.manage')
  updateReleaseChecklistItem(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdateReleaseChecklistItemDto) {
    return this.quality.updateReleaseChecklistItem(Number(user.sub), id, dto);
  }

  @Post('deployments')
  @RequirePermissions('release.manage')
  createDeployment(@CurrentUser() user: any, @Body() dto: CreateDeploymentRunDto) {
    return this.quality.createDeployment(Number(user.sub), dto);
  }

  @Get('deployments')
  @RequirePermissions('release.manage')
  deployments(@Query('take') take?: string, @Query('skip') skip?: string) {
    return this.quality.deployments(Number(take || 50), Number(skip || 0));
  }

  @Patch('deployments/:id/complete')
  @RequirePermissions('release.manage')
  completeDeployment(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CompleteDeploymentRunDto) {
    return this.quality.completeDeployment(Number(user.sub), id, dto.status);
  }
}
