import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { type UploadedFilePayload } from '../storage/uploaded-file.interface.js';
import { CompaniesService } from './companies.service.js';
import { CompanyDashboardSummaryDto } from './dto/company-dashboard-summary.dto.js';
import { CompanyProfileDto } from './dto/company-profile.dto.js';
import { UpdateCompanyProfileDto } from './dto/update-company-profile.dto.js';

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

  @Get('me')
  @ApiOperation({ summary: 'อ่านโปรไฟล์บริษัท' })
  @ApiResponse({ status: 200, type: CompanyProfileDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  getProfile(@CurrentUser() user: AuthUser): Promise<CompanyProfileDto> {
    return this.companiesService.getProfile(user);
  }

  @Patch('me')
  @ApiOperation({ summary: 'แก้ไขโปรไฟล์บริษัท' })
  @ApiBody({ type: UpdateCompanyProfileDto })
  @ApiResponse({ status: 200, type: CompanyProfileDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  updateProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateCompanyProfileDto,
  ): Promise<CompanyProfileDto> {
    return this.companiesService.updateProfile(user, dto);
  }

  @Post('me/logo')
  @ApiOperation({ summary: 'อัปโหลด logo ของบริษัท' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'ไฟล์รูปภาพโลโก้ (PNG, JPG, WEBP, SVG)',
        },
      },
      required: ['file'],
    },
  })
  @ApiResponse({
    status: 201,
    type: CompanyProfileDto,
    description: 'อัปโหลดสำเร็จ',
  })
  @ApiResponse({
    status: 400,
    description: 'ไฟล์ไม่ใช่รูปภาพ หรือไม่ได้เลือกไฟล์',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  @UseInterceptors(FileInterceptor('file'))
  uploadLogo(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: UploadedFilePayload | undefined,
  ): Promise<CompanyProfileDto> {
    return this.companiesService.uploadLogo(user, file);
  }
}
