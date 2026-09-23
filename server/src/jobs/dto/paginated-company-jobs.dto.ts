import { ApiProperty } from '@nestjs/swagger';
import { CompanyJobItemDto } from './company-job-item.dto.js';

export class PaginatedCompanyJobsDto {
  @ApiProperty({ type: [CompanyJobItemDto] })
  items: CompanyJobItemDto[];

  @ApiProperty({ example: 25 })
  total: number;

  @ApiProperty({ example: 1 })
  page: number;

  @ApiProperty({ example: 20 })
  limit: number;

  @ApiProperty({ example: 2 })
  totalPages: number;
}
