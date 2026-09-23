import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CompaniesService } from './companies.service.js';
import { CompanyDashboardSummaryDto } from './dto/company-dashboard-summary.dto.js';

@ApiTags('Companies')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('companies')
export class CompaniesController {
  constructor(private readonly companiesService: CompaniesService) {}

  @Get('me/dashboard')
  @ApiOperation({ summary: 'สรุปตัวเลขแดชบอร์ดของบริษัท' })
  @ApiResponse({ status: 200, type: CompanyDashboardSummaryDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  getDashboard(
    @CurrentUser() user: AuthUser,
  ): Promise<CompanyDashboardSummaryDto> {
    return this.companiesService.getDashboard(user);
  }
}
