// ============================================================================
// Pharmacy Routes (Dispense/Medication)
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/pharmacy/dispenses - Get all dispenses
router.get('/dispenses', async (req, res) => {
  try {
    const { patientId, staffId, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (staffId) where.staffId = parseInt(staffId);
    if (startDate || endDate) {
      where.dispenseDate = {};
      if (startDate) where.dispenseDate.gte = new Date(startDate);
      if (endDate) where.dispenseDate.lte = new Date(endDate);
    }

    const [dispenses, total] = await Promise.all([
      prisma.dispense.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          regimen: true,
          staff: { include: { person: true } },
        },
        orderBy: { dispenseDate: 'desc' },
      }),
      prisma.dispense.count({ where }),
    ]);

    res.json({
      data: dispenses,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dispenses' });
  }
});

// GET /api/pharmacy/dispenses/:id - Get dispense by ID
router.get('/dispenses/:id', async (req, res) => {
  try {
    const dispense = await prisma.dispense.findUnique({
      where: { dispenseId: BigInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
        regimen: true,
        staff: { include: { person: true } },
      },
    });

    if (!dispense) {
      return res.status(404).json({ error: 'Dispense not found' });
    }

    res.json(dispense);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dispense' });
  }
});

// POST /api/pharmacy/dispenses - Create new dispense (requires pharmacy or admin)
router.post('/dispenses', authorize('db_pharmacy', 'db_admin'), async (req, res) => {
  try {
    const {
      patientId,
      regimenId,
      dispenseDate,
      daysSupply,
      quantityDispensed,
      notes,
    } = req.body;

    // Calculate next refill date
    const dispenseDateObj = new Date(dispenseDate);
    const nextRefillDate = new Date(dispenseDateObj);
    nextRefillDate.setDate(nextRefillDate.getDate() + parseInt(daysSupply));

    const dispense = await prisma.dispense.create({
      data: {
        patientId: parseInt(patientId),
        staffId: req.staff.staffId,
        regimenId: parseInt(regimenId),
        dispenseDate: dispenseDateObj,
        daysSupply: parseInt(daysSupply),
        quantityDispensed: parseInt(quantityDispensed),
        nextRefillDate: nextRefillDate,
        notes: notes || null,
      },
      include: {
        patient: { include: { person: true } },
        regimen: true,
        staff: { include: { person: true } },
      },
    });

    res.status(201).json(dispense);
  } catch (error) {
    console.error('Create dispense error:', error);
    res.status(500).json({ error: 'Failed to create dispense' });
  }
});

// PUT /api/pharmacy/dispenses/:id - Update dispense (requires pharmacy or admin)
router.put('/dispenses/:id', authorize('db_pharmacy', 'db_admin'), async (req, res) => {
  try {
    const { daysSupply, quantityDispensed, notes } = req.body;

    const existing = await prisma.dispense.findUnique({
      where: { dispenseId: BigInt(req.params.id) },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Dispense not found' });
    }

    // Recalculate next refill date if daysSupply changed
    let nextRefillDate = existing.nextRefillDate;
    if (daysSupply) {
      const dispenseDate = new Date(existing.dispenseDate);
      nextRefillDate = new Date(dispenseDate);
      nextRefillDate.setDate(nextRefillDate.getDate() + parseInt(daysSupply));
    }

    const dispense = await prisma.dispense.update({
      where: { dispenseId: BigInt(req.params.id) },
      data: {
        daysSupply: daysSupply ? parseInt(daysSupply) : undefined,
        quantityDispensed: quantityDispensed ? parseInt(quantityDispensed) : undefined,
        nextRefillDate: nextRefillDate,
        notes: notes !== undefined ? notes : undefined,
      },
      include: {
        patient: { include: { person: true } },
        regimen: true,
        staff: { include: { person: true } },
      },
    });

    res.json(dispense);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update dispense' });
  }
});

// GET /api/pharmacy/dispenses/patient/:patientId - Get patient's dispense history
router.get('/dispenses/patient/:patientId', async (req, res) => {
  try {
    const dispenses = await prisma.dispense.findMany({
      where: { patientId: parseInt(req.params.patientId) },
      include: {
        regimen: true,
        staff: { include: { person: true } },
      },
      orderBy: { dispenseDate: 'desc' },
    });

    res.json(dispenses);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient dispenses' });
  }
});

// GET /api/pharmacy/overdue-refills - Get patients with overdue refills
router.get('/overdue-refills', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dispenses = await prisma.dispense.findMany({
      where: {
        nextRefillDate: {
          lt: today,
        },
        patient: {
          currentStatus: 'Active',
        },
      },
      include: {
        patient: {
          include: {
            person: true,
          },
        },
        regimen: true,
      },
      orderBy: { nextRefillDate: 'asc' },
    });

    res.json(dispenses);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch overdue refills' });
  }
});

module.exports = router;



