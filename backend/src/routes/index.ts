// ============================================================================
// API Routes Index
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

import { Router } from 'express';
import patientsRouter from './patients';
import visitsRouter from './visits';
import labTestsRouter from './lab-tests';
import { PrismaClient } from '@prisma/client';

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

export default router;

