import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

export const GOOGLE_TOKEN_VERIFIER = Symbol('GOOGLE_TOKEN_VERIFIER');

export interface VerifiedGoogleIdentity {
  subject: string;
  email: string;
  name: string;
}

export interface GoogleTokenVerifier {
  verify(idToken: string): Promise<VerifiedGoogleIdentity>;
}

@Injectable()
export class GoogleIdTokenVerifier implements GoogleTokenVerifier {
  private readonly client = new OAuth2Client();

  constructor(private readonly config: ConfigService) {}

  async verify(idToken: string): Promise<VerifiedGoogleIdentity> {
    const audiences = (
      this.config.get<string>('GOOGLE_ALLOWED_CLIENT_IDS') ?? ''
    )
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
    if (audiences.length === 0) {
      throw new Error('GOOGLE_ALLOWED_CLIENT_IDS is required for Google login');
    }

    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: audiences,
      });
      const payload = ticket.getPayload();
      if (!payload?.sub || !payload.email || payload.email_verified !== true) {
        throw new UnauthorizedException('Google account could not be verified');
      }
      return {
        subject: payload.sub,
        email: payload.email,
        name: typeof payload.name === 'string' ? payload.name : '',
      };
    } catch {
      throw new UnauthorizedException('Google ID token is invalid');
    }
  }
}
