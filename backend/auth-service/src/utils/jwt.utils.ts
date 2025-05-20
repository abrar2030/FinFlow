import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { TokenPayload } from '../types/auth.types';

// Hash password
export const hashPassword = async (password: string): Promise<string> => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

// Compare password with hash
export const comparePassword = async (password: string, hash: string): Promise<boolean> => {
  return bcrypt.compare(password, hash);
};

// Generate JWT token
export const generateToken = (
  userId: string,
  role: string,
  expiresIn: string = process.env.JWT_EXPIRES_IN || '1h'
): string => {
  return jwt.sign(
    { sub: userId, role },
    process.env.JWT_SECRET || 'default_jwt_secret',
    { expiresIn }
  );
};

// Verify JWT token
export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(
    token,
    process.env.JWT_SECRET || 'default_jwt_secret'
  ) as TokenPayload;
};

export default {
  hashPassword,
  comparePassword,
  generateToken,
  verifyToken
};
