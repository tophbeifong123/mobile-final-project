import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { MajorDto } from './dto/major.dto.js';
import { MajorsService } from './majors.service.js';

@ApiTags('Majors')
@Controller('majors')
export class MajorsController {
  constructor(private readonly service: MajorsService) {}

  @Get()
  @ApiOperation({ summary: 'ค้นหาคำแนะนำสาขา' })
  @ApiQuery({ name: 'q', required: false, maxLength: 100, example: 'วิศว' })
  @ApiResponse({ status: 200, type: MajorDto, isArray: true })
  @ApiResponse({ status: 400, description: 'คำค้นหายาวเกินไป' })
  search(@Query('q') query?: string): Promise<MajorDto[]> {
    return this.service.search(query ?? '');
  }
}
