import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UniversityDto } from './dto/university.dto.js';
import { UniversitiesService } from './universities.service.js';

@ApiTags('Universities')
@Controller('universities')
export class UniversitiesController {
  constructor(private readonly service: UniversitiesService) {}

  @Get()
  @ApiOperation({ summary: 'ค้นหาสถาบันอุดมศึกษาไทยด้วยชื่อหรือชื่อเรียกอื่น' })
  @ApiQuery({ name: 'q', required: false, maxLength: 100, example: 'PSU' })
  @ApiResponse({ status: 200, type: UniversityDto, isArray: true })
  @ApiResponse({ status: 400, description: 'คำค้นหายาวเกินไป' })
  search(@Query('q') query?: string): Promise<UniversityDto[]> {
    return this.service.search(query ?? '');
  }
}
