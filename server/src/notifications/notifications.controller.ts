import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { type AuthUser } from '../auth/auth-user.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { NotificationItemDto } from './dto/notification-item.dto.js';
import { NotificationsService } from './notifications.service.js';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'รายการแจ้งเตือนของนักศึกษา' })
  @ApiResponse({
    status: 200,
    type: [NotificationItemDto],
    description: 'รายการแจ้งเตือนเรียงจากใหม่สุดไปเก่าสุด',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบโปรไฟล์นักศึกษา' })
  list(@CurrentUser() user: AuthUser): Promise<NotificationItemDto[]> {
    return this.notificationsService.list(user);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'ทำเครื่องหมายว่าอ่านแจ้งเตือนแล้ว' })
  @ApiParam({ name: 'id', format: 'uuid', description: 'รหัสแจ้งเตือน' })
  @ApiResponse({
    status: 200,
    type: NotificationItemDto,
    description: 'อัปเดตสถานะเป็นอ่านแล้ว',
  })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  @ApiResponse({ status: 403, description: 'เฉพาะนักศึกษา' })
  @ApiResponse({ status: 404, description: 'ไม่พบการแจ้งเตือน' })
  markRead(
    @CurrentUser() user: AuthUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<NotificationItemDto> {
    return this.notificationsService.markAsRead(user, id);
  }
}
