import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Post,
  Param,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { type Response } from 'express';
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
import { ResumeResponseDto } from './dto/resume-response.dto.js';
import { StudentProfileDto } from './dto/student-profile.dto.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsService } from './students.service.js';
import { StudentDocumentType } from './student-document.entity.js';

@ApiTags('Students')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('students')
export class StudentsController {
  constructor(private readonly studentsService: StudentsService) {}

  @Get('me')
  @ApiOperation({ summary: 'อ่านโปรไฟล์นักศึกษา' })
  @ApiResponse({ status: 200, type: StudentProfileDto })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  getMe(@CurrentUser() user: AuthUser): Promise<StudentProfileDto> {
    return this.studentsService.getMine(user);
  }

  @Patch('me')
  @ApiOperation({ summary: 'แก้โปรไฟล์นักศึกษา' })
  @ApiBody({ type: UpdateStudentProfileDto })
  @ApiResponse({ status: 200, type: StudentProfileDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  updateMe(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateStudentProfileDto,
  ): Promise<StudentProfileDto> {
    return this.studentsService.updateMine(user, dto);
  }

  @Post('me/resume')
  @ApiOperation({ summary: 'อัปโหลด Resume เป็น PDF' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'ไฟล์ Resume รูปแบบ PDF',
        },
      },
      required: ['file'],
    },
  })
  @ApiResponse({
    status: 201,
    type: ResumeResponseDto,
    description: 'อัปโหลดสำเร็จ',
  })
  @ApiResponse({
    status: 400,
    description: 'ไฟล์ไม่ใช่ PDF หรือไม่ได้เลือกไฟล์',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  uploadResume(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: UploadedFilePayload | undefined,
  ): Promise<ResumeResponseDto> {
    return this.studentsService.uploadResume(user, file);
  }

  @Get('me/resume/file')
  @ApiOperation({ summary: 'ดาวน์โหลดหรือดูไฟล์ Resume เป็น PDF' })
  @ApiResponse({ status: 200, description: 'ไฟล์ PDF Resume' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบไฟล์ Resume' })
  async getResumeFile(
    @CurrentUser() user: AuthUser,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, fileName } = await this.studentsService.getResumeFile(user);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${encodeURIComponent(fileName)}"`,
    );
    res.send(buffer);
  }

  @Get('me/documents')
  @ApiOperation({ summary: 'รายการเอกสารของนักศึกษา' })
  @ApiResponse({ status: 200, description: 'CV, transcript และเอกสารอื่น' })
  listDocuments(@CurrentUser() user: AuthUser) {
    return this.studentsService.listDocuments(user);
  }

  @Post('me/documents/cv')
  @ApiOperation({ summary: 'อัปโหลดหรือแทนที่ CV เป็น PDF' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } }, required: ['file'] } })
  @ApiResponse({ status: 201, description: 'บันทึก CV สำเร็จ' })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  uploadCv(@CurrentUser() user: AuthUser, @UploadedFile() file: UploadedFilePayload | undefined) {
    return this.studentsService.uploadDocument(user, StudentDocumentType.Cv, file);
  }

  @Post('me/documents/transcript')
  @ApiOperation({ summary: 'อัปโหลดหรือแทนที่ Transcript เป็น PDF' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } }, required: ['file'] } })
  @ApiResponse({ status: 201, description: 'บันทึก Transcript สำเร็จ' })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  uploadTranscript(@CurrentUser() user: AuthUser, @UploadedFile() file: UploadedFilePayload | undefined) {
    return this.studentsService.uploadDocument(user, StudentDocumentType.Transcript, file);
  }

  @Post('me/documents/other')
  @ApiOperation({ summary: 'เพิ่มเอกสารอื่นเป็น PDF (สูงสุด 3 ไฟล์)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } }, required: ['file'] } })
  @ApiResponse({ status: 201, description: 'เพิ่มเอกสารสำเร็จ' })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  uploadOther(@CurrentUser() user: AuthUser, @UploadedFile() file: UploadedFilePayload | undefined) {
    return this.studentsService.uploadDocument(user, StudentDocumentType.Other, file);
  }

  @Delete('me/documents/:id')
  @ApiOperation({ summary: 'ลบ CV, transcript หรือเอกสารอื่น' })
  @ApiResponse({ status: 200, description: 'ลบเอกสารสำเร็จ' })
  deleteDocument(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.studentsService.deleteDocument(user, id);
  }

  @Get('me/documents/:id/file')
  @ApiOperation({ summary: 'เปิดไฟล์เอกสาร PDF ของนักศึกษา' })
  @ApiResponse({ status: 200, description: 'ไฟล์ PDF' })
  async getDocument(@CurrentUser() user: AuthUser, @Param('id') id: string, @Res() res: Response) {
    const { buffer, fileName } = await this.studentsService.getStudentDocument(user, id);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(fileName)}"`);
    res.send(buffer);
  }

  @Post('me/avatar')
  @ApiOperation({ summary: 'อัปโหลดรูปโปรไฟล์นักศึกษา' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'ไฟล์รูปภาพโปรไฟล์ (PNG, JPG, WEBP, SVG, GIF)',
        },
      },
      required: ['file'],
    },
  })
  @ApiResponse({
    status: 201,
    type: StudentProfileDto,
    description: 'อัปโหลดรูปโปรไฟล์สำเร็จ',
  })
  @ApiResponse({
    status: 400,
    description: 'ไฟล์ไม่ใช่รูปภาพ หรือไม่ได้เลือกไฟล์',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  @UseInterceptors(FileInterceptor('file'))
  uploadAvatar(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: UploadedFilePayload | undefined,
  ): Promise<StudentProfileDto> {
    return this.studentsService.uploadAvatar(user, file);
  }

  @Get('me/avatar')
  @ApiOperation({ summary: 'ดาวน์โหลดหรือดูรูปโปรไฟล์นักศึกษา' })
  @ApiResponse({ status: 200, description: 'ไฟล์รูปภาพโปรไฟล์' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบรูปโปรไฟล์' })
  async getAvatarFile(
    @CurrentUser() user: AuthUser,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, mimeType } = await this.studentsService.getAvatarFile(user);
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'private, max-age=3600');
    res.send(buffer);
  }

  @Delete('me/avatar')
  @ApiOperation({ summary: 'ลบรูปโปรไฟล์นักศึกษา' })
  @ApiResponse({
    status: 200,
    type: StudentProfileDto,
    description: 'ลบรูปโปรไฟล์สำเร็จ',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์' })
  deleteAvatar(@CurrentUser() user: AuthUser): Promise<StudentProfileDto> {
    return this.studentsService.deleteAvatar(user);
  }
}

