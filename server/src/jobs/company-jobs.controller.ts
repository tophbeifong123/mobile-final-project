import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CompanyJobItemDto } from './dto/company-job-item.dto.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDto } from './dto/job.dto.js';
import { JobsService } from './jobs.service.js';

@ApiTags('Company jobs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('company/jobs')
export class CompanyJobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  @ApiOperation({ summary: 'ประกาศของบริษัทนี้ ทั้งที่เปิดรับและปิดรับ' })
  @ApiResponse({ status: 200, type: [CompanyJobItemDto] })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  list(@CurrentUser() user: AuthUser): Promise<CompanyJobItemDto[]> {
    return this.jobsService.listMine(user);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'สร้างประกาศฝึกงานสถานะ Open' })
  @ApiBody({ type: CreateJobDto })
  @ApiResponse({ status: 201, type: JobDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateJobDto,
  ): Promise<JobDto> {
    return this.jobsService.create(user, dto);
  }
}
