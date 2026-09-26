import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { type UploadedFilePayload } from '../storage/uploaded-file.interface.js';
import { CompaniesRepository } from './companies.repository.js';
import { CompanyDashboardSummaryDto } from './dto/company-dashboard-summary.dto.js';
import { CompanyProfileDto } from './dto/company-profile.dto.js';
import { UpdateCompanyProfileDto } from './dto/update-company-profile.dto.js';

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';
const FILE_REQUIRED = 'กรุณาเลือกไฟล์รูปภาพ';
const ONLY_IMAGE_ALLOWED = 'เลือกได้เฉพาะไฟล์รูปภาพเท่านั้น (PNG, JPG, WEBP, SVG)';

@Injectable()
export class CompaniesService {
  constructor(
    private readonly companiesRepository: CompaniesRepository,
    private readonly storageService: StorageService,
  ) {}

  async getDashboard(user: AuthUser): Promise<CompanyDashboardSummaryDto> {
    this.assertCompany(user);

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const summary = await this.companiesRepository.getDashboardSummary(
      profile.id,
    );

    const dto = new CompanyDashboardSummaryDto();
    dto.totalJobs = summary.totalJobs;
    dto.openJobs = summary.openJobs;
    dto.totalApplicants = summary.totalApplicants;
    return dto;
  }

  async getProfile(user: AuthUser): Promise<CompanyProfileDto> {
    this.assertCompany(user);

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    return toProfileDto(profile);
  }

  async updateProfile(
    user: AuthUser,
    dto: UpdateCompanyProfileDto,
  ): Promise<CompanyProfileDto> {
    this.assertCompany(user);

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const saved = await this.companiesRepository.updateProfile(profile.id, {
      name: dto.name.trim(),
      businessType: dto.businessType.trim(),
      description: dto.description.trim(),
      websiteUrl: dto.websiteUrl !== undefined ? dto.websiteUrl.trim() : undefined,
      location: dto.location !== undefined ? dto.location.trim() : undefined,
      companySize: dto.companySize !== undefined ? dto.companySize.trim() : undefined,
      perks: dto.perks !== undefined ? dto.perks : undefined,
    });

    if (!saved) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    return toProfileDto(saved);
  }

