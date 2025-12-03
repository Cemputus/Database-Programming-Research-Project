// ============================================================================
// API Routes Index
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const patientsRouter = require('./patients');
const visitsRouter = require('./visits');
const labTestsRouter = require('./lab-tests');
const { PrismaClient } = require('@prisma/client');

const router = Router();
const prisma = new PrismaClient();

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Mount route modules
router.use('/patients', patientsRouter);
router.use('/visits', visitsRouter);
router.use('/lab-tests', labTestsRouter);

// Additional routes would be added here:
// router.use('/pharmacy', pharmacyRouter);
// router.use('/appointments', appointmentsRouter);
// router.use('/counseling', counselingRouter);
// router.use('/alerts', alertsRouter);
// router.use('/adherence', adherenceRouter);
// router.use('/staff', staffRouter);
// router.use('/regimens', regimensRouter);

module.exports = router;

