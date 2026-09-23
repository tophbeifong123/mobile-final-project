import { ApiProperty } from '@nestjs/swagger';
import { JobFeedItemDto } from './job-feed-item.dto.js';

export class PaginatedJobsDto {
  @ApiProperty({ type: [JobFeedItemDto] })
  items: JobFeedItemDto[];

  @ApiProperty({ example: 100 })
  total: number;

  @ApiProperty({ example: 1 })
  page: number;

  @ApiProperty({ example: 20 })
  limit: number;

  @ApiProperty({ example: 5 })
  totalPages: number;
}
