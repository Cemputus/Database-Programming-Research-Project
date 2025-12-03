// ============================================================================
// Lab Test Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

// GET /api/lab-tests - Get all lab tests
router.get('/', async (req, res) => {
  try {
    const { patientId, testType, status, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const where: any = {};
    if (patientId) where.patientId = parseInt(patientId as string);
    if (testType) where.testType = testType;
    if (status) where.status = status;
    if (startDate || endDate) {
      where.testDate = {};
      if (startDate) where.testDate.gte = new Date(startDate as string);
      if (endDate) where.testDate.lte = new Date(endDate as string);
    }

    const [labTests, total] = await Promise.all([
      prisma.labTest.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          orderedByStaff: { include: { person: true } },
          performedByStaff: { include: { person: true } },
        },
        orderBy: { testDate: 'desc' },
      }),
      prisma.labTest.count({ where }),
    ]);

    res.json({
      data: labTests,
      pagination: {
        page: parseInt(page as string),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch lab tests' });
  }
});

// GET /api/lab-tests/:id - Get lab test by ID
router.get('/:id', async (req, res) => {
  try {
    const labTest = await prisma.labTest.findUnique({
      where: { labTestId: parseInt(req.params.id) },
      include: {
        patient: { include: { person: true } },
        orderedByStaff: { include: { person: true } },
        performedByStaff: { include: { person: true } },
      },
    });

    if (!labTest) {
      return res.status(404).json({ error: 'Lab test not found' });
    }

    res.json(labTest);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch lab test' });
  }
});

// POST /api/lab-tests - Create new lab test
router.post('/', async (req, res) => {
  try {
    const labTest = await prisma.labTest.create({
      data: {
        patientId: req.body.patientId,
        testType: req.body.testType,
        testDate: new Date(req.body.testDate),
        orderedBy: req.body.orderedBy,
        performedBy: req.body.performedBy,
        sampleId: req.body.sampleId,
        sampleCollectionDate: req.body.sampleCollectionDate ? new Date(req.body.sampleCollectionDate) : null,
        resultValue: req.body.resultValue,
        resultNumeric: req.body.resultNumeric ? parseFloat(req.body.resultNumeric) : null,
        resultText: req.body.resultText,
        resultUnit: req.body.resultUnit,
        referenceRange: req.body.referenceRange,
        isAbnormal: req.body.isAbnormal,
        status: req.body.status || 'Pending',
        notes: req.body.notes,
      },
      include: {
        patient: { include: { person: true } },
      },
    });

    res.status(201).json(labTest);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create lab test' });
  }
});

// PUT /api/lab-tests/:id - Update lab test (e.g., update results)
router.put('/:id', async (req, res) => {
  try {
    const labTest = await prisma.labTest.update({
      where: { labTestId: parseInt(req.params.id) },
      data: {
        performedBy: req.body.performedBy,
        resultValue: req.body.resultValue,
        resultNumeric: req.body.resultNumeric ? parseFloat(req.body.resultNumeric) : null,
        resultText: req.body.resultText,
        resultUnit: req.body.resultUnit,
        referenceRange: req.body.referenceRange,
        isAbnormal: req.body.isAbnormal,
        status: req.body.status,
        notes: req.body.notes,
      },
      include: {
        patient: { include: { person: true } },
        performedByStaff: { include: { person: true } },
      },
    });

    res.json(labTest);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update lab test' });
  }
});

// GET /api/lab-tests/patient/:patientId/viral-load - Get viral load history
router.get('/patient/:patientId/viral-load', async (req, res) => {
  try {
    const viralLoads = await prisma.labTest.findMany({
      where: {
        patientId: parseInt(req.params.patientId),
        testType: 'ViralLoad',
        status: 'Completed',
      },
      orderBy: { testDate: 'desc' },
    });

    res.json(viralLoads);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch viral load history' });
  }
});

export default router;

