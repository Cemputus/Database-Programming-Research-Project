-- ============================================================================
-- DATA VERIFICATION SCRIPT
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- ============================================================================
-- This script verifies data integrity, completeness, and consistency
-- Run this after loading seed_data.sql to ensure all data is correct
-- ============================================================================

USE hiv_patient_care;

-- ============================================================================
-- SECTION 1: TABLE COUNT VERIFICATION
-- Verify that all expected tables have data
-- ============================================================================

SELECT '=== TABLE COUNT VERIFICATION ===' AS section;

-- Table count verification - wrapped to prevent LIMIT issues
SELECT * FROM (
    SELECT 
        'person' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM person
    UNION ALL
    SELECT 
        'patient' AS table_name,
        COUNT(*) AS record_count,
        'Expected: 747' AS expected
    FROM patient
    UNION ALL
    SELECT 
        'staff' AS table_name,
        COUNT(*) AS record_count,
        'Expected: 30' AS expected
    FROM staff
    UNION ALL
    SELECT 
        'role' AS table_name,
        COUNT(*) AS record_count,
        'Expected: 7' AS expected
    FROM role
    UNION ALL
    SELECT 
        'staff_role' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM staff_role
    UNION ALL
    SELECT 
        'visit' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM visit
    UNION ALL
    SELECT 
        'lab_test' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM lab_test
    UNION ALL
    SELECT 
        'regimen' AS table_name,
        COUNT(*) AS record_count,
        'Expected: 8' AS expected
    FROM regimen
    UNION ALL
    SELECT 
        'dispense' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM dispense
    UNION ALL
    SELECT 
        'appointment' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM appointment
    UNION ALL
    SELECT 
        'counseling_session' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM counseling_session
    UNION ALL
    SELECT 
        'cag' AS table_name,
        COUNT(*) AS record_count,
        'Expected: 30' AS expected
    FROM cag
    UNION ALL
    SELECT 
        'patient_cag' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM patient_cag
    UNION ALL
    SELECT 
        'cag_rotation' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM cag_rotation
    UNION ALL
    SELECT 
        'adherence_log' AS table_name,
        COUNT(*) AS record_count,
        'Expected: > 0' AS expected
    FROM adherence_log
    UNION ALL
    SELECT 
        'alert' AS table_name,
        COUNT(*) AS record_count,
        'Expected: >= 0' AS expected
    FROM alert
    UNION ALL
    SELECT 
        'audit_log' AS table_name,
        COUNT(*) AS record_count,
        'Expected: >= 0' AS expected
    FROM audit_log
) AS table_counts
ORDER BY table_name;

-- ============================================================================
-- SECTION 2: FOREIGN KEY INTEGRITY VERIFICATION
-- Check for orphaned records (broken foreign key references)
-- ============================================================================
-- Section Header: === FOREIGN KEY INTEGRITY CHECK ===
-- Note: Split into individual queries to avoid LIMIT issues with UNION ALL

-- Check for patients without person records
SELECT 
    'Orphaned patients (no person record)' AS check_type,
    COUNT(*) AS issue_count
FROM patient p
LEFT JOIN person per ON p.person_id = per.person_id
WHERE per.person_id IS NULL;

-- Check for staff without person records
SELECT 
    'Orphaned staff (no person record)' AS check_type,
    COUNT(*) AS issue_count
FROM staff s
LEFT JOIN person per ON s.person_id = per.person_id
WHERE per.person_id IS NULL;

-- Check for visits without valid patient
SELECT 
    'Orphaned visits (invalid patient_id)' AS check_type,
    COUNT(*) AS issue_count
FROM visit v
LEFT JOIN patient p ON v.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check for visits without valid staff
SELECT 
    'Orphaned visits (invalid staff_id)' AS check_type,
    COUNT(*) AS issue_count
FROM visit v
LEFT JOIN staff s ON v.staff_id = s.staff_id
WHERE s.staff_id IS NULL;

-- Check for lab tests without valid patient
SELECT 
    'Orphaned lab tests (invalid patient_id)' AS check_type,
    COUNT(*) AS issue_count
FROM lab_test lt
LEFT JOIN patient p ON lt.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check for lab tests with invalid visit_id
SELECT 
    'Lab tests with invalid visit_id' AS check_type,
    COUNT(*) AS issue_count
FROM lab_test lt
WHERE lt.visit_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM visit v WHERE v.visit_id = lt.visit_id);

-- Check for dispenses without valid patient
SELECT 
    'Orphaned dispenses (invalid patient_id)' AS check_type,
    COUNT(*) AS issue_count
