// ============================================================================
// API Routes Index
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const authRouter = require('./auth');
const patientsRouter = require('./patients');
const visitsRouter = require('./visits');
const labTestsRouter = require('./lab-tests');
const { PrismaClient } = require('@prisma/client');
const { authenticate, authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// Health check (public)
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Authentication routes (public)
router.use('/auth', authRouter);

// Protected routes - require authentication
router.use('/patients', authenticate, patientsRouter);
router.use('/visits', authenticate, visitsRouter);
router.use('/lab-tests', authenticate, labTestsRouter);

// Additional routes would be added here:
// router.use('/pharmacy', pharmacyRouter);
// router.use('/appointments', appointmentsRouter);
// router.use('/counseling', counselingRouter);
// router.use('/alerts', alertsRouter);
// router.use('/adherence', adherenceRouter);
// router.use('/staff', staffRouter);
// router.use('/regimens', regimensRouter);

module.exports = router;

