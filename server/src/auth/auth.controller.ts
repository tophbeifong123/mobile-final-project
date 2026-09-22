import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { type AuthUser } from './auth-user.js';
import { CurrentUser } from './current-user.decorator.js';
import { AuthSessionDto } from './dto/auth-session.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { JwtAuthGuard } from './jwt-auth.guard.js';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'สมัครบัญชีและเลือก role' })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({ status: 201, type: AuthSessionDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้องหรือ role ไม่ถูกต้อง' })
  @ApiResponse({ status: 409, description: 'อีเมลซ้ำ' })
  register(@Body() dto: RegisterDto): Promise<AuthSessionDto> {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'เข้าสู่ระบบ' })
  @ApiBody({ type: LoginDto })
  @ApiResponse({ status: 200, type: AuthSessionDto })
  @ApiResponse({ status: 401, description: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' })
  login(@Body() dto: LoginDto): Promise<AuthSessionDto> {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'หมุน refresh token' })
  @ApiBody({ type: RefreshDto })
  @ApiResponse({ status: 200, type: AuthSessionDto })
  @ApiResponse({ status: 401, description: 'refresh token ใช้ไม่ได้' })
  refresh(@Body() dto: RefreshDto): Promise<AuthSessionDto> {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'เพิกถอน refresh token ของผู้ที่ login อยู่' })
  @ApiResponse({ status: 204, description: 'เพิกถอนแล้ว' })
  @ApiResponse({ status: 401, description: 'access token ไม่ถูกต้อง' })
  logout(@CurrentUser() user: AuthUser): Promise<void> {
    return this.authService.logout(user.userId);
  }
}
