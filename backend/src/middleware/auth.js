// ============================================================================
// Authentication Middleware
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'hiv-care-monitoring-secret-key-change-in-production';

// Verify JWT token and attach user to request
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided. Authorization header required.' });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      
      // Get staff member with roles
      const staff = await prisma.staff.findUnique({
        where: { staffId: decoded.staffId },
        include: {
          person: true,
          staffRoles: {
            include: {
              role: true
            }
          }
        }
      });

      if (!staff || !staff.active) {
        return res.status(401).json({ error: 'Invalid token. Staff not found or inactive.' });
      }

      // Attach staff and roles to request
      req.staff = staff;
      req.roles = staff.staffRoles.map(sr => sr.role.roleName);
      
      next();
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Token expired. Please login again.' });
      }
      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({ error: 'Invalid token.' });
      }
      throw error;
    }
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ error: 'Authentication failed.' });
  }
};

// Role-based access control middleware
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.staff) {
      return res.status(401).json({ error: 'Authentication required.' });
    }

    const userRoles = req.roles || [];
    const hasRole = allowedRoles.some(role => userRoles.includes(role));

    if (!hasRole) {
      return res.status(403).json({ 
        error: 'Access denied. Insufficient permissions.',
        required: allowedRoles,
        current: userRoles
      });
    }

    next();
  };
};

// Check if user has any of the required roles (OR logic)
const authorizeAny = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.staff) {
      return res.status(401).json({ error: 'Authentication required.' });
    }

    const userRoles = req.roles || [];
    const hasAnyRole = allowedRoles.some(role => userRoles.includes(role));

    if (!hasAnyRole) {
      return res.status(403).json({ 
        error: 'Access denied. Insufficient permissions.',
        required: allowedRoles,
        current: userRoles
      });
    }

    next();
  };
};

// Optional authentication - doesn't fail if no token, but attaches user if token is valid
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        
        const staff = await prisma.staff.findUnique({
          where: { staffId: decoded.staffId },
          include: {
            person: true,
            staffRoles: {
              include: {
                role: true
              }
            }
          }
        });

        if (staff && staff.active) {
          req.staff = staff;
          req.roles = staff.staffRoles.map(sr => sr.role.roleName);
        }
      } catch (error) {
        // Token invalid or expired - continue without authentication
      }
    }
    
    next();
  } catch (error) {
    // Continue without authentication on error
    next();
  }
};

module.exports = {
  authenticate,
  authorize,
  authorizeAny,
  optionalAuth,
  JWT_SECRET
};

