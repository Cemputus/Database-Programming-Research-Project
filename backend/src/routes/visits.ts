// ============================================================================
// Visit Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

// GET /api/visits - Get all visits
router.get('/', async (req, res) => {
  try {
    const { patientId, staffId, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const where: any = {};
    if (patientId) where.patientId = parseInt(patientId as string);
    if (staffId) where.staffId = parseInt(staffId as string);
    if (startDate || endDate) {
      where.visitDate = {};
      if (startDate) where.visitDate.gte = new Date(startDate as string);
      if (endDate) where.visitDate.lte = new Date(endDate as string);
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
        page: parseInt(page as string),
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

// POST /api/visits - Create new visit
router.post('/', async (req, res) => {
  try {
    const visit = await prisma.visit.create({
      data: {
        patientId: req.body.patientId,
        visitDate: new Date(req.body.visitDate),
        visitType: req.body.visitType,
        staffId: req.body.staffId,
        weight: req.body.weight ? parseFloat(req.body.weight) : null,
        height: req.body.height ? parseFloat(req.body.height) : null,
        bpSystolic: req.body.bpSystolic ? parseInt(req.body.bpSystolic) : null,
        bpDiastolic: req.body.bpDiastolic ? parseInt(req.body.bpDiastolic) : null,
        temperature: req.body.temperature ? parseFloat(req.body.temperature) : null,
        pulse: req.body.pulse ? parseInt(req.body.pulse) : null,
        respiratoryRate: req.body.respiratoryRate ? parseInt(req.body.respiratoryRate) : null,
        clinicalNotes: req.body.clinicalNotes,
        diagnosis: req.body.diagnosis,
        whoStage: req.body.whoStage,
        tbScreeningResult: req.body.tbScreeningResult,
        pregnancyTestResult: req.body.pregnancyTestResult,
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

// PUT /api/visits/:id - Update visit
router.put('/:id', async (req, res) => {
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

export default router;

