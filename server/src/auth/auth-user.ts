import { UserRole } from './user-role.js';

export interface AuthUser {
  userId: string;
  role: UserRole;
}
