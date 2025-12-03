// ============================================================================
// Counseling Session Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/counseling - Get all counseling sessions
router.get('/', async (req, res) => {
  try {
    const { patientId, counselorId, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (counselorId) where.counselorId = parseInt(counselorId);
    if (startDate || endDate) {
      where.sessionDate = {};
      if (startDate) where.sessionDate.gte = new Date(startDate);
      if (endDate) where.sessionDate.lte = new Date(endDate);
    }

    const [sessions, total] = await Promise.all([
      prisma.counselingSession.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          counselor: { include: { person: true } },
        },
        orderBy: { sessionDate: 'desc' },
      }),
      prisma.counselingSession.count({ where }),
    ]);

    res.json({
      data: sessions,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch counseling sessions' });
  }
});

// GET /api/counseling/:id - Get counseling session by ID
router.get('/:id', async (req, res) => {
  try {
    const session = await prisma.counselingSession.findUnique({
      where: { counselingId: BigInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
        counselor: { include: { person: true } },
      },
    });

    if (!session) {
      return res.status(404).json({ error: 'Counseling session not found' });
    }

    res.json(session);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch counseling session' });
  }
});

// POST /api/counseling - Create new counseling session (requires counselor or admin)
router.post('/', authorize('db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { patientId, sessionDate, topic, adherenceBarriers, notes } = req.body;

    const session = await prisma.counselingSession.create({
      data: {
        patientId: parseInt(patientId),
        counselorId: req.staff.staffId,
        sessionDate: new Date(sessionDate),
        topic: topic,
        adherenceBarriers: adherenceBarriers || null,
        notes: notes || null,
      },
      include: {
        patient: { include: { person: true } },
        counselor: { include: { person: true } },
      },
    });

    res.status(201).json(session);
  } catch (error) {
    console.error('Create counseling session error:', error);
    res.status(500).json({ error: 'Failed to create counseling session' });
  }
});

// PUT /api/counseling/:id - Update counseling session (requires counselor or admin)
router.put('/:id', authorize('db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { sessionDate, topic, adherenceBarriers, notes } = req.body;

    const session = await prisma.counselingSession.update({
      where: { counselingId: BigInt(req.params.id) },
      data: {
        sessionDate: sessionDate ? new Date(sessionDate) : undefined,
        topic: topic || undefined,
        adherenceBarriers: adherenceBarriers !== undefined ? adherenceBarriers : undefined,
        notes: notes !== undefined ? notes : undefined,
      },
      include: {
        patient: { include: { person: true } },
        counselor: { include: { person: true } },
      },
    });

    res.json(session);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update counseling session' });
  }
});

// GET /api/counseling/patient/:patientId - Get patient's counseling sessions
router.get('/patient/:patientId', async (req, res) => {
  try {
    const sessions = await prisma.counselingSession.findMany({
      where: { patientId: parseInt(req.params.patientId) },
      include: {
        counselor: { include: { person: true } },
      },
      orderBy: { sessionDate: 'desc' },
    });

    res.json(sessions);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient counseling sessions' });
  }
});

module.exports = router;

