// ============================================================================
// Regimen Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/regimens - Get all regimens
router.get('/', async (req, res) => {
  try {
    const { line, search, page = '1', limit = '50' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (line) where.line = line;
    if (search) {
      where.OR = [
        { regimenCode: { contains: search } },
        { regimenName: { contains: search } },
      ];
    }

    const [regimens, total] = await Promise.all([
      prisma.regimen.findMany({
        where,
        skip,
        take,
        orderBy: { regimenName: 'asc' },
      }),
      prisma.regimen.count({ where }),
    ]);

    res.json({
      data: regimens,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch regimens' });
  }
});

// GET /api/regimens/:id - Get regimen by ID
router.get('/:id', async (req, res) => {
  try {
    const regimen = await prisma.regimen.findUnique({
      where: { regimenId: parseInt(req.params.id) },
      include: {
        dispenses: {
          take: 10,
          orderBy: { dispenseDate: 'desc' },
          include: {
            patient: { include: { person: true } },
          },
        },
      },
    });

    if (!regimen) {
      return res.status(404).json({ error: 'Regimen not found' });
    }

    res.json(regimen);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch regimen' });
  }
});

// POST /api/regimens - Create new regimen (requires admin)
router.post('/', authorize('db_admin'), async (req, res) => {
  try {
    const { regimenCode, regimenName, line } = req.body;

    const regimen = await prisma.regimen.create({
      data: {
        regimenCode,
        regimenName,
        line,
      },
    });

    res.status(201).json(regimen);
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Regimen code already exists' });
    }
    res.status(500).json({ error: 'Failed to create regimen' });
  }
});

// PUT /api/regimens/:id - Update regimen (requires admin)
router.put('/:id', authorize('db_admin'), async (req, res) => {
  try {
    const { regimenName, line } = req.body;

    const regimen = await prisma.regimen.update({
      where: { regimenId: parseInt(req.params.id) },
      data: {
        regimenName: regimenName || undefined,
        line: line || undefined,
      },
    });

    res.json(regimen);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update regimen' });
  }
});

// GET /api/regimens/line/:line - Get regimens by line
router.get('/line/:line', async (req, res) => {
  try {
    const regimens = await prisma.regimen.findMany({
      where: { line: req.params.line },
      orderBy: { regimenName: 'asc' },
    });

    res.json(regimens);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch regimens by line' });
  }
});

module.exports = router;

