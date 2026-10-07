import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { GoogleIdTokenVerifier } from './google-token-verifier.js';

describe('GoogleIdTokenVerifier', () => {
  const config = {
    get: vi.fn(() => 'android-client-id, web-client-id'),
  };
  let verifier: GoogleIdTokenVerifier;
  let verifyIdToken: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    vi.restoreAllMocks();
    config.get.mockReturnValue('android-client-id, web-client-id');
    verifyIdToken = vi.spyOn(OAuth2Client.prototype, 'verifyIdToken');
    verifier = new GoogleIdTokenVerifier(config as unknown as ConfigService);
  });

  it('verifies the signature and only accepts configured token audiences', async () => {
    verifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub',
        email: 'student@example.com',
        email_verified: true,
        name: 'Google Student',
      }),
    } as Awaited<ReturnType<OAuth2Client['verifyIdToken']>>);

    await expect(verifier.verify('signed-id-token')).resolves.toEqual({
      subject: 'google-sub',
      email: 'student@example.com',
      name: 'Google Student',
    });
    expect(verifyIdToken).toHaveBeenCalledWith({
      idToken: 'signed-id-token',
      audience: ['android-client-id', 'web-client-id'],
    });
  });

  it('rejects a token that fails Google verification', async () => {
    verifyIdToken.mockRejectedValue(new Error('wrong audience or expired'));

    await expect(verifier.verify('bad-id-token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('uses an empty profile name when Google omits the optional claim', async () => {
    verifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub',
        email: 'student@example.com',
        email_verified: true,
      }),
    } as Awaited<ReturnType<OAuth2Client['verifyIdToken']>>);

    await expect(verifier.verify('signed-id-token')).resolves.toMatchObject({
      name: '',
    });
  });

  it('rejects a verified token without verified email identity fields', async () => {
    verifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub',
        email: 'student@example.com',
        email_verified: false,
      }),
    } as Awaited<ReturnType<OAuth2Client['verifyIdToken']>>);

    await expect(verifier.verify('signed-id-token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('fails closed when no accepted audience is configured', async () => {
    config.get.mockReturnValue('');

    await expect(verifier.verify('signed-id-token')).rejects.toThrow(
      'GOOGLE_ALLOWED_CLIENT_IDS is required',
    );
    expect(verifyIdToken).not.toHaveBeenCalled();
  });
});
