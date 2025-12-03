// ============================================================================
// Adherence Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/adherence - Get all adherence logs
router.get('/', async (req, res) => {
  try {
    const { patientId, methodUsed, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (methodUsed) where.methodUsed = methodUsed;
    if (startDate || endDate) {
      where.logDate = {};
      if (startDate) where.logDate.gte = new Date(startDate);
      if (endDate) where.logDate.lte = new Date(endDate);
    }

    const [logs, total] = await Promise.all([
      prisma.adherenceLog.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
        },
        orderBy: { logDate: 'desc' },
      }),
      prisma.adherenceLog.count({ where }),
    ]);

    res.json({
      data: logs,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch adherence logs' });
  }
});

// GET /api/adherence/:id - Get adherence log by ID
router.get('/:id', async (req, res) => {
  try {
    const log = await prisma.adherenceLog.findUnique({
      where: { adherenceId: BigInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
      },
    });

    if (!log) {
      return res.status(404).json({ error: 'Adherence log not found' });
    }

    res.json(log);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch adherence log' });
  }
});

// POST /api/adherence - Create new adherence log (requires clinician, counselor, or admin)
router.post('/', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { patientId, logDate, adherencePercent, methodUsed, notes } = req.body;

    // Validate adherence percentage
    const adherence = parseFloat(adherencePercent);
    if (isNaN(adherence) || adherence < 0 || adherence > 100) {
      return res.status(400).json({ error: 'Adherence percentage must be between 0 and 100' });
    }

    const log = await prisma.adherenceLog.create({
      data: {
        patientId: parseInt(patientId),
        logDate: new Date(logDate),
        adherencePercent: adherence,
        methodUsed: methodUsed,
        notes: notes || null,
      },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.status(201).json(log);
  } catch (error) {
    console.error('Create adherence log error:', error);
    res.status(500).json({ error: 'Failed to create adherence log' });
  }
});

// PUT /api/adherence/:id - Update adherence log (requires clinician, counselor, or admin)
router.put('/:id', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { logDate, adherencePercent, methodUsed, notes } = req.body;

    // Validate adherence percentage if provided
    if (adherencePercent !== undefined) {
      const adherence = parseFloat(adherencePercent);
      if (isNaN(adherence) || adherence < 0 || adherence > 100) {
        return res.status(400).json({ error: 'Adherence percentage must be between 0 and 100' });
      }
    }

    const log = await prisma.adherenceLog.update({
      where: { adherenceId: BigInt(req.params.id) },
      data: {
        logDate: logDate ? new Date(logDate) : undefined,
        adherencePercent: adherencePercent ? parseFloat(adherencePercent) : undefined,
        methodUsed: methodUsed || undefined,
        notes: notes !== undefined ? notes : undefined,
      },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.json(log);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update adherence log' });
  }
});

// GET /api/adherence/patient/:patientId - Get patient's adherence history
router.get('/patient/:patientId', async (req, res) => {
  try {
    const logs = await prisma.adherenceLog.findMany({
      where: { patientId: parseInt(req.params.patientId) },
      orderBy: { logDate: 'desc' },
    });

    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient adherence history' });
  }
});

// POST /api/adherence/compute/:patientId - Compute adherence for patient (requires clinician or admin)
router.post('/compute/:patientId', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const patientId = parseInt(req.params.patientId);

    // Call stored procedure to compute adherence
    // Note: This requires executing raw SQL since Prisma doesn't directly support stored procedures
    const result = await prisma.$queryRaw`
      CALL sp_compute_adherence(${patientId}, ${startDate ? new Date(startDate) : null}, ${endDate ? new Date(endDate) : null})
    `;

    // Get the latest computed adherence log
    const latestLog = await prisma.adherenceLog.findFirst({
      where: {
        patientId: patientId,
        methodUsed: 'Computed',
      },
      orderBy: { logDate: 'desc' },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.json({
      message: 'Adherence computed successfully',
      adherence: latestLog,
    });
  } catch (error) {
    console.error('Compute adherence error:', error);
    res.status(500).json({ error: 'Failed to compute adherence' });
  }
});

module.exports = router;

