import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { StudentProfileDto } from './dto/student-profile.dto.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsRepository } from './students.repository.js';

const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const PROFILE_NOT_FOUND = 'ไม่พบโปรไฟล์';

@Injectable()
export class StudentsService {
  constructor(private readonly studentsRepository: StudentsRepository) {}

  async getMine(user: AuthUser): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(profile);
  }

  async updateMine(
    user: AuthUser,
    dto: UpdateStudentProfileDto,
  ): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const saved = await this.studentsRepository.updateByUserId(user.userId, {
      fullName: dto.fullName.trim(),
      university: dto.university.trim(),
      major: dto.major.trim(),
      skills: dto.skills
        .map((skill) => skill.trim())
        .filter((skill) => skill.length > 0),
      portfolioUrl: dto.portfolioUrl?.trim() || null,
    });
    if (!saved) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(saved);
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }
}

function toDto(profile: {
  fullName: string;
  university: string;
  major: string;
  skills: string[];
  portfolioUrl: string | null;
}): StudentProfileDto {
  const dto = new StudentProfileDto();
  dto.fullName = profile.fullName;
  dto.university = profile.university;
  dto.major = profile.major;
  dto.skills = profile.skills;
  dto.portfolioUrl = profile.portfolioUrl;
  return dto;
}
