import { User } from '@prisma/client';
import jwt from 'jsonwebtoken';
import userService from './user.service';
import { comparePassword } from '../utils/password.utils';
import { LoginDTO, RegisterDTO, RefreshTokenDTO, AuthTokens, TokenPayload } from '../types/auth.types';
import { UserCreateInput } from '../types/user.types';
import { hashPassword } from '../utils/password.utils';
import { logger } from '../utils/logger';
import { sendMessage } from '../config/kafka';

class AuthService {
  // Register a new user
  async register(registerDto: RegisterDTO): Promise<User & AuthTokens> {
    try {
      // Hash password
      const hashedPassword = await hashPassword(registerDto.password);

      // Create user
      const userData: UserCreateInput = {
        email: registerDto.email,
        hashedPassword
      };

      const user = await userService.create(userData);

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.role);
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userService.updateRefreshToken(user.id, refreshToken);

      // Publish user_created event to Kafka
      await this.publishUserCreatedEvent(user);

      // Return user data and tokens
      return {
        ...user,
        accessToken,
        refreshToken
      };
    } catch (error) {
      logger.error(`Error registering user: ${error}`);
      throw error;
    }
  }

  // Login user
  async login(loginDto: LoginDTO): Promise<User & AuthTokens> {
    try {
      // Find user by email
      const user = await userService.findByEmail(loginDto.email);
      if (!user) {
        const error = new Error('Invalid credentials');
        error.name = 'UnauthorizedError';
        throw error;
      }

      // Verify password
      const isPasswordValid = await comparePassword(loginDto.password, user.hashedPassword);
      if (!isPasswordValid) {
        const error = new Error('Invalid credentials');
        error.name = 'UnauthorizedError';
        throw error;
      }

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.role);
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userService.updateRefreshToken(user.id, refreshToken);

      // Return user data and tokens
      return {
        ...user,
        accessToken,
        refreshToken
      };
    } catch (error) {
      logger.error(`Error logging in user: ${error}`);
      throw error;
    }
  }

  // Refresh access token
  async refreshToken(refreshTokenDto: RefreshTokenDTO): Promise<AuthTokens> {
    try {
      const { refreshToken } = refreshTokenDto;

      // Verify refresh token
      const decoded = jwt.verify(
        refreshToken,
        process.env.JWT_SECRET || 'default_jwt_secret'
      ) as TokenPayload;

      // Find user by ID
      const user = await userService.findById(decoded.sub);
      if (!user || user.refreshToken !== refreshToken) {
        const error = new Error('Invalid refresh token');
        error.name = 'UnauthorizedError';
        throw error;
      }

      // Generate new access token
      const accessToken = this.generateAccessToken(user.id, user.role);

      // Return new access token
      return { accessToken };
    } catch (error) {
      logger.error(`Error refreshing token: ${error}`);
      
      if (error instanceof jwt.JsonWebTokenError) {
        const customError = new Error('Invalid refresh token');
        customError.name = 'UnauthorizedError';
        throw customError;
      }
      
      throw error;
    }
  }

  // Logout user
  async logout(userId: string): Promise<void> {
    try {
      // Clear refresh token in database
      await userService.updateRefreshToken(userId, null);
    } catch (error) {
      logger.error(`Error logging out user: ${error}`);
      throw error;
    }
  }

  // Helper method to generate access token
  private generateAccessToken(userId: string, role: string): string {
    return jwt.sign(
      { sub: userId, role },
      process.env.JWT_SECRET || 'default_jwt_secret',
      { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
    );
  }

  // Helper method to generate refresh token
  private generateRefreshToken(userId: string, role: string): string {
    return jwt.sign(
      { sub: userId, role },
      process.env.JWT_SECRET || 'default_jwt_secret',
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
    );
  }

  // Publish user_created event to Kafka
  private async publishUserCreatedEvent(user: User): Promise<void> {
    try {
      await sendMessage('user_created', {
        id: user.id,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt
      });
    } catch (error) {
      logger.error(`Error publishing user_created event: ${error}`);
      // Don't throw error, just log it
    }
  }
}

export default new AuthService();