FROM dispense d
LEFT JOIN patient p ON d.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check for dispenses without valid regimen
SELECT 
    'Orphaned dispenses (invalid regimen_id)' AS check_type,
    COUNT(*) AS issue_count
FROM dispense d
LEFT JOIN regimen r ON d.regimen_id = r.regimen_id
WHERE r.regimen_id IS NULL;

-- Check for patient_cag without valid patient
SELECT 
    'Orphaned patient_cag (invalid patient_id)' AS check_type,
    COUNT(*) AS issue_count
FROM patient_cag pc
LEFT JOIN patient p ON pc.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check for patient_cag without valid cag
SELECT 
    'Orphaned patient_cag (invalid cag_id)' AS check_type,
    COUNT(*) AS issue_count
FROM patient_cag pc
LEFT JOIN cag c ON pc.cag_id = c.cag_id
WHERE c.cag_id IS NULL;

-- ============================================================================
-- SECTION 3: DATA CONSISTENCY VERIFICATION
-- Check for logical inconsistencies and data quality issues
-- ============================================================================

SELECT '=== DATA CONSISTENCY CHECK ===' AS section;

-- Data consistency verification - wrapped to prevent LIMIT issues

    -- Check for patients with art_start_date before enrollment_date
    SELECT 
        'Patients with ART start before enrollment' AS check_type,
        COUNT(*) AS issue_count
    FROM patient
    WHERE art_start_date IS NOT NULL
      AND art_start_date < enrollment_date

    

    -- Check for future dates
    SELECT 
        'Visits with future dates' AS check_type,
        COUNT(*) AS issue_count
    FROM visit
    WHERE visit_date > CURDATE()

  

    SELECT 
        'Lab tests with future dates' AS check_type,
        COUNT(*) AS issue_count
    FROM lab_test
    WHERE test_date > CURDATE()

  

    SELECT 
        'Dispenses with future dates' AS check_type,
        COUNT(*) AS issue_count
    FROM dispense
    WHERE dispense_date > CURDATE()

    

    -- Check for invalid WHO stage
    SELECT 
        'Visits with invalid WHO stage' AS check_type,
        COUNT(*) AS issue_count
    FROM visit
    WHERE who_stage IS NOT NULL
      AND (who_stage < 1 OR who_stage > 4)

   

    -- Check for invalid adherence percentages
    SELECT 
        'Adherence logs with invalid percentages' AS check_type,
        COUNT(*) AS issue_count
    FROM adherence_log
    WHERE adherence_percent < 0 OR adherence_percent > 100

    UNION ALL

    -- Check for invalid days_supply
    SELECT 
        'Dispenses with invalid days_supply' AS check_type,
        COUNT(*) AS issue_count
    FROM dispense
    WHERE days_supply = 0 OR days_supply > 365

   

    -- Check for next_refill_date calculation errors
    SELECT 
        'Dispenses with incorrect next_refill_date' AS check_type,
        COUNT(*) AS issue_count
    FROM dispense
    WHERE next_refill_date != DATE_ADD(dispense_date, INTERVAL days_supply DAY)

   

    -- Check for patient_cag exit_date before join_date
    SELECT 
        'Patient_CAG with exit_date before join_date' AS check_type,
        COUNT(*) AS issue_count
    FROM patient_cag
    WHERE exit_date IS NOT NULL
      AND exit_date < join_date


-- ============================================================================
-- SECTION 4: UNIQUENESS VERIFICATION
-- Check for duplicate unique constraints
-- ============================================================================

SELECT '=== UNIQUENESS CHECK ===' AS section;

-- Uniqueness verification - wrapped to prevent LIMIT issues

    -- Check for duplicate NINs
    SELECT 
        'Duplicate NINs' AS check_type,
        COUNT(*) - COUNT(DISTINCT nin) AS duplicate_count
    FROM person

  

    -- Check for duplicate patient codes
    SELECT 
        'Duplicate patient codes' AS check_type,
        COUNT(*) - COUNT(DISTINCT patient_code) AS duplicate_count
    FROM patient



    -- Check for duplicate staff codes
    SELECT 
        'Duplicate staff codes' AS check_type,
        COUNT(*) - COUNT(DISTINCT staff_code) AS duplicate_count
    FROM staff

    

    -- Check for duplicate role names
    SELECT 
        'Duplicate role names' AS check_type,
        COUNT(*) - COUNT(DISTINCT role_name) AS duplicate_count
    FROM role

   

    -- Check for duplicate CAG names
    SELECT 
        'Duplicate CAG names' AS check_type,
        COUNT(*) - COUNT(DISTINCT cag_name) AS duplicate_count
    FROM cag

  

    -- Check for duplicate regimen codes
    SELECT 
        'Duplicate regimen codes' AS check_type,
        COUNT(*) - COUNT(DISTINCT regimen_code) AS duplicate_count
    FROM regimen


