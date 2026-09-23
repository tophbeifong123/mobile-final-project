import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
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
import { ApplicationsService } from './applications.service.js';
import { ApplicationDetailDto } from './dto/application-detail.dto.js';
import { ApplicationResponseDto } from './dto/application-response.dto.js';
import { ApplyJobDto } from './dto/apply-job.dto.js';
import { MyApplicationItemDto } from './dto/my-application-item.dto.js';

@ApiTags('Applications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class ApplicationsController {
  constructor(private readonly applicationsService: ApplicationsService) {}

  @Get('applications')
  @ApiOperation({ summary: 'รายการใบสมัครของตัวเอง' })
  @ApiResponse({
    status: 200,
    type: [MyApplicationItemDto],
    description: 'รายการใบสมัครที่นักศึกษาเคยยื่น',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์นักศึกษา' })
  getMine(@CurrentUser() user: AuthUser): Promise<MyApplicationItemDto[]> {
    return this.applicationsService.getMine(user);
  }

  @Get('applications/:id')
  @ApiOperation({ summary: 'รายละเอียดใบสมัครและ timeline' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสใบสมัคร' })
  @ApiResponse({
    status: 200,
    type: ApplicationDetailDto,
    description: 'รายละเอียดใบสมัคร ข้อมูลงาน Cover Letter และ timeline สถานะ',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบใบสมัคร' })
  getDetail(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<ApplicationDetailDto> {
    return this.applicationsService.getDetail(user, id);
  }

  @Post('jobs/:id/applications')
  @ApiOperation({ summary: 'สมัครงานฝึกงาน' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiBody({ type: ApplyJobDto })
  @ApiResponse({
    status: 201,
    type: ApplicationResponseDto,
    description: 'ยื่นใบสมัครสำเร็จ สถานะเป็น submitted',
  })
  @ApiResponse({
    status: 400,
    description:
      'ไม่ได้ระบุ Cover Letter, ยังไม่มี Resume หรือประกาศงานปิดรับแล้ว',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบประกาศงานหรือโปรไฟล์' })
  @ApiResponse({ status: 409, description: 'สมัครงานนี้ไปแล้ว' })
  apply(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyJobDto,
  ): Promise<ApplicationResponseDto> {
    return this.applicationsService.apply(user, id, dto);
  }
}
