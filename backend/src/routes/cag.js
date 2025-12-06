// ============================================================================
// CAG (Community ART Group) Routes
// HIV Patient Care & Treatment Monitoring System
// ============================================================================

const { Router } = require('express');
const { PrismaClient } = require('@prisma/client');
const { authorize } = require('../middleware/auth');

const router = Router();
const prisma = new PrismaClient();

// GET /api/cag - Get all CAGs
router.get('/', async (req, res) => {
  try {
    const { status, district, village, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    let whereClause = 'WHERE 1=1';
    const params = [];

    if (status) {
      whereClause += ' AND c.status = ?';
      params.push(status);
    }
    if (district) {
      whereClause += ' AND c.district = ?';
      params.push(district);
    }
    if (village) {
      whereClause += ' AND c.village = ?';
      params.push(village);
    }

    const [cags, totalResult] = await Promise.all([
      prisma.$queryRawUnsafe(`
        SELECT 
          c.cag_id,
          c.cag_name,
          c.district,
          c.subcounty,
          c.parish,
          c.village,
          c.formation_date,
          c.status,
          c.max_members,
          c.coordinator_patient_id,
          c.facility_staff_id,
          COUNT(DISTINCT pc.patient_id) AS current_member_count,
          CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS coordinator_name,
          CONCAT(sper.first_name, ' ', COALESCE(sper.other_name, ''), ' ', sper.last_name) AS facility_staff_name
        FROM cag c
        LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
        LEFT JOIN patient p_coord ON c.coordinator_patient_id = p_coord.patient_id
        LEFT JOIN person per ON p_coord.person_id = per.person_id
        LEFT JOIN staff s ON c.facility_staff_id = s.staff_id
        LEFT JOIN person sper ON s.person_id = sper.person_id
        ${whereClause}
        GROUP BY c.cag_id, c.cag_name, c.district, c.subcounty, c.parish, c.village, 
                 c.formation_date, c.status, c.max_members, c.coordinator_patient_id, 
                 c.facility_staff_id, per.first_name, per.other_name, per.last_name, 
                 sper.first_name, sper.other_name, sper.last_name
        ORDER BY c.cag_name
        LIMIT ? OFFSET ?
      `, ...params, take, skip),
      prisma.$queryRawUnsafe(`
        SELECT COUNT(DISTINCT c.cag_id) as total
        FROM cag c
        ${whereClause}
      `, ...params),
    ]);

    const total = Number(totalResult[0].total);

    res.json({
      data: cags,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    console.error('Get CAGs error:', error);
    res.status(500).json({ error: 'Failed to fetch CAGs' });
  }
});

// GET /api/cag/:id - Get CAG by ID
router.get('/:id', async (req, res) => {
  try {
    const cag = await prisma.$queryRawUnsafe(`
      SELECT 
        c.*,
        COUNT(DISTINCT pc.patient_id) AS current_member_count,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS coordinator_name,
        CONCAT(sper.first_name, ' ', COALESCE(sper.other_name, ''), ' ', sper.last_name) AS facility_staff_name
      FROM cag c
      LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
      LEFT JOIN patient p_coord ON c.coordinator_patient_id = p_coord.patient_id
      LEFT JOIN person per ON p_coord.person_id = per.person_id
      LEFT JOIN staff s ON c.facility_staff_id = s.staff_id
      LEFT JOIN person sper ON s.person_id = sper.person_id
      WHERE c.cag_id = ?
      GROUP BY c.cag_id
    `, parseInt(req.params.id));

    if (!cag || cag.length === 0) {
      return res.status(404).json({ error: 'CAG not found' });
    }

    res.json(cag[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch CAG' });
  }
});

// GET /api/cag/:id/members - Get CAG members
router.get('/:id/members', async (req, res) => {
  try {
    const members = await prisma.$queryRawUnsafe(`
      SELECT 
        pc.patient_cag_id,
        pc.patient_id,
        p.patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS patient_name,
        per.sex,
        TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) AS age,
        pc.join_date,
        pc.role_in_cag,
        p.current_status
      FROM patient_cag pc
      INNER JOIN patient p ON pc.patient_id = p.patient_id
      INNER JOIN person per ON p.person_id = per.person_id
      WHERE pc.cag_id = ? AND pc.is_active = TRUE
      ORDER BY pc.role_in_cag DESC, pc.join_date
    `, parseInt(req.params.id));

    res.json(members);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch CAG members' });
  }
});

// GET /api/cag/:id/rotations - Get CAG rotation history
router.get('/:id/rotations', async (req, res) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const rotations = await prisma.$queryRawUnsafe(`
      SELECT 
        cr.rotation_id,
        cr.rotation_date,
        cr.pickup_patient_id,
        p.patient_code AS pickup_patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS pickup_patient_name,
        cr.patients_served,
        cr.dispense_id,
        d.dispense_date,
        r.regimen_name,
        cr.notes
      FROM cag_rotation cr
      INNER JOIN patient p ON cr.pickup_patient_id = p.patient_id
      INNER JOIN person per ON p.person_id = per.person_id
      LEFT JOIN dispense d ON cr.dispense_id = d.dispense_id
      LEFT JOIN regimen r ON d.regimen_id = r.regimen_id
      WHERE cr.cag_id = ?
      ORDER BY cr.rotation_date DESC
      LIMIT ? OFFSET ?
    `, parseInt(req.params.id), take, skip);

    const totalResult = await prisma.$queryRawUnsafe(`
      SELECT COUNT(*) as total
      FROM cag_rotation
      WHERE cag_id = ?
    `, parseInt(req.params.id));

    const total = Number(totalResult[0].total);

    res.json({
      data: rotations,
      pagination: {
        page: parseInt(page),
        limit: take,
        total,
        pages: Math.ceil(total / take),
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch CAG rotations' });
  }
});

// GET /api/cag/:id/statistics - Get CAG statistics
router.get('/:id/statistics', async (req, res) => {
  try {
    const stats = await prisma.$queryRawUnsafe(`
      SELECT 
        COUNT(DISTINCT pc.patient_id) AS active_members,
        AVG(ad.adherence_percent) AS avg_adherence,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 95 THEN pc.patient_id END) AS excellent_adherence_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric < 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS suppressed_vl_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric >= 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS unsuppressed_vl_count,
        COUNT(DISTINCT cr.rotation_id) AS total_rotations,
        MAX(cr.rotation_date) AS last_rotation_date,
        MIN(cr.rotation_date) AS first_rotation_date
      FROM cag c
      LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
      LEFT JOIN adherence_log ad ON pc.patient_id = ad.patient_id
      LEFT JOIN lab_test lt ON pc.patient_id = lt.patient_id 
        AND lt.test_type = 'Viral Load' 
        AND lt.result_status = 'Completed'
        AND lt.test_date = (
          SELECT MAX(test_date) 
          FROM lab_test 
          WHERE patient_id = pc.patient_id 
            AND test_type = 'Viral Load' 
            AND result_status = 'Completed'
        )
      LEFT JOIN cag_rotation cr ON c.cag_id = cr.cag_id
      WHERE c.cag_id = ?
      GROUP BY c.cag_id
    `, parseInt(req.params.id));

    if (!stats || stats.length === 0) {
      return res.status(404).json({ error: 'CAG not found' });
    }

    res.json(stats[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch CAG statistics' });
  }
});

// POST /api/cag/:id/add-member - Add patient to CAG (requires admin or clinician)
router.post('/:id/add-member', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const { patientId, roleInCag } = req.body;

    // Call stored procedure
    await prisma.$executeRawUnsafe(`
      CALL sp_cag_add_patient(?, ?, ?)
    `, parseInt(req.params.id), parseInt(patientId), roleInCag || 'Member');

    // Get updated member list
    const members = await prisma.$queryRawUnsafe(`
      SELECT 
        pc.patient_cag_id,
        pc.patient_id,
        p.patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS patient_name,
        pc.join_date,
        pc.role_in_cag
      FROM patient_cag pc
      INNER JOIN patient p ON pc.patient_id = p.patient_id
      INNER JOIN person per ON p.person_id = per.person_id
      WHERE pc.cag_id = ? AND pc.is_active = TRUE
      ORDER BY pc.join_date DESC
    `, parseInt(req.params.id));

    res.json({ message: 'Patient added to CAG successfully', members });
  } catch (error) {
    console.error('Add CAG member error:', error);
    res.status(500).json({ error: 'Failed to add patient to CAG' });
  }
});

// POST /api/cag/:id/remove-member - Remove patient from CAG (requires admin or clinician)
router.post('/:id/remove-member', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const { patientId, exitReason } = req.body;

    // Call stored procedure
    await prisma.$executeRawUnsafe(`
      CALL sp_cag_remove_patient(?, ?, ?)
    `, parseInt(req.params.id), parseInt(patientId), exitReason || null);

    res.json({ message: 'Patient removed from CAG successfully' });
  } catch (error) {
    console.error('Remove CAG member error:', error);
    res.status(500).json({ error: 'Failed to remove patient from CAG' });
  }
});

// POST /api/cag/:id/rotation - Record CAG rotation (requires pharmacy or admin)
router.post('/:id/rotation', authorize('db_pharmacy', 'db_admin'), async (req, res) => {
  try {
    const { pickupPatientId, rotationDate, dispenseId, patientsServed, notes } = req.body;

    // Call stored procedure
    await prisma.$executeRawUnsafe(`
      CALL sp_cag_record_rotation(?, ?, ?, ?, ?, ?)
    `,
      parseInt(req.params.id),
      parseInt(pickupPatientId),
      new Date(rotationDate),
      dispenseId ? BigInt(dispenseId) : null,
      parseInt(patientsServed),
      notes || null
    );

    res.json({ message: 'CAG rotation recorded successfully' });
  } catch (error) {
    console.error('Record CAG rotation error:', error);
    res.status(500).json({ error: 'Failed to record CAG rotation' });
  }
});

// PUT /api/cag/:id/coordinator - Set CAG coordinator (requires admin or clinician)
router.put('/:id/coordinator', authorize('db_clinician', 'db_admin'), async (req, res) => {
  try {
    const { patientId } = req.body;

    // Call stored procedure
    await prisma.$executeRawUnsafe(`
      CALL sp_cag_set_coordinator(?, ?)
    `, parseInt(req.params.id), parseInt(patientId));

    // Get updated CAG
    const cag = await prisma.$queryRawUnsafe(`
      SELECT 
        c.*,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS coordinator_name
      FROM cag c
      LEFT JOIN patient p_coord ON c.coordinator_patient_id = p_coord.patient_id
      LEFT JOIN person per ON p_coord.person_id = per.person_id
      WHERE c.cag_id = ?
    `, parseInt(req.params.id));

    res.json({ message: 'CAG coordinator set successfully', cag: cag[0] });
  } catch (error) {
    console.error('Set CAG coordinator error:', error);
    res.status(500).json({ error: 'Failed to set CAG coordinator' });
  }
});

module.exports = router;



