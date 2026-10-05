import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ProvinceDto } from './dto/province.dto.js';
import { ProvincesService } from './provinces.service.js';

@ApiTags('Provinces')
@Controller('provinces')
export class ProvincesController {
  constructor(private readonly provincesService: ProvincesService) {}

  @Get()
  @ApiOperation({
    summary: 'รายการจังหวัดไทย 77 แห่งสำหรับเลือกจังหวัดและเปิดแผนที่',
  })
  @ApiResponse({ status: 200, type: [ProvinceDto] })
  list(): Promise<ProvinceDto[]> {
    return this.provincesService.list();
  }
}