  async uploadLogo(
    user: AuthUser,
    file: UploadedFilePayload | undefined,
  ): Promise<CompanyProfileDto> {
    this.assertCompany(user);
    const { ext, mimeType } = this.validateAndExtractImage(file);

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    // Clean up previous logo if exists
    if (profile.logoObjectKey) {
      try {
        await this.storageService.delete(profile.logoObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }

    const objectKey = `company-logos/${user.userId}/${Date.now()}-${randomUUID()}.${ext}`;
    await this.storageService.put(objectKey, file!.buffer, mimeType);

    const updated = await this.companiesRepository.updateLogoObjectKey(
      profile.id,
      objectKey,
    );
    if (!updated) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    return toProfileDto(updated);
  }

  async getLogoFile(
    user: AuthUser,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    this.assertCompany(user);
    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    if (!profile.logoObjectKey) {
      throw new NotFoundException('ไม่พบโลโก้บริษัท');
    }
    const buffer = await this.storageService.get(profile.logoObjectKey);
    if (!buffer) {
      throw new NotFoundException('ไม่พบโลโก้บริษัท');
    }
    const mimeType = this.mimeTypeFromObjectKey(profile.logoObjectKey);
    return { buffer, mimeType };
  }

  async deleteLogo(user: AuthUser): Promise<CompanyProfileDto> {
    this.assertCompany(user);
    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    if (profile.logoObjectKey) {
      try {
        await this.storageService.delete(profile.logoObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }
    const updated = await this.companiesRepository.updateLogoObjectKey(
      profile.id,
      null,
    );
    if (!updated) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    return toProfileDto(updated);
  }

  async uploadCover(
    user: AuthUser,
    file: UploadedFilePayload | undefined,
  ): Promise<CompanyProfileDto> {
    this.assertCompany(user);
    const { ext, mimeType } = this.validateAndExtractImage(file);

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    // Clean up previous cover if exists
    if (profile.coverObjectKey) {
      try {
        await this.storageService.delete(profile.coverObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }

    const objectKey = `company-covers/${user.userId}/${Date.now()}-${randomUUID()}.${ext}`;
    await this.storageService.put(objectKey, file!.buffer, mimeType);

    const updated = await this.companiesRepository.updateCoverObjectKey(
      profile.id,
      objectKey,
    );
    if (!updated) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    return toProfileDto(updated);
  }

  async getCoverFile(
    user: AuthUser,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    this.assertCompany(user);
    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    if (!profile.coverObjectKey) {
      throw new NotFoundException('ไม่พบรูปหน้าปกบริษัท');
    }
    const buffer = await this.storageService.get(profile.coverObjectKey);
    if (!buffer) {
      throw new NotFoundException('ไม่พบรูปหน้าปกบริษัท');
    }
    const mimeType = this.mimeTypeFromObjectKey(profile.coverObjectKey);
    return { buffer, mimeType };
  }

  async deleteCover(user: AuthUser): Promise<CompanyProfileDto> {
    this.assertCompany(user);
    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    if (profile.coverObjectKey) {
      try {
        await this.storageService.delete(profile.coverObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }
    const updated = await this.companiesRepository.updateCoverObjectKey(
      profile.id,
      null,
    );
    if (!updated) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    return toProfileDto(updated);
  }

  private validateAndExtractImage(file: UploadedFilePayload | undefined): {
    ext: string;
    mimeType: string;
  } {
    if (!file) {
      throw new BadRequestException(FILE_REQUIRED);
    }

    const isPng =
      file.buffer &&
      file.buffer.length >= 8 &&
      file.buffer[0] === 0x89 &&
      file.buffer[1] === 0x50 &&
      file.buffer[2] === 0x4e &&
      file.buffer[3] === 0x47;

    const isJpeg =
      file.buffer &&
      file.buffer.length >= 3 &&
      file.buffer[0] === 0xff &&
      file.buffer[1] === 0xd8 &&
      file.buffer[2] === 0xff;

    const isWebp =
      file.buffer &&
      file.buffer.length >= 12 &&
      file.buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
      file.buffer.subarray(8, 12).toString('ascii') === 'WEBP';

    const isGif =
      file.buffer &&
      file.buffer.length >= 6 &&
      (file.buffer.subarray(0, 6).toString('ascii') === 'GIF87a' ||
        file.buffer.subarray(0, 6).toString('ascii') === 'GIF89a');

    const isSvg =
      file.originalname?.toLowerCase().endsWith('.svg') ||
      file.mimetype === 'image/svg+xml' ||
      (file.buffer &&
        file.buffer.subarray(0, 100).toString('utf8').toLowerCase().includes('<svg'));

    const isImageMime = Boolean(file.mimetype?.startsWith('image/'));
    const hasImageExt = Boolean(
      file.originalname?.toLowerCase().match(/\.(png|jpe?g|webp|svg|gif)$/),
    );

    const isImage =
      isPng || isJpeg || isWebp || isGif || isSvg || isImageMime || hasImageExt;

    if (!isImage) {
      throw new BadRequestException(ONLY_IMAGE_ALLOWED);
    }

    let ext = 'png';
    let mimeType = 'image/png';
    if (isPng) {
      ext = 'png';
      mimeType = 'image/png';
    } else if (isJpeg) {
      ext = 'jpg';
      mimeType = 'image/jpeg';
    } else if (isWebp) {
      ext = 'webp';
      mimeType = 'image/webp';
    } else if (isGif) {
      ext = 'gif';
      mimeType = 'image/gif';
    } else if (isSvg) {
      ext = 'svg';
      mimeType = 'image/svg+xml';
    } else if (file.mimetype && file.mimetype.startsWith('image/')) {
      mimeType = file.mimetype;
      const sub = file.mimetype.split('/')[1];
      ext = sub === 'jpeg' ? 'jpg' : sub;
    } else if (hasImageExt) {
      const match = file.originalname?.toLowerCase().match(/\.([a-z0-9]+)$/);
      if (match) {
        ext = match[1];
        mimeType = ext === 'jpg' ? 'image/jpeg' : `image/${ext}`;
      }
    }

    return { ext, mimeType };
  }

  private mimeTypeFromObjectKey(key: string): string {
    const ext = key.split('.').pop()?.toLowerCase();
    if (ext === 'jpg' || ext === 'jpeg') return 'image/jpeg';
    if (ext === 'webp') return 'image/webp';
    if (ext === 'svg') return 'image/svg+xml';
    if (ext === 'gif') return 'image/gif';
    return 'image/png';
  }

  private assertCompany(user: AuthUser): void {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }
  }
}

function toProfileDto(profile: {
  name: string;
  businessType: string;
  description: string;
  logoObjectKey?: string | null;
  websiteUrl?: string;
  location?: string;
  companySize?: string;
  perks?: string[];
  coverObjectKey?: string | null;
}): CompanyProfileDto {
  const dto = new CompanyProfileDto();
  dto.name = profile.name;
  dto.businessType = profile.businessType;
  dto.description = profile.description;
  dto.logoObjectKey = profile.logoObjectKey ?? null;
  dto.websiteUrl = profile.websiteUrl ?? '';
  dto.location = profile.location ?? '';
  dto.companySize = profile.companySize ?? '';
  dto.perks = profile.perks ?? [];
  dto.coverObjectKey = profile.coverObjectKey ?? null;
  return dto;
}
