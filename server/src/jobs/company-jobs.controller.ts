import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDto } from './dto/job.dto.js';
import { PaginatedCompanyJobsDto } from './dto/paginated-company-jobs.dto.js';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateJobStatusDto } from './dto/update-job-status.dto.js';
import { JobsService } from './jobs.service.js';

@ApiTags('Company jobs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('company/jobs')
export class CompanyJobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  @ApiOperation({ summary: 'ประกาศของบริษัทนี้ ทั้งที่เปิดรับและปิดรับ' })
  @ApiResponse({ status: 200, type: PaginatedCompanyJobsDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์บริษัท' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() pagination: PaginationQueryDto,
  ): Promise<PaginatedCompanyJobsDto> {
    return this.jobsService.listMine(user, pagination);
  }

  @Get(':id')
  @ApiOperation({ summary: 'อ่านประกาศของบริษัทนี้เพื่อแก้ไข' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, type: JobDto })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศหรือโปรไฟล์บริษัท' })
  getOne(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<JobDto> {
    return this.jobsService.getMine(user, id);
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

  @Patch(':id')
  @ApiOperation({ summary: 'แก้ประกาศของบริษัทนี้' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiBody({ type: UpdateJobDto })
  @ApiResponse({ status: 200, type: JobDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศหรือโปรไฟล์บริษัท' })
  @ApiResponse({ status: 409, description: 'เวอร์ชันประกาศไม่ตรง' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateJobDto,
  ): Promise<JobDto> {
    return this.jobsService.update(user, id, dto);
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'เปิดหรือปิดรับสมัคร' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiBody({ type: UpdateJobStatusDto })
  @ApiResponse({ status: 200, type: JobDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศหรือโปรไฟล์บริษัท' })
  updateStatus(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateJobStatusDto,
  ): Promise<JobDto> {
    return this.jobsService.updateStatus(user, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'ลบประกาศของบริษัทนี้' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 204, description: 'ลบแล้ว' })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศหรือโปรไฟล์บริษัท' })
  remove(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.jobsService.remove(user, id);
  }
}