-- ============================================================================
-- SECTION 5: ENUM VALUE VERIFICATION
-- Verify all enum values are valid
-- ============================================================================

SELECT '=== ENUM VALUE VERIFICATION ===' AS section;

-- Enum value verification - wrapped to prevent LIMIT issues

    -- Check patient status values
    SELECT 
        'Invalid patient status values' AS check_type,
        COUNT(*) AS issue_count
    FROM patient
    WHERE current_status NOT IN ('Active', 'Transferred-Out', 'LTFU', 'Dead')

   

    -- Check staff cadre values
    SELECT 
        'Invalid staff cadre values' AS check_type,
        COUNT(*) AS issue_count
    FROM staff
    WHERE cadre NOT IN ('Doctor', 'Clinical Officer', 'Nurse', 'Midwife', 'Lab Technician', 'Pharmacist', 'Counselor', 'Records Officer')

  

    -- Check lab test types
    SELECT 
        'Invalid lab test types' AS check_type,
        COUNT(*) AS issue_count
    FROM lab_test
    WHERE test_type NOT IN ('Viral Load', 'CD4', 'HB', 'Creatinine', 'Malaria RDT', 'TB-LAM', 'Urinalysis')

   

    -- Check lab test result status
    SELECT 
        'Invalid lab test result_status' AS check_type,
        COUNT(*) AS issue_count
    FROM lab_test
    WHERE result_status NOT IN ('Pending', 'Completed', 'Rejected')


    -- Check appointment status
    SELECT 
        'Invalid appointment status' AS check_type,
        COUNT(*) AS issue_count
    FROM appointment
    WHERE status NOT IN ('Scheduled', 'Attended', 'Missed', 'Rescheduled', 'Cancelled')

    

    -- Check CAG status
    SELECT 
        'Invalid CAG status' AS check_type,
        COUNT(*) AS issue_count
    FROM cag
    WHERE status NOT IN ('Active', 'Inactive', 'Dissolved')

  

    -- Check adherence methods
    SELECT 
        'Invalid adherence method' AS check_type,
        COUNT(*) AS issue_count
    FROM adherence_log
    WHERE method_used NOT IN ('Pill Count', 'Pharmacy Refill', 'Self Report', 'CAG Report', 'Computed')

   

    -- Check alert types
    SELECT 
        'Invalid alert types' AS check_type,
        COUNT(*) AS issue_count
    FROM alert
    WHERE alert_type NOT IN ('High Viral Load', 'Overdue VL', 'Missed Appointment', 'Missed Refill', 'Low Adherence', 'Severe OI')


    -- Check alert levels
    SELECT 
        'Invalid alert levels' AS check_type,
        COUNT(*) AS issue_count
    FROM alert
    WHERE alert_level NOT IN ('Info', 'Warning', 'Critical')


-- ============================================================================
-- SECTION 6: REFERENTIAL DATA VERIFICATION
-- Check that related data exists where expected
-- ============================================================================

SELECT '=== REFERENTIAL DATA CHECK ===' AS section;

-- Referential data verification - wrapped to prevent LIMIT issues
    -- Check for patients without any visits
    SELECT 
        'Patients with no visits' AS check_type,
        COUNT(*) AS issue_count
    FROM patient p
    LEFT JOIN visit v ON p.patient_id = v.patient_id
    WHERE v.visit_id IS NULL
      AND p.current_status = 'Active'

   

    -- Check for active patients without any dispenses
    SELECT 
        'Active patients with no dispenses' AS check_type,
        COUNT(*) AS issue_count
    FROM patient p
    LEFT JOIN dispense d ON p.patient_id = d.patient_id
    WHERE d.dispense_id IS NULL
      AND p.current_status = 'Active'
      AND p.art_start_date IS NOT NULL



    -- Check for staff without roles
    SELECT 
        'Staff without assigned roles' AS check_type,
        COUNT(*) AS issue_count
    FROM staff s
    LEFT JOIN staff_role sr ON s.staff_id = sr.staff_id
    WHERE sr.staff_id IS NULL
      AND s.active = TRUE


    -- Check for CAGs without members
    SELECT 
        'CAGs without active members' AS check_type,
        COUNT(*) AS issue_count
    FROM cag c
    LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
    WHERE pc.patient_cag_id IS NULL
      AND c.status = 'Active'

   

    -- Check for CAGs without coordinators
    SELECT 
        'Active CAGs without coordinators' AS check_type,
        COUNT(*) AS issue_count
    FROM cag
    WHERE status = 'Active'
      AND coordinator_patient_id IS NULL


