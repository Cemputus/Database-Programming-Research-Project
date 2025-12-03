// ============================================================================
// Patient Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

// GET /api/patients - Get all patients
router.get('/', async (req, res) => {
  try {
    const { status, search, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const where: any = {};
    if (status) {
      where.currentStatus = status;
    }
    if (search) {
      where.OR = [
        { patientNumber: { contains: search as string } },
        { person: { firstName: { contains: search as string } } },
        { person: { lastName: { contains: search as string } } },
      ];
    }

    const [patients, total] = await Promise.all([
      prisma.patient.findMany({
        where,
        skip,
        take,
        include: {
          person: true,
        },
        orderBy: { enrollmentDate: 'desc' },
      }),
      prisma.patient.count({ where }),
    ]);

    res.json({
      data: patients,
      pagination: {
        page: parseInt(page as string),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patients' });
  }
});

// GET /api/patients/:id - Get patient by ID
router.get('/:id', async (req, res) => {
  try {
    const patient = await prisma.patient.findUnique({
      where: { patientId: parseInt(req.params.id) },
      include: {
        person: true,
        visits: {
          take: 10,
          orderBy: { visitDate: 'desc' },
          include: { staff: { include: { person: true } } },
        },
        labTests: {
          take: 10,
          orderBy: { testDate: 'desc' },
        },
        dispenses: {
          take: 10,
          orderBy: { dispenseDate: 'desc' },
          include: { regimen: true },
        },
        appointments: {
          take: 10,
          orderBy: { appointmentDate: 'desc' },
        },
        adherenceLogs: {
          take: 5,
          orderBy: { assessmentDate: 'desc' },
        },
        alerts: {
          where: { status: 'Active' },
          take: 10,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!patient) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient' });
  }
});

// POST /api/patients - Create new patient
router.post('/', async (req, res) => {
  try {
    const {
      nin,
      firstName,
      middleName,
      lastName,
      dateOfBirth,
      gender,
      phoneNumber,
      email,
      district,
      subcounty,
      parish,
      village,
      addressLine,
      patientNumber,
      enrollmentDate,
      artStartDate,
      baselineCd4,
      baselineVl,
      whoStage,
      tbStatus,
      pregnancyStatus,
      nextOfKinName,
      nextOfKinPhone,
      nextOfKinRelationship,
    } = req.body;

    // Create person first
    const person = await prisma.person.create({
      data: {
        nin,
        firstName,
        middleName,
        lastName,
        dateOfBirth: new Date(dateOfBirth),
        gender,
        phoneNumber,
        email,
        district,
        subcounty,
        parish,
        village,
        addressLine,
      },
    });

    // Create patient
    const patient = await prisma.patient.create({
      data: {
        personId: person.personId,
        patientNumber,
        enrollmentDate: new Date(enrollmentDate),
        artStartDate: artStartDate ? new Date(artStartDate) : null,
        baselineCd4,
        baselineVl: baselineVl ? parseFloat(baselineVl) : null,
        whoStage,
        tbStatus,
        pregnancyStatus,
        nextOfKinName,
        nextOfKinPhone,
        nextOfKinRelationship,
      },
      include: {
        person: true,
      },
    });

    res.status(201).json(patient);
  } catch (error: any) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Patient number or NIN already exists' });
    }
    res.status(500).json({ error: 'Failed to create patient' });
  }
});

// PUT /api/patients/:id - Update patient
router.put('/:id', async (req, res) => {
  try {
    const {
      artStartDate,
      currentStatus,
      whoStage,
      tbStatus,
      pregnancyStatus,
      nextOfKinName,
      nextOfKinPhone,
      nextOfKinRelationship,
    } = req.body;

    const patient = await prisma.patient.update({
      where: { patientId: parseInt(req.params.id) },
      data: {
        artStartDate: artStartDate ? new Date(artStartDate) : undefined,
        currentStatus,
        whoStage,
        tbStatus,
        pregnancyStatus,
        nextOfKinName,
        nextOfKinPhone,
        nextOfKinRelationship,
      },
      include: {
        person: true,
      },
    });

    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update patient' });
  }
});

// GET /api/patients/:id/timeline - Get patient care timeline
router.get('/:id/timeline', async (req, res) => {
  try {
    const patientId = parseInt(req.params.id);
    
    // This would typically use the v_patient_care_timeline view
    // For now, we'll aggregate data from multiple tables
    const [visits, labTests, dispenses, appointments] = await Promise.all([
      prisma.visit.findMany({
        where: { patientId },
        orderBy: { visitDate: 'desc' },
        include: { staff: { include: { person: true } } },
      }),
      prisma.labTest.findMany({
        where: { patientId },
        orderBy: { testDate: 'desc' },
      }),
      prisma.dispense.findMany({
        where: { patientId },
        orderBy: { dispenseDate: 'desc' },
        include: { regimen: true, staff: { include: { person: true } } },
      }),
      prisma.appointment.findMany({
        where: { patientId },
        orderBy: { appointmentDate: 'desc' },
      }),
    ]);

    const timeline = [
      ...visits.map(v => ({
        eventType: 'Visit',
        eventDate: v.visitDate,
        description: `Clinical visit - ${v.visitType}`,
        staffName: `${v.staff.person.firstName} ${v.staff.person.lastName}`,
      })),
      ...labTests.map(lt => ({
        eventType: 'Lab Test',
        eventDate: lt.testDate,
        description: `${lt.testType} - ${lt.resultValue || 'Pending'}`,
        staffName: null,
      })),
      ...dispenses.map(d => ({
        eventType: 'Dispense',
        eventDate: d.dispenseDate,
        description: `Medication dispensed - ${d.regimen.regimenName} (${d.daysSupply} days)`,
        staffName: `${d.staff.person.firstName} ${d.staff.person.lastName}`,
      })),
      ...appointments.map(a => ({
        eventType: 'Appointment',
        eventDate: a.appointmentDate,
        description: `Appointment - ${a.appointmentType} (${a.status})`,
        staffName: null,
      })),
    ].sort((a, b) => new Date(b.eventDate).getTime() - new Date(a.eventDate).getTime());

    res.json(timeline);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch timeline' });
  }
});

export default router;

