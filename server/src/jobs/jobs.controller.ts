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
  UseGuards,
} from '@nestjs/common';
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
import { JobFeedItemDto } from './dto/job-feed-item.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { JobsService } from './jobs.service.js';

@ApiTags('Jobs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  @ApiOperation({ summary: 'รายการงานที่เปิดรับ' })
  @ApiResponse({ status: 200, type: [JobFeedItemDto] })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: JobFeedQueryDto,
  ): Promise<JobFeedItemDto[]> {
    return this.jobsService.listOpen(user, query);
  }

  @Get('saved')
  @ApiOperation({ summary: 'งานที่นักศึกษาบันทึกไว้และยังเปิดรับ' })
  @ApiResponse({ status: 200, type: [JobFeedItemDto] })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  listSaved(@CurrentUser() user: AuthUser): Promise<JobFeedItemDto[]> {
    return this.jobsService.listSaved(user);
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
