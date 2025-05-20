import { User } from '@prisma/client';
import jwt from 'jsonwebtoken';
import userService from './user.service';
import { comparePassword } from '../utils/password.utils';
import { 
  LoginDTO, 
  RegisterDTO, 
  RefreshTokenDTO, 
  AuthTokens, 
  TokenPayload,
  OAuthProviderType,
  OAuthLoginDTO
} from '../types/auth.types';
import { UserCreateInput } from '../types/user.types';
import { hashPassword } from '../utils/password.utils';
import { logger } from '../utils/logger';
import { sendMessage } from '../config/kafka';
import axios from 'axios';
import crypto from 'crypto';
import { auditLog } from '../utils/audit.utils';

class AuthService {
  // Register a new user
  async register(registerDto: RegisterDTO): Promise<User & AuthTokens> {
    try {
      // Validate password strength
      this.validatePasswordStrength(registerDto.password);
      
      // Hash password
      const hashedPassword = await hashPassword(registerDto.password);

      // Create user
      const userData: UserCreateInput = {
        email: registerDto.email,
        hashedPassword,
        firstName: registerDto.firstName,
        lastName: registerDto.lastName
      };

      const user = await userService.create(userData);

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.role);
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userService.updateRefreshToken(user.id, refreshToken);

      // Publish user_created event to Kafka
      await this.publishUserCreatedEvent(user);
      
      // Log the registration event
      await auditLog({
        action: 'USER_REGISTER',
        userId: user.id,
        resourceType: 'USER',
        resourceId: user.id,
        metadata: {
          email: user.email,
          ipAddress: registerDto.ipAddress
        }
      });

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
        // Log failed login attempt
        await auditLog({
          action: 'LOGIN_FAILED',
          resourceType: 'USER',
          resourceId: user.id,
          metadata: {
            email: user.email,
            reason: 'INVALID_PASSWORD',
            ipAddress: loginDto.ipAddress
          }
        });
        
        const error = new Error('Invalid credentials');
        error.name = 'UnauthorizedError';
        throw error;
      }

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.role);
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userService.updateRefreshToken(user.id, refreshToken);
      
      // Log successful login
      await auditLog({
        action: 'LOGIN_SUCCESS',
        userId: user.id,
        resourceType: 'USER',
        resourceId: user.id,
        metadata: {
          email: user.email,
          ipAddress: loginDto.ipAddress
        }
      });

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
  
  // OAuth login/registration
  async oauthLogin(oauthLoginDto: OAuthLoginDTO): Promise<User & AuthTokens> {
    try {
      const { provider, code, redirectUri, ipAddress } = oauthLoginDto;
      
      // Get user profile from OAuth provider
      const profile = await this.getOAuthUserProfile(provider, code, redirectUri);
      
      if (!profile || !profile.email) {
        const error = new Error('Failed to get user profile from OAuth provider');
        error.name = 'OAuthError';
        throw error;
      }
      
      // Check if user exists
      let user = await userService.findByEmail(profile.email);
      
      if (!user) {
        // Create new user if not exists
        const userData: UserCreateInput = {
          email: profile.email,
          firstName: profile.firstName || '',
          lastName: profile.lastName || '',
          oauthProvider: provider,
          oauthId: profile.id
        };
        
        user = await userService.create(userData);
        
        // Publish user_created event to Kafka
        await this.publishUserCreatedEvent(user);
      } else if (!user.oauthProvider || user.oauthProvider !== provider) {
        // Link existing user with OAuth provider
        user = await userService.update(user.id, {
          oauthProvider: provider,
          oauthId: profile.id
        });
      }
      
      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.role);
      const refreshToken = this.generateRefreshToken(user.id, user.role);
      
      // Save refresh token to database
      await userService.updateRefreshToken(user.id, refreshToken);
      
      // Log OAuth login
      await auditLog({
        action: 'OAUTH_LOGIN',
        userId: user.id,
        resourceType: 'USER',
        resourceId: user.id,
        metadata: {
          email: user.email,
          provider,
          ipAddress
        }
      });
      
      // Return user data and tokens
      return {
        ...user,
        accessToken,
        refreshToken
      };
    } catch (error) {
      logger.error(`Error in OAuth login: ${error}`);
      throw error;
    }
  }

  // Refresh access token
  async refreshToken(refreshTokenDto: RefreshTokenDTO): Promise<AuthTokens> {
    try {
      const { refreshToken, ipAddress } = refreshTokenDto;

      // Verify refresh token
      const decoded = jwt.verify(
        refreshToken,
        process.env.JWT_SECRET || 'default_jwt_secret'
      ) as TokenPayload;

      // Find user by ID
      const user = await userService.findById(decoded.sub);
      if (!user || user.refreshToken !== refreshToken) {
        // Log invalid refresh token attempt
        await auditLog({
          action: 'TOKEN_REFRESH_FAILED',
          resourceType: 'TOKEN',
          metadata: {
            userId: decoded.sub,
            reason: 'INVALID_REFRESH_TOKEN',
            ipAddress
          }
        });
        
        const error = new Error('Invalid refresh token');
        error.name = 'UnauthorizedError';
        throw error;
      }

      // Generate new access token
      const accessToken = this.generateAccessToken(user.id, user.role);
      
      // Log successful token refresh
      await auditLog({
        action: 'TOKEN_REFRESH_SUCCESS',
        userId: user.id,
        resourceType: 'TOKEN',
        metadata: {
          ipAddress
        }
      });

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
  async logout(userId: string, ipAddress?: string): Promise<void> {
    try {
      // Clear refresh token in database
      await userService.updateRefreshToken(userId, null);
      
      // Log logout
      await auditLog({
        action: 'LOGOUT',
        userId,
        resourceType: 'USER',
        resourceId: userId,
        metadata: { ipAddress }
      });
    } catch (error) {
      logger.error(`Error logging out user: ${error}`);
      throw error;
    }
  }
  
  // Change password
  async changePassword(userId: string, currentPassword: string, newPassword: string, ipAddress?: string): Promise<void> {
    try {
      // Find user
      const user = await userService.findById(userId);
      if (!user) {
        const error = new Error('User not found');
        error.name = 'NotFoundError';
        throw error;
      }
      
      // Verify current password
      const isPasswordValid = await comparePassword(currentPassword, user.hashedPassword);
      if (!isPasswordValid) {
        // Log failed password change attempt
        await auditLog({
          action: 'PASSWORD_CHANGE_FAILED',
          userId,
          resourceType: 'USER',
          resourceId: userId,
          metadata: {
            reason: 'INVALID_CURRENT_PASSWORD',
            ipAddress
          }
        });
        
        const error = new Error('Current password is incorrect');
        error.name = 'UnauthorizedError';
        throw error;
      }
      
      // Validate new password strength
      this.validatePasswordStrength(newPassword);
      
      // Hash new password
      const hashedPassword = await hashPassword(newPassword);
      
      // Update user password
      await userService.update(userId, { hashedPassword });
      
      // Invalidate all refresh tokens
      await userService.updateRefreshToken(userId, null);
      
      // Log password change
      await auditLog({
        action: 'PASSWORD_CHANGED',
        userId,
        resourceType: 'USER',
        resourceId: userId,
        metadata: { ipAddress }
      });
    } catch (error) {
      logger.error(`Error changing password: ${error}`);
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
  
  // Helper method to validate password strength
  private validatePasswordStrength(password: string): void {
    // Password must be at least 8 characters long
    if (password.length < 8) {
      throw new Error('Password must be at least 8 characters long');
    }
    
    // Password must contain at least one uppercase letter
    if (!/[A-Z]/.test(password)) {
      throw new Error('Password must contain at least one uppercase letter');
    }
    
    // Password must contain at least one lowercase letter
    if (!/[a-z]/.test(password)) {
      throw new Error('Password must contain at least one lowercase letter');
    }
    
    // Password must contain at least one number
    if (!/[0-9]/.test(password)) {
      throw new Error('Password must contain at least one number');
    }
    
    // Password must contain at least one special character
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
      throw new Error('Password must contain at least one special character');
    }
  }
  
  // Helper method to get user profile from OAuth provider
  private async getOAuthUserProfile(
    provider: OAuthProviderType,
    code: string,
    redirectUri: string
  ): Promise<{ id: string; email: string; firstName?: string; lastName?: string }> {
    try {
      switch (provider) {
        case OAuthProviderType.GOOGLE:
          return await this.getGoogleUserProfile(code, redirectUri);
        case OAuthProviderType.GITHUB:
          return await this.getGithubUserProfile(code, redirectUri);
        case OAuthProviderType.MICROSOFT:
          return await this.getMicrosoftUserProfile(code, redirectUri);
        default:
          throw new Error(`Unsupported OAuth provider: ${provider}`);
      }
    } catch (error) {
      logger.error(`Error getting OAuth user profile: ${error}`);
      throw error;
    }
  }
  
  // Get Google user profile
  private async getGoogleUserProfile(
    code: string,
    redirectUri: string
  ): Promise<{ id: string; email: string; firstName?: string; lastName?: string }> {
    try {
      // Exchange authorization code for tokens
      const tokenResponse = await axios.post('https://oauth2.googleapis.com/token', {
        code,
        client_id: process.env.GOOGLE_CLIENT_ID,
        client_secret: process.env.GOOGLE_CLIENT_SECRET,
        redirect_uri: redirectUri,
        grant_type: 'authorization_code'
      });
      
      const { access_token } = tokenResponse.data;
      
      // Get user profile
      const profileResponse = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${access_token}` }
      });
      
      const { sub, email, given_name, family_name } = profileResponse.data;
      
      return {
        id: sub,
        email,
        firstName: given_name,
        lastName: family_name
      };
    } catch (error) {
      logger.error(`Error getting Google user profile: ${error}`);
      throw error;
    }
  }
  
  // Get GitHub user profile
  private async getGithubUserProfile(
    code: string,
    redirectUri: string
  ): Promise<{ id: string; email: string; firstName?: string; lastName?: string }> {
    try {
      // Exchange authorization code for access token
      const tokenResponse = await axios.post(
        'https://github.com/login/oauth/access_token',
        {
          client_id: process.env.GITHUB_CLIENT_ID,
          client_secret: process.env.GITHUB_CLIENT_SECRET,
          code,
          redirect_uri: redirectUri
        },
        {
          headers: { Accept: 'application/json' }
        }
      );
      
      const { access_token } = tokenResponse.data;
      
      // Get user profile
      const profileResponse = await axios.get('https://api.github.com/user', {
        headers: { Authorization: `token ${access_token}` }
      });
      
      // Get user email (GitHub might not include email in profile)
      const emailResponse = await axios.get('https://api.github.com/user/emails', {
        headers: { Authorization: `token ${access_token}` }
      });
      
      const primaryEmail = emailResponse.data.find((email: any) => email.primary)?.email;
      
      const { id, name } = profileResponse.data;
      
      // Split name into first and last name (best effort)
      let firstName, lastName;
      if (name) {
        const nameParts = name.split(' ');
        firstName = nameParts[0];
        lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';
      }
      
      return {
        id: id.toString(),
        email: primaryEmail,
        firstName,
        lastName
      };
    } catch (error) {
      logger.error(`Error getting GitHub user profile: ${error}`);
      throw error;
    }
  }
  
  // Get Microsoft user profile
  private async getMicrosoftUserProfile(
    code: string,
    redirectUri: string
  ): Promise<{ id: string; email: string; firstName?: string; lastName?: string }> {
    try {
      // Exchange authorization code for access token
      const tokenResponse = await axios.post(
        'https://login.microsoftonline.com/common/oauth2/v2.0/token',
        new URLSearchParams({
          client_id: process.env.MICROSOFT_CLIENT_ID || '',
          client_secret: process.env.MICROSOFT_CLIENT_SECRET || '',
          code,
          redirect_uri: redirectUri,
          grant_type: 'authorization_code'
        }),
        {
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        }
      );
      
      const { access_token } = tokenResponse.data;
      
      // Get user profile
      const profileResponse = await axios.get('https://graph.microsoft.com/v1.0/me', {
        headers: { Authorization: `Bearer ${access_token}` }
      });
      
      const { id, mail, givenName, surname } = profileResponse.data;
      
      return {
        id,
        email: mail,
        firstName: givenName,
        lastName: surname
      };
    } catch (error) {
      logger.error(`Error getting Microsoft user profile: ${error}`);
      throw error;
    }
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
