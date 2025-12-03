// ============================================================================
// Alert Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/alerts - Get all alerts
router.get('/', async (req, res) => {
  try {
    const { patientId, alertType, alertLevel, isResolved, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (alertType) where.alertType = alertType;
    if (alertLevel) where.alertLevel = alertLevel;
    if (isResolved !== undefined) where.isResolved = isResolved === 'true';

    const [alerts, total] = await Promise.all([
      prisma.alert.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
        },
        orderBy: [
          { alertLevel: 'asc' },
          { triggeredAt: 'desc' },
        ],
      }),
      prisma.alert.count({ where }),
    ]);

    res.json({
      data: alerts,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// GET /api/alerts/:id - Get alert by ID
router.get('/:id', async (req, res) => {
  try {
    const alert = await prisma.alert.findUnique({
      where: { alertId: BigInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
      },
    });

    if (!alert) {
      return res.status(404).json({ error: 'Alert not found' });
    }

    res.json(alert);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch alert' });
  }
});

// GET /api/alerts/patient/:patientId - Get patient's alerts
router.get('/patient/:patientId', async (req, res) => {
  try {
    const { isResolved } = req.query;
    const where = { patientId: parseInt(req.params.patientId) };
    
    if (isResolved !== undefined) where.isResolved = isResolved === 'true';

    const alerts = await prisma.alert.findMany({
      where,
      orderBy: [
        { alertLevel: 'asc' },
        { triggeredAt: 'desc' },
      ],
    });

    res.json(alerts);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient alerts' });
  }
});

// GET /api/alerts/active - Get all active (unresolved) alerts
router.get('/active', async (req, res) => {
  try {
    const alerts = await prisma.alert.findMany({
      where: { isResolved: false },
      include: {
        patient: { include: { person: true } },
      },
      orderBy: [
        { alertLevel: 'asc' },
        { triggeredAt: 'desc' },
      ],
    });

    res.json(alerts);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch active alerts' });
  }
});

// PUT /api/alerts/:id/resolve - Resolve alert (requires clinician, counselor, or admin)
router.put('/:id/resolve', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const alert = await prisma.alert.update({
      where: { alertId: BigInt(req.params.id) },
      data: {
        isResolved: true,
        resolvedAt: new Date(),
      },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.json(alert);
  } catch (error) {
    res.status(500).json({ error: 'Failed to resolve alert' });
  }
});

// PUT /api/alerts/:id/unresolve - Unresolve alert (requires clinician, counselor, or admin)
router.put('/:id/unresolve', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const alert = await prisma.alert.update({
      where: { alertId: BigInt(req.params.id) },
      data: {
        isResolved: false,
        resolvedAt: null,
      },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.json(alert);
  } catch (error) {
    res.status(500).json({ error: 'Failed to unresolve alert' });
  }
});

module.exports = router;

