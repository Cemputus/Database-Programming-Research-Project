// ============================================================================
// Visit Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/visits - Get all visits
router.get('/', async (req, res) => {
  try {
    const { patientId, staffId, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (staffId) where.staffId = parseInt(staffId);
    if (startDate || endDate) {
      where.visitDate = {};
      if (startDate) where.visitDate.gte = new Date(startDate);
      if (endDate) where.visitDate.lte = new Date(endDate);
    }

    const [visits, total] = await Promise.all([
      prisma.visit.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          staff: { include: { person: true } },
        },
        orderBy: { visitDate: 'desc' },
      }),
      prisma.visit.count({ where }),
    ]);

    res.json({
      data: visits,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch visits' });
  }
});

// GET /api/visits/:id - Get visit by ID
router.get('/:id', async (req, res) => {
  try {
    const visit = await prisma.visit.findUnique({
      where: { visitId: parseInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    if (!visit) {
      return res.status(404).json({ error: 'Visit not found' });
    }

    res.json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch visit' });
  }
});

// POST /api/visits - Create new visit (requires clinician)
router.post('/', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const visit = await prisma.visit.create({
      data: {
        patientId: req.body.patientId,
        visitDate: new Date(req.body.visitDate),
        visitType: req.body.visitType,
        staffId: req.body.staffId,
        weightKg: req.body.weightKg ? parseFloat(req.body.weightKg) : null,
        bp: req.body.bp,
        whoStage: req.body.whoStage ? parseInt(req.body.whoStage) : null,
        tbScreening: req.body.tbScreening,
        symptoms: req.body.symptoms,
        oiDiagnosis: req.body.oiDiagnosis,
        nextAppointmentDate: req.body.nextAppointmentDate ? new Date(req.body.nextAppointmentDate) : null,
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    res.status(201).json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create visit' });
  }
});

// PUT /api/visits/:id - Update visit (requires clinician)
router.put('/:id', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const visit = await prisma.visit.update({
      where: { visitId: parseInt(req.params.id) },
      data: req.body,
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    res.json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update visit' });
  }
});

module.exports = router;

