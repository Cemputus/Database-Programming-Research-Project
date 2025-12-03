// ============================================================================
// Staff Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/staff - Get all staff
router.get('/', async (req, res) => {
  try {
    const { active, cadre, search, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (active !== undefined) where.active = active === 'true';
    if (cadre) where.cadre = cadre;
    if (search) {
      where.OR = [
        { staffCode: { contains: search } },
        { person: { firstName: { contains: search } } },
        { person: { lastName: { contains: search } } },
      ];
    }

    const [staff, total] = await Promise.all([
      prisma.staff.findMany({
        where,
        skip,
        take,
        include: {
          person: true,
          staffRoles: {
            include: {
              role: true,
            },
          },
        },
        orderBy: { hireDate: 'desc' },
      }),
      prisma.staff.count({ where }),
    ]);

    res.json({
      data: staff,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch staff' });
  }
});

// GET /api/staff/:id - Get staff by ID
router.get('/:id', async (req, res) => {
  try {
    const staff = await prisma.staff.findUnique({
      where: { staffId: parseInt(req.params.id) },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    if (!staff) {
      return res.status(404).json({ error: 'Staff not found' });
    }

    res.json(staff);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch staff' });
  }
});

// POST /api/staff - Create new staff (requires admin)
router.post('/', authorize('db_admin'), async (req, res) => {
  try {
    const {
      nin,
      firstName,
      lastName,
      otherName,
      sex,
      dateOfBirth,
      phoneContact,
      district,
      subcounty,
      parish,
      village,
      staffCode,
      cadre,
      moHRegistrationNo,
      hireDate,
      roleIds,
    } = req.body;

    // Create person first
    const person = await prisma.person.create({
      data: {
        nin,
        firstName,
        lastName,
        otherName: otherName || null,
        sex,
        dateOfBirth: new Date(dateOfBirth),
        phoneContact: phoneContact || null,
        district,
        subcounty,
        parish: parish || null,
        village: village || null,
      },
    });

    // Create staff
    const staff = await prisma.staff.create({
      data: {
        personId: person.personId,
        staffCode,
        cadre,
        moHRegistrationNo: moHRegistrationNo || null,
        hireDate: new Date(hireDate),
        active: true,
      },
      include: {
        person: true,
      },
    });

    // Assign roles if provided
    if (roleIds && Array.isArray(roleIds) && roleIds.length > 0) {
      await prisma.staffRole.createMany({
        data: roleIds.map(roleId => ({
          staffId: staff.staffId,
          roleId: parseInt(roleId),
        })),
      });
    }

    // Fetch staff with roles
    const staffWithRoles = await prisma.staff.findUnique({
      where: { staffId: staff.staffId },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    res.status(201).json(staffWithRoles);
  } catch (error) {
    console.error('Create staff error:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Staff code or NIN already exists' });
    }
    res.status(500).json({ error: 'Failed to create staff' });
  }
});

// PUT /api/staff/:id - Update staff (requires admin)
router.put('/:id', authorize('db_admin'), async (req, res) => {
  try {
    const { active, cadre, moHRegistrationNo } = req.body;

    const staff = await prisma.staff.update({
      where: { staffId: parseInt(req.params.id) },
      data: {
        active: active !== undefined ? active : undefined,
        cadre: cadre || undefined,
        moHRegistrationNo: moHRegistrationNo !== undefined ? moHRegistrationNo : undefined,
      },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    res.json(staff);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update staff' });
  }
});

// GET /api/staff/:id/roles - Get staff roles
router.get('/:id/roles', async (req, res) => {
  try {
    const staff = await prisma.staff.findUnique({
      where: { staffId: parseInt(req.params.id) },
      include: {
        staffRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    if (!staff) {
      return res.status(404).json({ error: 'Staff not found' });
    }

    res.json(staff.staffRoles.map(sr => sr.role));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch staff roles' });
  }
});

// POST /api/staff/:id/roles - Assign roles to staff (requires admin)
router.post('/:id/roles', authorize('db_admin'), async (req, res) => {
  try {
    const { roleIds } = req.body;

    if (!Array.isArray(roleIds) || roleIds.length === 0) {
      return res.status(400).json({ error: 'roleIds must be a non-empty array' });
    }

    // Remove existing roles
    await prisma.staffRole.deleteMany({
      where: { staffId: parseInt(req.params.id) },
    });

    // Add new roles
    await prisma.staffRole.createMany({
      data: roleIds.map(roleId => ({
        staffId: parseInt(req.params.id),
        roleId: parseInt(roleId),
      })),
    });

    // Fetch staff with roles
    const staff = await prisma.staff.findUnique({
      where: { staffId: parseInt(req.params.id) },
      include: {
        person: true,
        staffRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    res.json(staff);
  } catch (error) {
    res.status(500).json({ error: 'Failed to assign roles' });
  }
});

module.exports = router;

