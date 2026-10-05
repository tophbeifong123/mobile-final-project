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
import { ProvincesService } from '../provinces/provinces.service.js';
import { CompaniesRepository } from './companies.repository.js';
import { CompanyDashboardSummaryDto } from './dto/company-dashboard-summary.dto.js';
import { CompanyProfileDto } from './dto/company-profile.dto.js';
import { UpdateCompanyProfileDto } from './dto/update-company-profile.dto.js';

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';
const FILE_REQUIRED = 'กรุณาเลือกไฟล์รูปภาพ';
const ONLY_IMAGE_ALLOWED = 'เลือกได้เฉพาะไฟล์รูปภาพเท่านั้น';

@Injectable()
export class CompaniesService {
  constructor(
    private readonly companiesRepository: CompaniesRepository,
    private readonly storageService: StorageService,
    private readonly provincesService: ProvincesService,
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

    const data: {
      name?: string;
      businessType?: string;
      description?: string;
      provinceId?: number | null;
      location?: string;
      latitude?: number | null;
      longitude?: number | null;
    } = {};
    if (typeof dto.name === 'string') data.name = dto.name.trim();
    if (typeof dto.businessType === 'string')
      data.businessType = dto.businessType.trim();
    if (typeof dto.description === 'string')
      data.description = dto.description.trim();
    if (typeof dto.location === 'string') {
      const location = dto.location.trim();
      if (location.length > 255) {
        throw new BadRequestException('ที่อยู่ต้องไม่เกิน 255 ตัวอักษร');
      }
      data.location = location;
    }

    const currentProvinceId = profile.provinceId ?? null;
    const provinceId =
      dto.provinceId !== undefined ? dto.provinceId : currentProvinceId;
    if (dto.provinceId !== undefined) {
      if (dto.provinceId !== null) {
        await this.provincesService.requireById(dto.provinceId);
      }
      data.provinceId = dto.provinceId;
    }

    const hasLatitude = dto.latitude !== undefined;
    const hasLongitude = dto.longitude !== undefined;
    if (hasLatitude !== hasLongitude) {
      throw new BadRequestException('ต้องส่ง latitude และ longitude พร้อมกัน');
    }
    if (hasLatitude && hasLongitude) {
      const bothNull = dto.latitude === null && dto.longitude === null;
      const validPair =
        typeof dto.latitude === 'number' &&
        typeof dto.longitude === 'number' &&
        Number.isFinite(dto.latitude) &&
        Number.isFinite(dto.longitude) &&
        dto.latitude >= -90 &&
        dto.latitude <= 90 &&
        dto.longitude >= -180 &&
        dto.longitude <= 180;
      if (!bothNull && !validPair) {
        throw new BadRequestException('พิกัดไม่ถูกต้อง');
      }
      if (validPair && provinceId === null) {
        throw new BadRequestException('ต้องเลือกจังหวัดก่อนบันทึกหมุดสำนักงาน');
      }
      data.latitude = dto.latitude;
      data.longitude = dto.longitude;
    } else if (
      dto.provinceId !== undefined &&
      dto.provinceId !== currentProvinceId
    ) {
      // A pin from the previously selected province must not silently survive
      // a province change. The caller can send a fresh coordinate pair instead.
      data.latitude = null;
      data.longitude = null;
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('ไม่มีข้อมูลสำหรับแก้ไข');
    }

    const saved = await this.companiesRepository.updateProfile(
      profile.id,
      data,
    );

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
      file.buffer.length >= 3 &&
      file.buffer.subarray(0, 3).toString('ascii') === 'GIF';

    const isSvg =
      file.originalname?.toLowerCase().endsWith('.svg') ||
      file.mimetype === 'image/svg+xml' ||
      (file.buffer && file.buffer.toString('utf8').includes('<svg'));

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

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const objectKey = `company-logos/${user.userId}/${Date.now()}-${randomUUID()}.${ext}`;
    await this.storageService.put(objectKey, file.buffer, mimeType);

    const updated = await this.companiesRepository.updateLogoObjectKey(
      profile.id,
      objectKey,
    );
    if (!updated) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    return toProfileDto(updated);
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
  logoObjectKey: string | null;
  provinceId?: number | null;
  province?: { nameTh: string } | null;
  location?: string;
  latitude?: number | null;
  longitude?: number | null;
}): CompanyProfileDto {
  const dto = new CompanyProfileDto();
  dto.name = profile.name;
  dto.businessType = profile.businessType;
  dto.description = profile.description;
  dto.logoObjectKey = profile.logoObjectKey ?? null;
  dto.provinceId = profile.provinceId ?? null;
  dto.provinceName = profile.province?.nameTh ?? null;
  dto.location = profile.location ?? '';
  dto.latitude = profile.latitude ?? null;
  dto.longitude = profile.longitude ?? null;
  return dto;
}
