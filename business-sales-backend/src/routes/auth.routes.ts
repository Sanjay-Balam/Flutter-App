import { Elysia, t } from 'elysia';
import { jwt } from '@elysiajs/jwt';
import User from '../models/User.schema';

// JWT Secret - In production, use environment variable
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';

export const authRoutes = new Elysia({ prefix: '/api/auth' })
  .use(
    jwt({
      name: 'jwt',
      secret: JWT_SECRET,
      exp: '7d' // Token expires in 7 days
    })
  )
  
  // Register new user
  .post('/register', async ({ body, set, jwt }) => {
    try {
      const { email, password, firstName, lastName, phone, businessName, role } = body;

      // Check if user already exists
      const existingUser = await User.findOne({ email: email.toLowerCase() });
      if (existingUser) {
        set.status = 409;
        return {
          success: false,
          message: 'User with this email already exists'
        };
      }

      // Validate password length
      if (password.length < 6) {
        set.status = 400;
        return {
          success: false,
          message: 'Password must be at least 6 characters long'
        };
      }

      // Create new user (password will be hashed by pre-save middleware)
      const user = await User.create({
        email: email.toLowerCase(),
        password,
        firstName,
        lastName,
        phone: phone || undefined,
        businessName: businessName || undefined,
        role: role || 'owner',
        isActive: true
      });

      // Generate JWT token
      const token = await jwt.sign({
        userId: user._id.toString(),
        email: user.email,
        role: user.role
      });

      return {
        success: true,
        message: 'User registered successfully',
        data: {
          token,
          user: {
            id: user._id.toString(),
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role,
            businessName: user.businessName,
            isActive: user.isActive
          }
        }
      };
    } catch (error: any) {
      console.error('Registration error:', error);
      set.status = 500;
      return {
        success: false,
        message: 'Registration failed',
        error: error.message
      };
    }
  }, {
    body: t.Object({
      email: t.String({ format: 'email' }),
      password: t.String({ minLength: 6 }),
      firstName: t.String({ minLength: 1, maxLength: 50 }),
      lastName: t.String({ minLength: 1, maxLength: 50 }),
      phone: t.Optional(t.String()),
      businessName: t.Optional(t.String({ maxLength: 100 })),
      role: t.Optional(t.Union([t.Literal('owner'), t.Literal('manager'), t.Literal('employee')]))
    }),
    detail: {
      tags: ['Auth'],
      summary: 'Register a new user',
      description: 'Create a new user account with email and password'
    }
  })

  // Login user
  .post('/login', async ({ body, set, jwt }) => {
    try {
      const { email, password } = body;

      // Find user by email (include password field)
      const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
      
      if (!user) {
        set.status = 401;
        return {
          success: false,
          message: 'Invalid email or password'
        };
      }

      // Check if user is active
      if (!user.isActive) {
        set.status = 403;
        return {
          success: false,
          message: 'Account is deactivated. Please contact support.'
        };
      }

      // Compare password
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        set.status = 401;
        return {
          success: false,
          message: 'Invalid email or password'
        };
      }

      // Generate JWT token
      const token = await jwt.sign({
        userId: user._id.toString(),
        email: user.email,
        role: user.role
      });

      return {
        success: true,
        message: 'Login successful',
        data: {
          token,
          user: {
            id: user._id.toString(),
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role,
            businessName: user.businessName,
            isActive: user.isActive
          }
        }
      };
    } catch (error: any) {
      console.error('Login error:', error);
      set.status = 500;
      return {
        success: false,
        message: 'Login failed',
        error: error.message
      };
    }
  }, {
    body: t.Object({
      email: t.String({ format: 'email' }),
      password: t.String({ minLength: 1 })
    }),
    detail: {
      tags: ['Auth'],
      summary: 'Login user',
      description: 'Authenticate user with email and password'
    }
  })

  // Get current user profile
  .get('/me', async ({ headers, set, jwt }) => {
    try {
      const authHeader = headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        set.status = 401;
        return {
          success: false,
          message: 'No token provided'
        };
      }

      const token = authHeader.split(' ')[1];
      const payload = await jwt.verify(token);

      if (!payload) {
        set.status = 401;
        return {
          success: false,
          message: 'Invalid or expired token'
        };
      }

      // Get user from database
      const user = await User.findById(payload.userId);
      if (!user) {
        set.status = 404;
        return {
          success: false,
          message: 'User not found'
        };
      }

      if (!user.isActive) {
        set.status = 403;
        return {
          success: false,
          message: 'Account is deactivated'
        };
      }

      return {
        success: true,
        data: {
          user: {
            id: user._id.toString(),
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role,
            businessName: user.businessName,
            phone: user.phone,
            businessType: user.businessType,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
          }
        }
      };
    } catch (error: any) {
      console.error('Get profile error:', error);
      set.status = 500;
      return {
        success: false,
        message: 'Failed to get user profile',
        error: error.message
      };
    }
  }, {
    detail: {
      tags: ['Auth'],
      summary: 'Get current user profile',
      description: 'Get authenticated user information',
      security: [{ bearerAuth: [] }]
    }
  })

  // Verify token
  .post('/verify', async ({ body, set, jwt }) => {
    try {
      const { token } = body;
      const payload = await jwt.verify(token);

      if (!payload) {
        set.status = 401;
        return {
          success: false,
          message: 'Invalid or expired token'
        };
      }

      return {
        success: true,
        message: 'Token is valid',
        data: {
          userId: payload.userId,
          email: payload.email,
          role: payload.role
        }
      };
    } catch (error: any) {
      set.status = 401;
      return {
        success: false,
        message: 'Invalid token',
        error: error.message
      };
    }
  }, {
    body: t.Object({
      token: t.String()
    }),
    detail: {
      tags: ['Auth'],
      summary: 'Verify JWT token',
      description: 'Check if a JWT token is valid'
    }
  });

