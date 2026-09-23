import { ApiProperty } from '@nestjs/swagger';

export class NotificationItemDto {
  @ApiProperty({ format: 'uuid', description: 'รหัสแจ้งเตือน' })
  id: string;

  @ApiProperty({ format: 'uuid', description: 'รหัสใบสมัครที่เกี่ยวข้อง' })
  applicationId: string;

  @ApiProperty({ description: 'ข้อความแจ้งเตือนสถานะ' })
  message: string;

  @ApiProperty({
    format: 'date-time',
    nullable: true,
    description: 'เวลาที่อ่านแจ้งเตือน (null แปลว่ายังไม่อ่าน)',
  })
  readAt: string | null;

  @ApiProperty({
    format: 'date-time',
    description: 'เวลาที่ได้รับแจ้งเตือน',
  })
  createdAt: string;
}
