import { Injectable } from '@nestjs/common';
import { DataSource, type EntityManager, IsNull } from 'typeorm';
import { CompanyProfile } from './entities/company-profile.entity.js';
import { AuthIdentity } from './entities/auth-identity.entity.js';
import { PasswordResetToken } from './entities/password-reset-token.entity.js';
import { RefreshToken } from './entities/refresh-token.entity.js';
import { StudentProfile } from './entities/student-profile.entity.js';
import { User } from './entities/user.entity.js';
import { UserRole } from './user-role.js';

export interface NewUser {
  email: string;
  passwordHash: string | null;
  role: UserRole;
}

export interface NewGoogleUser {
  email: string;
  providerSubject: string;
  role: UserRole;
}

export interface StoredRefreshToken {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  tokenVersion: number;
}

export interface RefreshRotation {
  currentHash: string;
  nextHash: string;
  expiresAt: Date;
}

export interface ActiveSessionUser {
  userId: string;
  role: UserRole;
  tokenVersion: number;
}

export type PasswordResetConsumption =
  { status: 'consumed'; email: string } | { status: 'reused' } | null;

@Injectable()
export class AuthRepository {
  constructor(private readonly dataSource: DataSource) {}

  findByEmail(email: string): Promise<User | null> {
    return this.dataSource.getRepository(User).findOne({ where: { email } });
  }

  findByGoogleSubject(providerSubject: string): Promise<User | null> {
    return this.dataSource
      .getRepository(User)
      .createQueryBuilder('user')
      .innerJoin(
        AuthIdentity,
        'identity',
        'identity.user_id = user.id AND identity.provider = :provider AND identity.provider_subject = :providerSubject',
        { provider: 'google', providerSubject },
      )
      .getOne();
  }

  async createGoogleUserWithProfile(input: NewGoogleUser): Promise<User> {
    return this.dataSource.transaction(async (manager) => {
      const user = await manager.save(
        manager.create(User, {
          email: input.email,
          passwordHash: null,
          role: input.role,
        }),
      );
      await manager.save(
        manager.create(AuthIdentity, {
          userId: user.id,
          provider: 'google',
          providerSubject: input.providerSubject,
        }),
      );
      await this.saveEmptyProfile(manager, user.id, input.role);
      return user;
    });
  }

  findById(id: string): Promise<User | null> {
    return this.dataSource.getRepository(User).findOne({ where: { id } });
  }

  async createUserWithProfile(input: NewUser): Promise<User> {
    return this.dataSource.transaction(async (manager) => {
      const user = await manager.save(
        manager.create(User, {
          email: input.email,
          passwordHash: input.passwordHash,
          role: input.role,
        }),
      );
      await this.saveEmptyProfile(manager, user.id, input.role);
      return user;
    });
  }

  async saveRefreshToken(input: StoredRefreshToken): Promise<boolean> {
    return this.dataSource.transaction(async (manager) => {
      const user = await manager.findOne(User, {
        where: { id: input.userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!user || user.tokenVersion !== input.tokenVersion) {
        return false;
      }
      await manager.save(
        manager.create(RefreshToken, {
          userId: input.userId,
          tokenHash: input.tokenHash,
          expiresAt: input.expiresAt,
        }),
      );
      return true;
    });
  }

  async rotateRefreshToken(
    input: RefreshRotation,
  ): Promise<ActiveSessionUser | null> {
    return this.dataSource.transaction(async (manager) => {
      const candidate = await manager.findOne(RefreshToken, {
        where: { tokenHash: input.currentHash },
      });
      if (!candidate) {
        return null;
      }
      // Always lock the user first, also used by recovery/session creation.
      const user = await manager.findOne(User, {
        where: { id: candidate.userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!user) {
        return null;
      }
      const current = await manager.findOne(RefreshToken, {
        where: { tokenHash: input.currentHash, revokedAt: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (!current || current.expiresAt.getTime() <= Date.now()) {
        return null;
      }

      await manager.update(
        RefreshToken,
        { id: current.id },
        { revokedAt: new Date() },
      );
      await manager.save(
        manager.create(RefreshToken, {
          userId: user.id,
          tokenHash: input.nextHash,
          expiresAt: input.expiresAt,
        }),
      );
      return {
        userId: user.id,
        role: user.role,
        tokenVersion: user.tokenVersion,
      };
    });
  }

  async replacePasswordResetToken(
    input: Omit<StoredRefreshToken, 'tokenVersion'>,
  ): Promise<boolean> {
    return this.dataSource.transaction(async (manager) => {
      const user = await manager.findOne(User, {
        where: { id: input.userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!user) {
        return false;
      }
      const previous = await manager.findOne(PasswordResetToken, {
        where: { userId: input.userId },
      });
      if (previous && previous.createdAt.getTime() > Date.now() - 60_000) {
        return false;
      }
      await manager.delete(PasswordResetToken, { userId: input.userId });
      await manager.save(manager.create(PasswordResetToken, input));
      return true;
    });
  }

  findPasswordResetToken(
    tokenHash: string,
  ): Promise<PasswordResetToken | null> {
    return this.dataSource
      .getRepository(PasswordResetToken)
      .findOne({ where: { tokenHash } });
  }

  async deletePasswordResetToken(tokenHash: string): Promise<void> {
    await this.dataSource
      .getRepository(PasswordResetToken)
      .delete({ tokenHash });
  }

  async consumePasswordResetToken(
    tokenHash: string,
    passwordHash: string,
    isReusedPassword: (currentHash: string) => Promise<boolean>,
  ): Promise<PasswordResetConsumption> {
    return this.dataSource.transaction(async (manager) => {
      const candidate = await manager.findOne(PasswordResetToken, {
        where: { tokenHash },
      });
      if (!candidate) {
        return null;
      }
      const user = await manager.findOne(User, {
        where: { id: candidate.userId },
        lock: { mode: 'pessimistic_write' },
      });
      // Ensure the owner still exists while holding the user lock.
      if (!user) {
        return null;
      }
      const token = await manager.findOne(PasswordResetToken, {
        where: { tokenHash },
        lock: { mode: 'pessimistic_write' },
      });
      if (!token || token.expiresAt.getTime() <= Date.now()) {
        return null;
      }
      // Compare against the current hash while the user is locked. A rejected
      // password leaves both the one-use token and existing sessions intact.
      if (user.passwordHash && (await isReusedPassword(user.passwordHash))) {
        return { status: 'reused' };
      }
      await manager.update(
        User,
        { id: user.id },
        {
          passwordHash,
          tokenVersion: () => '"token_version" + 1',
        },
      );
      await manager.update(
        RefreshToken,
        { userId: user.id, revokedAt: IsNull() },
        { revokedAt: new Date() },
      );
      await manager.delete(PasswordResetToken, { userId: user.id });
      return { status: 'consumed', email: user.email };
    });
  }

  private async saveEmptyProfile(
    manager: EntityManager,
    userId: string,
    role: UserRole,
  ): Promise<void> {
    if (role === UserRole.Student) {
      await manager.save(
        manager.create(StudentProfile, {
          userId,
          fullName: '',
          university: '',
          major: '',
          skills: [],
        }),
      );
      return;
    }

    if (role === UserRole.Company) {
      await manager.save(
        manager.create(CompanyProfile, {
          userId,
          name: '',
          businessType: '',
          description: '',
        }),
      );
      return;
    }

    throw new Error('role ไม่ถูกต้อง');
  }

  async revokeAllForUser(userId: string): Promise<void> {
    await this.dataSource
      .getRepository(RefreshToken)
      .update({ userId, revokedAt: IsNull() }, { revokedAt: new Date() });
  }
}
