import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import {
  COVER_LETTER_REQUIRED,
  PROFILE_NOT_FOUND,
  RESUME_REQUIRED,
  STUDENT_ONLY,
} from './applications.constants.js';
import { ApplicationsRepository } from './applications.repository.js';
import { ApplicationResponseDto } from './dto/application-response.dto.js';
import { ApplyJobDto } from './dto/apply-job.dto.js';
import { Application } from './entities/application.entity.js';

@Injectable()
export class ApplicationsService {
  constructor(
    private readonly applicationsRepository: ApplicationsRepository,
  ) {}

  async apply(
    user: AuthUser,
    jobId: string,
    dto: ApplyJobDto,
  ): Promise<ApplicationResponseDto> {
    this.assertStudent(user);

    const coverLetter = dto.coverLetter?.trim();
    if (!coverLetter) {
      throw new BadRequestException(COVER_LETTER_REQUIRED);
    }

    const profile = await this.applicationsRepository.findStudentProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    if (!profile.resumeObjectKey) {
      throw new BadRequestException(RESUME_REQUIRED);
    }

    const application = await this.applicationsRepository.applyJob({
      studentId: profile.id,
      jobId,
      coverLetter,
      resumeObjectKey: profile.resumeObjectKey,
      actorUserId: user.userId,
    });

    return this.toResponseDto(application);
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }

  private toResponseDto(application: Application): ApplicationResponseDto {
    const dto = new ApplicationResponseDto();
    dto.id = application.id;
    dto.jobId = application.jobId;
    dto.studentId = application.studentId;
    dto.coverLetter = application.coverLetter;
    dto.resumeObjectKey = application.resumeObjectKey;
    dto.status = application.status;
    dto.createdAt = application.createdAt.toISOString();
    dto.updatedAt = application.updatedAt.toISOString();
    return dto;
  }
}
