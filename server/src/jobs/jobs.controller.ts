import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { type Response } from 'express';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { JobDetailDto } from './dto/job-detail.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { PaginatedJobsDto } from './dto/paginated-jobs.dto.js';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto.js';
import { JobsService } from './jobs.service.js';

@ApiTags('Jobs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  @ApiOperation({ summary: 'รายการงานที่เปิดรับ' })
  @ApiResponse({ status: 200, type: PaginatedJobsDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: JobFeedQueryDto,
  ): Promise<PaginatedJobsDto> {
    return this.jobsService.listOpen(user, query);
  }

  @Get('saved')
  @ApiOperation({ summary: 'งานที่นักศึกษาบันทึกไว้และยังเปิดรับ' })
  @ApiResponse({ status: 200, type: PaginatedJobsDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  listSaved(
    @CurrentUser() user: AuthUser,
    @Query() pagination: PaginationQueryDto,
  ): Promise<PaginatedJobsDto> {
    return this.jobsService.listSaved(user, pagination);
  }

  @Get(':id')
  @ApiOperation({ summary: 'รายละเอียดงานที่เปิดรับ' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, type: JobDetailDto })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศ' })
  getOne(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<JobDetailDto> {
    return this.jobsService.getOpen(user, id);
  }

  @Get(':id/company-logo')
  @ApiOperation({
    summary: 'โลโก้บริษัทบนรายละเอียดงานที่เปิดรับ (เฉพาะนักศึกษา)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({
    status: 200,
    description: 'ไฟล์โลโก้ PNG/JPEG/WEBP/GIF/SVG',
    content: {
      'image/png': { schema: { type: 'string', format: 'binary' } },
      'image/jpeg': { schema: { type: 'string', format: 'binary' } },
      'image/webp': { schema: { type: 'string', format: 'binary' } },
      'image/gif': { schema: { type: 'string', format: 'binary' } },
      'image/svg+xml': { schema: { type: 'string', format: 'binary' } },
    },
  })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศที่เปิดรับหรือโลโก้' })
  async getCompanyLogo(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, mimeType } = await this.jobsService.getCompanyLogo(
      user,
      id,
    );
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'private, no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Security-Policy', "sandbox; default-src 'none'");
    res.setHeader('Content-Disposition', 'attachment');
    res.send(buffer);
  }

  @Post(':id/save')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'บันทึกงานที่เปิดรับ ถ้าบันทึกแล้วไม่สร้างซ้ำ' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 204, description: 'บันทึกแล้ว' })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศหรือโปรไฟล์' })
  save(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.jobsService.save(user, id);
  }

  @Delete(':id/save')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'ยกเลิกบันทึกงาน' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 204, description: 'ยกเลิกบันทึกแล้ว' })
  @ApiResponse({ status: 400, description: 'รหัสประกาศไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  unsave(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.jobsService.unsave(user, id);
  }
}
