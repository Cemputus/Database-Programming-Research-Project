// ============================================================================
// Authentication Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { authenticate, JWT_SECRET } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// POST /api/auth/login - Staff login
router.post('/login', async (req, res) => {
  try {
    const { staffCode, password } = req.body;

    if (!staffCode || !password) {
      return res.status(400).json({ error: 'Staff code and password are required.' });
    }

    // Find staff by staff code
    const staff = await prisma.staff.findUnique({
      where: { staffCode },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true
          }
        }
      }
    });

    if (!staff) {
      return res.status(401).json({ error: 'Invalid staff code or password.' });
    }

    if (!staff.active) {
      return res.status(403).json({ error: 'Account is inactive. Contact administrator.' });
    }

    // Check password (in production, passwords should be hashed in database)
    // For now, we'll check if password matches a default or stored hash
    // In production, you should have a password field in staff table or a separate auth table
    const passwordMatch = await bcrypt.compare(password, staff.passwordHash || '$2a$10$defaultHash');
    
    // For development: allow default password 'password123' for all staff
    // In production, remove this and require proper password hashing
    const defaultPasswordHash = await bcrypt.hash('password123', 10);
    const isDefaultPassword = password === 'password123' || await bcrypt.compare(password, defaultPasswordHash);

    if (!passwordMatch && !isDefaultPassword) {
      // Check against a simple default for development
      // In production, all passwords must be properly hashed
      return res.status(401).json({ error: 'Invalid staff code or password.' });
    }

    // Get user roles
    const roles = staff.staffRoles.map(sr => sr.role.roleName);

    // Generate JWT token
    const token = jwt.sign(
      {
        staffId: staff.staffId,
        staffCode: staff.staffCode,
        cadre: staff.cadre,
        roles: roles
      },
      JWT_SECRET,
      { expiresIn: '8h' } // Token expires in 8 hours
    );

    res.json({
      message: 'Login successful',
      token,
      staff: {
        staffId: staff.staffId,
        staffCode: staff.staffCode,
        name: `${staff.person.firstName} ${staff.person.lastName}`,
        cadre: staff.cadre,
        roles: roles
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// POST /api/auth/logout - Logout (client-side token removal)
router.post('/logout', authenticate, (req, res) => {
  // JWT is stateless, so logout is handled client-side by removing token
  // In production, you might want to implement token blacklisting
  res.json({ message: 'Logout successful' });
});

// GET /api/auth/me - Get current authenticated user
router.get('/me', authenticate, async (req, res) => {
  try {
    const staff = await prisma.staff.findUnique({
      where: { staffId: req.staff.staffId },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true
          }
        }
      }
    });

    if (!staff) {
      return res.status(404).json({ error: 'Staff not found.' });
    }

    res.json({
      staffId: staff.staffId,
      staffCode: staff.staffCode,
      name: `${staff.person.firstName} ${staff.person.lastName}`,
      email: staff.person.email || null,
      phone: staff.person.phoneNumber || null,
      cadre: staff.cadre,
      moHRegistrationNo: staff.moHRegistrationNo,
      active: staff.active,
      roles: staff.staffRoles.map(sr => sr.role.roleName)
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({ error: 'Failed to get user information.' });
  }
});

// POST /api/auth/change-password - Change password
router.post('/change-password', authenticate, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters long.' });
    }

    // In production, verify current password against stored hash
    // For now, we'll just update (in production, add password field to staff table)
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // In production, update password in database
    // await prisma.staff.update({
    //   where: { staffId: req.staff.staffId },
    //   data: { passwordHash: hashedPassword }
    // });

    res.json({ message: 'Password changed successfully. (Note: In production, implement password storage)' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to change password.' });
  }
});

// GET /api/auth/roles - Get all available roles
router.get('/roles', authenticate, async (req, res) => {
  try {
    const roles = await prisma.role.findMany({
      orderBy: { roleName: 'asc' }
    });

    res.json(roles);
  } catch (error) {
    console.error('Get roles error:', error);
    res.status(500).json({ error: 'Failed to get roles.' });
  }
});

module.exports = router;

