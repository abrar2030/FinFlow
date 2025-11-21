import { Role } from "@prisma/client";

export interface UserPayload {
  id: string;
  email: string;
  role: Role;
}

export interface TokenPayload {
  sub: string;
  role: Role;
  iat?: number;
  exp?: number;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken?: string;
}

export interface RegisterDTO {
  email: string;
  password: string;
}

export interface LoginDTO {
  email: string;
  password: string;
}

export interface RefreshTokenDTO {
  refreshToken: string;
}
