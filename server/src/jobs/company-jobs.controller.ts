import {
  Body,
  Controller,
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
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDto } from './dto/job.dto.js';
import { JobsService } from './jobs.service.js';

@ApiTags('Company jobs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('company/jobs')
export class CompanyJobsController {
  constructor(private readonly jobsService: JobsService) {}

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
