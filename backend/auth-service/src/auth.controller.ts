import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/user.model';
import { LoginDTO, RegisterDTO, RefreshTokenDTO, TokenPayload } from '../types/auth.types';
import { sendMessage } from '../config/kafka';

class AuthController {
  // Register a new user
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password }: RegisterDTO = req.body;

      // Check if user already exists
      const existingUser = await userModel.findByEmail(email);
      if (existingUser) {
        res.status(409).json({ message: 'User already exists with this email' });
        return;
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Create user
      const user = await userModel.create({
        email,
        hashedPassword,
      });

      // Generate JWT token
      const accessToken = this.generateAccessToken(user.id, user.role);

      // Generate refresh token
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userModel.updateRefreshToken(user.id, refreshToken);

      // Publish user_created event to Kafka
      await sendMessage('user_created', {
        id: user.id,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt
      });

      // Return user data and tokens
      res.status(201).json({
        id: user.id,
        email: user.email,
        role: user.role,
        accessToken,
        refreshToken
      });
    } catch (error) {
      next(error);
    }
  }

  // Login user
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password }: LoginDTO = req.body;

      // Find user by email
      const user = await userModel.findByEmail(email);
      if (!user) {
        res.status(401).json({ message: 'Invalid credentials' });
        return;
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.hashedPassword);
      if (!isPasswordValid) {
        res.status(401).json({ message: 'Invalid credentials' });
        return;
      }

      // Generate JWT token
      const accessToken = this.generateAccessToken(user.id, user.role);

      // Generate refresh token
      const refreshToken = this.generateRefreshToken(user.id, user.role);

      // Save refresh token to database
      await userModel.updateRefreshToken(user.id, refreshToken);

      // Return user data and tokens
      res.status(200).json({
        id: user.id,
        email: user.email,
        role: user.role,
        accessToken,
        refreshToken
      });
    } catch (error) {
      next(error);
    }
  }

  // Get current user
  async me(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // User is attached to request by auth middleware
      const user = req.user;
      
      if (!user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
      }

      res.status(200).json({
        id: user.id,
        email: user.email,
        role: user.role
      });
    } catch (error) {
      next(error);
    }
  }

  // Refresh access token
  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken }: RefreshTokenDTO = req.body;

      if (!refreshToken) {
        res.status(400).json({ message: 'Refresh token is required' });
        return;
      }

      // Verify refresh token
      const decoded = jwt.verify(
        refreshToken,
        process.env.JWT_SECRET || 'default_jwt_secret'
      ) as TokenPayload;

      // Find user by ID
      const user = await userModel.findById(decoded.sub);
      if (!user || user.refreshToken !== refreshToken) {
        res.status(401).json({ message: 'Invalid refresh token' });
        return;
      }

      // Generate new access token
      const accessToken = this.generateAccessToken(user.id, user.role);

      // Return new access token
      res.status(200).json({ accessToken });
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        res.status(401).json({ message: 'Invalid refresh token' });
        return;
      }
      next(error);
    }
  }

  // Logout user
  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // User is attached to request by auth middleware
      const user = req.user;
      
      if (!user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
      }

      // Clear refresh token in database
      await userModel.updateRefreshToken(user.id, null);

      res.status(200).json({ message: 'Logged out successfully' });
    } catch (error) {
      next(error);
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
}

export default new AuthController();
