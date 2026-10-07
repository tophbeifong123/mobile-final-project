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
  ApiExtraModels,
  ApiOperation,
  ApiResponse,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { ThrottlerGuard, Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service.js';
import { GoogleAuthDto } from './dto/google-auth.dto.js';
import { GoogleLinkDto } from './dto/google-link.dto.js';
import { GoogleRoleRequiredDto } from './dto/google-role-required.dto.js';
import { type AuthUser } from './auth-user.js';
import { CurrentUser } from './current-user.decorator.js';
import { AuthSessionDto } from './dto/auth-session.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { JwtAuthGuard } from './jwt-auth.guard.js';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import { PasswordRecoveryResponseDto } from './dto/password-recovery-response.dto.js';
import { PasswordRecoveryService } from './password-recovery.service.js';
import { PasswordRecoveryRateLimitGuard } from './password-recovery-rate-limit.guard.js';

@ApiTags('Auth')
@ApiExtraModels(AuthSessionDto, GoogleRoleRequiredDto)
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly recovery: PasswordRecoveryService,
  ) {}

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @UseGuards(PasswordRecoveryRateLimitGuard)
  @ApiOperation({ summary: 'ขอลิงก์รีเซ็ตรหัสผ่านด้วยอีเมลที่ใช้สมัครสมาชิก ไม่จำกัดโดเมน' })
  @ApiBody({ type: ForgotPasswordDto })
  @ApiResponse({ status: 200, type: PasswordRecoveryResponseDto })
  @ApiResponse({ status: 400, description: 'รูปแบบอีเมลไม่ถูกต้อง' })
  @ApiResponse({ status: 429, description: 'ส่งคำขอมากเกินไป' })
  @ApiResponse({ status: 503, description: 'ระบบส่งอีเมลยังไม่พร้อมใช้งาน' })
  forgotPassword(@Body() dto: ForgotPasswordDto): Promise<PasswordRecoveryResponseDto> {
    return this.recovery.forgotPassword(dto);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @UseGuards(PasswordRecoveryRateLimitGuard)
  @ApiOperation({ summary: 'ตั้งรหัสผ่านใหม่ด้วยลิงก์ที่ใช้ได้ครั้งเดียวภายใน 15 นาที' })
  @ApiBody({ type: ResetPasswordDto })
  @ApiResponse({ status: 200, type: PasswordRecoveryResponseDto })
  @ApiResponse({ status: 400, description: 'ข้อมูลไม่ถูกต้อง ลิงก์ใช้ไม่ได้/หมดอายุ หรือบัญชีไม่มีอยู่แล้ว' })
  @ApiResponse({ status: 409, description: 'รหัสผ่านใหม่ซ้ำกับรหัสผ่านเดิม ลิงก์ยังใช้ได้สำหรับการลองใหม่' })
  @ApiResponse({ status: 429, description: 'ส่งคำขอมากเกินไป' })
  resetPassword(@Body() dto: ResetPasswordDto): Promise<PasswordRecoveryResponseDto> {
    return this.recovery.resetPassword(dto);
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'สมัครบัญชีและเลือก role' })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({ status: 201, type: AuthSessionDto })
  @ApiResponse({
    status: 400,
    description: 'ข้อมูลไม่ถูกต้องหรือ role ไม่ถูกต้อง',
  })
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

  @Post('google')
  @HttpCode(HttpStatus.OK)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({ summary: 'สมัครหรือเข้าสู่ระบบด้วย Google ID token' })
  @ApiBody({ type: GoogleAuthDto })
  @ApiResponse({
    status: 200,
    description: 'Auth session, or { code: role_required } for a new account',
    schema: {
      oneOf: [
        { $ref: getSchemaPath(AuthSessionDto) },
        { $ref: getSchemaPath(GoogleRoleRequiredDto) },
      ],
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Google ID token invalid or not verified',
  })
  @ApiResponse({
    status: 409,
    description:
      'Email belongs to an existing account. password_link_required means the user must prove the password before Google is linked.',
  })
  @ApiResponse({ status: 429, description: 'Too many Google login attempts' })
  google(
    @Body() dto: GoogleAuthDto,
  ): Promise<AuthSessionDto | GoogleRoleRequiredDto> {
    return this.authService.googleAuth(dto);
  }

  @Post('google/link')
  @HttpCode(HttpStatus.OK)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({
    summary: 'ผูก Google เข้ากับบัญชีรหัสผ่านเดิมหลังตรวจรหัสผ่าน',
  })
  @ApiBody({ type: GoogleLinkDto })
  @ApiResponse({ status: 200, type: AuthSessionDto })
  @ApiResponse({ status: 401, description: 'รหัสผ่านไม่ถูกต้องหรือไม่พบบัญชีรหัสผ่าน' })
  @ApiResponse({
    status: 409,
    description: 'Google นี้ถูกใช้แล้ว หรือบัญชีผูกกับ Google อื่นอยู่แล้ว',
  })
  @ApiResponse({ status: 429, description: 'Too many Google link attempts' })
  linkGoogle(@Body() dto: GoogleLinkDto): Promise<AuthSessionDto> {
    return this.authService.linkGooglePasswordAccount(dto);
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
