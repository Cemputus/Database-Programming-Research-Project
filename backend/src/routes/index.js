// ============================================================================
// API Routes Index
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const authRouter = require('./auth');
const patientsRouter = require('./patients');
const visitsRouter = require('./visits');
const labTestsRouter = require('./lab-tests');
const pharmacyRouter = require('./pharmacy');
const appointmentsRouter = require('./appointments');
const counselingRouter = require('./counseling');
const alertsRouter = require('./alerts');
const adherenceRouter = require('./adherence');
const staffRouter = require('./staff');
const regimensRouter = require('./regimens');
const cagRouter = require('./cag');
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
router.use('/pharmacy', authenticate, pharmacyRouter);
router.use('/appointments', authenticate, appointmentsRouter);
router.use('/counseling', authenticate, counselingRouter);
router.use('/alerts', authenticate, alertsRouter);
router.use('/adherence', authenticate, adherenceRouter);
router.use('/staff', authenticate, staffRouter);
router.use('/regimens', authenticate, regimensRouter);
router.use('/cag', authenticate, cagRouter);

module.exports = router;

