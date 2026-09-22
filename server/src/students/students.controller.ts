import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
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
import { StudentProfileDto } from './dto/student-profile.dto.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsService } from './students.service.js';

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
}
