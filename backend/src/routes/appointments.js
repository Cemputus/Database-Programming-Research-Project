// ============================================================================
// Appointment Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/appointments - Get all appointments
router.get('/', async (req, res) => {
  try {
    const { patientId, staffId, status, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (staffId) where.staffId = parseInt(staffId);
    if (status) where.status = status;
    if (startDate || endDate) {
      where.scheduledDate = {};
      if (startDate) where.scheduledDate.gte = new Date(startDate);
      if (endDate) where.scheduledDate.lte = new Date(endDate);
    }

    const [appointments, total] = await Promise.all([
      prisma.appointment.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          staff: { include: { person: true } },
        },
        orderBy: { scheduledDate: 'desc' },
      }),
      prisma.appointment.count({ where }),
    ]);

    res.json({
      data: appointments,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch appointments' });
  }
});

// GET /api/appointments/:id - Get appointment by ID
router.get('/:id', async (req, res) => {
  try {
    const appointment = await prisma.appointment.findUnique({
      where: { appointmentId: BigInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    res.json(appointment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch appointment' });
  }
});

// POST /api/appointments - Create new appointment (requires clinician, counselor, or admin)
router.post('/', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { patientId, scheduledDate, reason } = req.body;

    const appointment = await prisma.appointment.create({
      data: {
        patientId: parseInt(patientId),
        staffId: req.staff.staffId,
        scheduledDate: new Date(scheduledDate),
        reason: reason || null,
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    res.status(201).json(appointment);
  } catch (error) {
    console.error('Create appointment error:', error);
    res.status(500).json({ error: 'Failed to create appointment' });
  }
});

// PUT /api/appointments/:id - Update appointment (requires clinician, counselor, or admin)
router.put('/:id', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const { scheduledDate, status, reason } = req.body;

    const appointment = await prisma.appointment.update({
      where: { appointmentId: BigInt(req.params.id) },
      data: {
        scheduledDate: scheduledDate ? new Date(scheduledDate) : undefined,
        status: status || undefined,
        reason: reason !== undefined ? reason : undefined,
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    res.json(appointment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update appointment' });
  }
});

// PUT /api/appointments/:id/mark-attended - Mark appointment as attended
router.put('/:id/mark-attended', authorize('db_clinician', 'db_counselor', 'db_admin'), async (req, res) => {
  try {
    const appointment = await prisma.appointment.update({
      where: { appointmentId: BigInt(req.params.id) },
      data: { status: 'Attended' },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
    });

    res.json(appointment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to mark appointment as attended' });
  }
});

// GET /api/appointments/patient/:patientId - Get patient's appointments
router.get('/patient/:patientId', async (req, res) => {
  try {
    const { status, upcoming } = req.query;
    const where = { patientId: parseInt(req.params.patientId) };
    
    if (status) where.status = status;
    if (upcoming === 'true') {
      where.scheduledDate = { gte: new Date() };
      where.status = 'Scheduled';
    }

    const appointments = await prisma.appointment.findMany({
      where,
      include: {
        staff: { include: { person: true } },
      },
      orderBy: { scheduledDate: 'desc' },
    });

    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient appointments' });
  }
});

// GET /api/appointments/missed - Get missed appointments
router.get('/missed', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const appointments = await prisma.appointment.findMany({
      where: {
        status: 'Missed',
        scheduledDate: {
          lte: today,
        },
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
      },
      orderBy: { scheduledDate: 'desc' },
    });

    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch missed appointments' });
  }
});

module.exports = router;

