// ============================================================================
// Lab Test Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');

const router = Router();
const prisma = new PrismaClient();

// GET /api/lab-tests - Get all lab tests
router.get('/', async (req, res) => {
  try {
    const { patientId, testType, status, startDate, endDate, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const where = {};
    if (patientId) where.patientId = parseInt(patientId);
    if (testType) where.testType = testType;
    if (status) where.status = status;
    if (startDate || endDate) {
      where.testDate = {};
      if (startDate) where.testDate.gte = new Date(startDate);
      if (endDate) where.testDate.lte = new Date(endDate);
    }

    const [labTests, total] = await Promise.all([
      prisma.labTest.findMany({
        where,
        skip,
        take,
        include: {
          patient: { include: { person: true } },
          staff: { include: { person: true } },
        },
        orderBy: { testDate: 'desc' },
      }),
      prisma.labTest.count({ where }),
    ]);

    res.json({
      data: labTests,
      pagination: {
        page: parseInt(page),
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
        visitId: req.body.visitId ? parseInt(req.body.visitId) : null,
        staffId: req.body.staffId,
        resultNumeric: req.body.resultNumeric ? parseFloat(req.body.resultNumeric) : null,
        resultText: req.body.resultText,
        units: req.body.units,
        cphlSampleId: req.body.cphlSampleId,
        resultStatus: req.body.resultStatus || 'Pending',
        notes: req.body.notes,
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
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
        resultNumeric: req.body.resultNumeric ? parseFloat(req.body.resultNumeric) : null,
        resultText: req.body.resultText,
        units: req.body.units,
        resultStatus: req.body.resultStatus,
      },
      include: {
        patient: { include: { person: true } },
        staff: { include: { person: true } },
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
        resultStatus: 'Completed',
      },
      orderBy: { testDate: 'desc' },
    });

    res.json(viralLoads);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch viral load history' });
  }
});

module.exports = router;

