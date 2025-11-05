import { Elysia } from 'elysia';
import { jwt } from '@elysiajs/jwt';
import User from '../models/User.schema';

// JWT Secret - In production, use environment variable
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';

/**
 * Authentication middleware to protect routes
 * Verifies JWT token and adds user info to context
 */
export const authMiddleware = new Elysia()
  .use(
    jwt({
      name: 'jwt',
      secret: JWT_SECRET,
      exp: '7d'
    })
  )
  .derive(async ({ headers, set, jwt }) => {
    const authHeader = headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      set.status = 401;
      throw new Error('No authentication token provided');
    }

    const token = authHeader.split(' ')[1];
    const payload = await jwt.verify(token);

    if (!payload) {
      set.status = 401;
      throw new Error('Invalid or expired token');
    }

    // Get user from database to ensure they still exist and are active
    const user = await User.findById(payload.userId);
    if (!user) {
      set.status = 404;
      throw new Error('User not found');
    }

    if (!user.isActive) {
      set.status = 403;
      throw new Error('Account is deactivated');
    }

    // Add user info to context
    return {
      user: {
        id: user._id.toString(),
        email: user.email,
        role: user.role,
        firstName: user.firstName,
        lastName: user.lastName,
        businessName: user.businessName
      }
    };
  });

/**
 * Role-based authorization middleware
 * Restricts access to specific roles
 */
export const requireRole = (allowedRoles: string[]) => {
  return new Elysia()
    .use(authMiddleware)
    .derive(({ user, set }) => {
      if (!allowedRoles.includes(user.role)) {
        set.status = 403;
        throw new Error(`Access denied. Required role: ${allowedRoles.join(' or ')}`);
      }
      return { user };
    });
};