-- ============================================================================
-- SECTION 7: STATISTICAL SUMMARY
-- Overall data statistics
-- ============================================================================

SELECT '=== STATISTICAL SUMMARY ===' AS section;

-- Statistical summary - wrapped to prevent LIMIT issues
SELECT * FROM (
    SELECT 
        'Total Persons' AS metric,
        COUNT(*) AS value
    FROM person

    UNION ALL

    SELECT 
        'Total Patients' AS metric,
        COUNT(*) AS value
    FROM patient

    UNION ALL

    SELECT 
        'Active Patients' AS metric,
        COUNT(*) AS value
    FROM patient
    WHERE current_status = 'Active'

    UNION ALL

    SELECT 
        'Total Staff' AS metric,
        COUNT(*) AS value
    FROM staff

    UNION ALL

    SELECT 
        'Active Staff' AS metric,
        COUNT(*) AS value
    FROM staff
    WHERE active = TRUE

    UNION ALL

    SELECT 
        'Total Visits' AS metric,
        COUNT(*) AS value
    FROM visit

    UNION ALL

    SELECT 
        'Total Lab Tests' AS metric,
        COUNT(*) AS value
    FROM lab_test

    UNION ALL

    SELECT 
        'Completed Lab Tests' AS metric,
        COUNT(*) AS value
    FROM lab_test
    WHERE result_status = 'Completed'

    UNION ALL

    SELECT 
        'Total Dispenses' AS metric,
        COUNT(*) AS value
    FROM dispense

    UNION ALL

    SELECT 
        'Total Appointments' AS metric,
        COUNT(*) AS value
    FROM appointment

    UNION ALL

    SELECT 
        'Total CAGs' AS metric,
        COUNT(*) AS value
    FROM cag

    UNION ALL

    SELECT 
        'Active CAGs' AS metric,
        COUNT(*) AS value
    FROM cag
    WHERE status = 'Active'

    UNION ALL

    SELECT 
        'Total CAG Members' AS metric,
        COUNT(*) AS value
    FROM patient_cag
    WHERE is_active = TRUE

    UNION ALL

    SELECT 
        'Total Alerts' AS metric,
        COUNT(*) AS value
    FROM alert

    UNION ALL

    SELECT 
        'Active Alerts' AS metric,
        COUNT(*) AS value
    FROM alert
    WHERE is_resolved = FALSE
) AS statistical_summary
ORDER BY metric;

-- ============================================================================
-- SECTION 8: DATA RANGE VERIFICATION
-- Check for reasonable data ranges
-- ============================================================================

SELECT '=== DATA RANGE VERIFICATION ===' AS section;

-- Data range verification - wrapped to prevent LIMIT issues
SELECT * FROM (
    -- Check patient ages (should be reasonable)
    SELECT 
        'Patients with age < 0 or > 120' AS check_type,
        COUNT(*) AS issue_count
    FROM patient p
    INNER JOIN person per ON p.person_id = per.person_id
    WHERE TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 0
       OR TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) > 120

    UNION ALL

    -- Check for very old enrollment dates (before 2000)
    SELECT 
        'Patients enrolled before 2000' AS check_type,
        COUNT(*) AS issue_count
    FROM patient
    WHERE enrollment_date < '2000-01-01'

    UNION ALL

    -- Check for very high viral loads (might indicate data entry error)
    SELECT 
        'Viral loads > 10,000,000 copies/mL' AS check_type,
        COUNT(*) AS issue_count
    FROM lab_test
    WHERE test_type = 'Viral Load'
      AND result_numeric > 10000000

    UNION ALL

    -- Check for negative viral loads
    SELECT 
        'Negative viral loads' AS check_type,
        COUNT(*) AS issue_count
    FROM lab_test
    WHERE test_type = 'Viral Load'
      AND result_numeric < 0
) AS range_checks
ORDER BY check_type;

-- ============================================================================
-- VERIFICATION COMPLETE
-- Review all sections above. All issue_count values should be 0 for data integrity.
-- ============================================================================

SELECT '=== VERIFICATION COMPLETE ===' AS status,
       'Review all sections above. All issue_count values should be 0.' AS note;

