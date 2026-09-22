import { Injectable } from '@nestjs/common';
import { DataSource, type EntityManager, IsNull } from 'typeorm';
import { CompanyProfile } from './entities/company-profile.entity.js';
import { RefreshToken } from './entities/refresh-token.entity.js';
import { StudentProfile } from './entities/student-profile.entity.js';
import { User } from './entities/user.entity.js';
import { UserRole } from './user-role.js';

export interface NewUser {
  email: string;
  passwordHash: string;
  role: UserRole;
}

export interface StoredRefreshToken {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
}

export interface RefreshRotation {
  currentHash: string;
  nextHash: string;
  expiresAt: Date;
}

export interface ActiveSessionUser {
  userId: string;
  role: UserRole;
}

@Injectable()
export class AuthRepository {
  constructor(private readonly dataSource: DataSource) {}

  findByEmail(email: string): Promise<User | null> {
    return this.dataSource.getRepository(User).findOne({ where: { email } });
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

  async saveRefreshToken(input: StoredRefreshToken): Promise<void> {
    const tokens = this.dataSource.getRepository(RefreshToken);
    await tokens.save(tokens.create(input));
  }

  async rotateRefreshToken(
    input: RefreshRotation,
  ): Promise<ActiveSessionUser | null> {
    return this.dataSource.transaction(async (manager) => {
      const current = await manager.findOne(RefreshToken, {
        where: { tokenHash: input.currentHash, revokedAt: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (!current || current.expiresAt.getTime() <= Date.now()) {
        return null;
      }

      const user = await manager.findOne(User, { where: { id: current.userId } });
      if (!user) {
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
      return { userId: user.id, role: user.role };
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
    await this.dataSource.getRepository(RefreshToken).update(
      { userId, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }
}
