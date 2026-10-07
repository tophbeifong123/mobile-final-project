import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Res,
  UseGuards,
} from '@nestjs/common';
import { type Response } from 'express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiProduces,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { ApplicationsService } from './applications.service.js';
import { ApplicantDetailDto } from './dto/applicant-detail.dto.js';
import { ApplicationDetailDto } from './dto/application-detail.dto.js';
import { ApplicationResponseDto } from './dto/application-response.dto.js';
import { ApplyJobDto } from './dto/apply-job.dto.js';
import { JobApplicantItemDto } from './dto/job-applicant-item.dto.js';
import { MyApplicationItemDto } from './dto/my-application-item.dto.js';
import { SetExamLinkDto } from './dto/set-exam-link.dto.js';
import { SetInterviewLinkDto } from './dto/set-interview-link.dto.js';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';

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

  @Post('applications/:id/exam/complete')
  @ApiOperation({ summary: 'นักศึกษาแจ้งว่าทำข้อสอบแล้ว' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสใบสมัคร' })
  @ApiResponse({ status: 201, type: ApplicationDetailDto })
  @ApiResponse({
    status: 400,
    description: 'ยังไม่มีข้อสอบ เลยกำหนด กดซ้ำ หรือยังไม่ถึงขั้นพิจารณา',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบใบสมัคร' })
  completeExam(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<ApplicationDetailDto> {
    return this.applicationsService.completeExam(user, id);
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

  @Get('company/jobs/:id/applications')
  @ApiOperation({ summary: 'รายชื่อผู้สมัครของประกาศตำแหน่งงานนี้' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiResponse({
    status: 200,
    type: [JobApplicantItemDto],
    description:
      'รายชื่อผู้สมัครของประกาศงาน พร้อมข้อมูลมหาวิทยาลัย สาขา และสถานะ',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({
    status: 403,
    description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้',
  })
  @ApiResponse({
    status: 404,
    description: 'ไม่พบประกาศงานหรือโปรไฟล์บริษัท',
  })
  getJobApplicants(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
  ): Promise<JobApplicantItemDto[]> {
    return this.applicationsService.getJobApplicants(user, jobId);
  }

  @Get('company/jobs/:id/applications/:applicationId')
  @ApiOperation({
    summary: 'รายละเอียดผู้สมัคร โปรไฟล์ Resume และ Cover Letter',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({
    name: 'applicationId',
    format: 'uuid',
    description: 'รหัสใบสมัคร',
  })
  @ApiResponse({
    status: 200,
    type: ApplicantDetailDto,
    description:
      'รายละเอียดผู้สมัคร ข้อมูลโปรไฟล์นักศึกษา Resume และ Cover Letter',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({
    status: 403,
    description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้',
  })
  @ApiResponse({
    status: 404,
    description: 'ไม่พบประกาศงาน ใบสมัคร หรือโปรไฟล์บริษัท',
  })
  getApplicantDetail(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
  ): Promise<ApplicantDetailDto> {
    return this.applicationsService.getApplicantDetail(
      user,
      jobId,
      applicationId,
    );
  }

  @Get('company/jobs/:id/applications/:applicationId/resume')
  @ApiOperation({
    summary: 'เปิด PDF สำเนา Resume ตอนยื่นใบสมัคร เฉพาะบริษัทเจ้าของประกาศ',
  })
  @ApiProduces('application/pdf')
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({
    name: 'applicationId',
    format: 'uuid',
    description: 'รหัสใบสมัคร',
  })
  @ApiResponse({
    status: 200,
    description: 'ไฟล์ PDF ของใบสมัคร ไม่ใช่ Resume ล่าสุดของนักศึกษา',
    content: {
      'application/pdf': { schema: { type: 'string', format: 'binary' } },
    },
  })
  @ApiResponse({ status: 400, description: 'รหัสประกาศหรือใบสมัครไม่ใช่ UUID' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัทเจ้าของประกาศ' })
  @ApiResponse({
    status: 404,
    description: 'ไม่พบประกาศ ใบสมัคร โปรไฟล์ หรือไฟล์ PDF',
  })
  @ApiResponse({ status: 503, description: 'เปิดไฟล์ไม่ได้ กรุณาลองใหม่' })
  async getApplicantResume(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Res() res: Response,
  ): Promise<void> {
    const buffer = await this.applicationsService.getApplicantResume(
      user,
      jobId,
      applicationId,
    );
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      'inline; filename="application-resume.pdf"',
    );
    res.setHeader('Cache-Control', 'private, no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.send(buffer);
  }

  @Get('company/jobs/:id/applications/:applicationId/avatar')
  @ApiOperation({ summary: 'ดาวน์โหลดหรือดูรูปโปรไฟล์ของผู้สมัคร' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({
    name: 'applicationId',
    format: 'uuid',
    description: 'รหัสใบสมัคร',
  })
  @ApiResponse({ status: 200, description: 'ไฟล์รูปภาพโปรไฟล์ผู้สมัคร' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({
    status: 403,
    description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้',
  })
  @ApiResponse({
    status: 404,
    description: 'ไม่พบประกาศงาน ใบสมัคร หรือรูปโปรไฟล์',
  })
  async getApplicantAvatar(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, mimeType } =
      await this.applicationsService.getApplicantAvatar(
        user,
        jobId,
        applicationId,
      );
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'private, max-age=3600');
    res.send(buffer);
  }

  @Get('company/jobs/:id/applications/:applicationId/documents/:documentId/file')
  @ApiOperation({ summary: 'เปิด PDF เอกสารของผู้สมัคร' })
  @ApiResponse({ status: 200, description: 'ไฟล์ PDF สำหรับบริษัทเจ้าของประกาศเท่านั้น' })
  async getApplicantDocument(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Param('documentId') documentId: string,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, fileName } = await this.applicationsService.getApplicantDocument(user, jobId, applicationId, documentId);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(fileName)}"`);
    res.send(buffer);
  }

  @Put('company/jobs/:id/applications/:applicationId/exam')
  @ApiOperation({ summary: 'ส่งหรือแก้ลิงก์ข้อสอบพร้อมกำหนดเวลา' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({ name: 'applicationId', format: 'uuid', description: 'รหัสใบสมัคร' })
  @ApiBody({ type: SetExamLinkDto })
  @ApiResponse({ status: 200, type: ApplicantDetailDto })
  @ApiResponse({ status: 400, description: 'ลิงก์ เวลา หรือสถานะใบสมัครไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบใบสมัคร' })
  setExamLink(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Body() dto: SetExamLinkDto,
  ): Promise<ApplicantDetailDto> {
    return this.applicationsService.setExamLink(user, jobId, applicationId, dto);
  }

  @Post('company/jobs/:id/applications/:applicationId/exam/pass')
  @ApiOperation({
    summary: 'ตรวจว่าข้อสอบผ่าน แล้วจึงเรียกสัมภาษณ์ได้',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({ name: 'applicationId', format: 'uuid', description: 'รหัสใบสมัคร' })
  @ApiResponse({ status: 200, type: ApplicantDetailDto })
  @ApiResponse({ status: 400, description: 'นักศึกษายังไม่ทำข้อสอบ หรือตรวจผ่านไปแล้ว' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบใบสมัคร' })
  passExam(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
  ): Promise<ApplicantDetailDto> {
    return this.applicationsService.passExam(user, jobId, applicationId);
  }

  @Put('company/jobs/:id/applications/:applicationId/interview')
  @ApiOperation({
    summary: 'เรียกสัมภาษณ์หลังตรวจว่าข้อสอบผ่าน',
    description:
      'ใช้ได้เมื่อใบสมัครกำลังพิจารณาและบริษัทกดว่าข้อสอบผ่านแล้ว สัมภาษณ์ออนไลน์ต้องมีลิงก์ สัมภาษณ์ออนไซต์ส่งเฉพาะวันเวลา',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({ name: 'applicationId', format: 'uuid', description: 'รหัสใบสมัคร' })
  @ApiBody({ type: SetInterviewLinkDto })
  @ApiResponse({ status: 200, type: ApplicantDetailDto })
  @ApiResponse({ status: 400, description: 'ลิงก์ เวลา หรือสถานะใบสมัครไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้' })
  @ApiResponse({ status: 404, description: 'ไม่พบใบสมัคร' })
  setInterviewLink(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Body() dto: SetInterviewLinkDto,
  ): Promise<ApplicantDetailDto> {
    return this.applicationsService.setInterviewLink(
      user,
      jobId,
      applicationId,
      dto,
    );
  }

  @Patch('company/jobs/:id/applications/:applicationId/status')
  @ApiOperation({
    summary: 'เปลี่ยนสถานะผู้สมัคร (Reviewing, Accepted, Rejected)',
    description:
      'ตอบรับได้เมื่อกำลังพิจารณาและมีวันเวลานัดสัมภาษณ์แล้ว ปฏิเสธได้ตลอดระหว่างกำลังพิจารณา',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสประกาศงาน' })
  @ApiParam({
    name: 'applicationId',
    format: 'uuid',
    description: 'รหัสใบสมัคร',
  })
  @ApiBody({ type: UpdateApplicationStatusDto })
  @ApiResponse({
    status: 200,
    type: ApplicantDetailDto,
    description: 'เปลี่ยนสถานะใบสมัครสำเร็จ พร้อมบันทึก event และแจ้งเตือน',
  })
  @ApiResponse({
    status: 400,
    description:
      'การเปลี่ยนสถานะไม่ถูกต้อง, ยังไม่ได้เป็น Reviewing หรือใบสมัครอยู่ในสถานะสิ้นสุดแล้ว',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({
    status: 403,
    description: 'เฉพาะบริษัท หรือไม่ใช่ประกาศของบริษัทนี้',
  })
  @ApiResponse({
    status: 404,
    description: 'ไม่พบประกาศงาน ใบสมัคร หรือโปรไฟล์บริษัท',
  })
  updateApplicantStatus(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) jobId: string,
    @Param('applicationId', new ParseUUIDPipe()) applicationId: string,
    @Body() dto: UpdateApplicationStatusDto,
  ): Promise<ApplicantDetailDto> {
    return this.applicationsService.updateApplicantStatus(
      user,
      jobId,
      applicationId,
      dto,
    );
  }
}
