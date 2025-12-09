-- ============================================================================
-- HIV Patient Care & Treatment Monitoring System
-- Additional Database Management Commands
-- This file contains ALTER commands, maintenance queries, and utility commands
-- ============================================================================

USE hiv_patient_care;

-- ============================================================================
-- ROLE AND USER MANAGEMENT
-- ============================================================================

-- View role assignments
SELECT * FROM mysql.role_edges;

-- When logged in as pharmacist1, run:
SELECT CURRENT_ROLE();
SHOW GRANTS FOR CURRENT_USER();

-- View all users and their roles
SELECT 
    user,
    host,
    account_locked,
    password_expired
FROM mysql.user
WHERE user LIKE 'doctor%' OR user LIKE 'lab_tech%' OR user LIKE 'pharmacist%' OR user LIKE 'counselor%' OR user LIKE 'nsubuga%' OR user LIKE 'records_officer%';

-- View all roles
SELECT * FROM mysql.role_edges WHERE TO_USER = 'db_admin' OR TO_USER = 'db_clinician' OR TO_USER = 'db_lab' OR TO_USER = 'db_pharmacy' OR TO_USER = 'db_counselor' OR TO_USER = 'db_readonly' OR TO_USER = 'db_patient';

-- ============================================================================
-- TABLE INFORMATION QUERIES
-- ============================================================================

SHOW tables;

-- View table structure
DESCRIBE person;
DESCRIBE patient;
DESCRIBE staff;
DESCRIBE visit;
DESCRIBE lab_test;

-- Get detailed table information
SHOW CREATE TABLE patient;
SHOW CREATE TABLE visit;
SHOW CREATE TABLE lab_test;

-- View all indexes on a table
SHOW INDEX FROM patient;
SHOW INDEX FROM visit;
SHOW INDEX FROM lab_test;

-- View foreign key constraints
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'hiv_patient_care'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ============================================================================
-- ALTER TABLE COMMANDS - ADD COLUMNS
-- ============================================================================

-- Add a new column to person table (example: email)
-- ALTER TABLE person ADD COLUMN email VARCHAR(100) DEFAULT NULL COMMENT 'Email address' AFTER phone_contact;

-- Add a new column to patient table (example: preferred_language)
-- ALTER TABLE patient ADD COLUMN preferred_language VARCHAR(50) DEFAULT 'English' COMMENT 'Preferred communication language' AFTER treatment_partner;

-- Add a new column to visit table (example: visit_duration_minutes)
-- ALTER TABLE visit ADD COLUMN visit_duration_minutes INT UNSIGNED DEFAULT NULL COMMENT 'Visit duration in minutes' AFTER next_appointment_date;

-- Add a new column to lab_test table (example: lab_facility)
-- ALTER TABLE lab_test ADD COLUMN lab_facility VARCHAR(100) DEFAULT NULL COMMENT 'Laboratory facility name' AFTER cphl_sample_id;

-- Add a new column to staff table (example: email)
-- ALTER TABLE staff ADD COLUMN email VARCHAR(100) DEFAULT NULL COMMENT 'Staff email address' AFTER moH_registration_no;

-- ============================================================================
-- ALTER TABLE COMMANDS - MODIFY COLUMNS
-- ============================================================================

-- Modify column data type (example: increase phone_contact length)
-- ALTER TABLE person MODIFY COLUMN phone_contact VARCHAR(30) DEFAULT NULL COMMENT 'Phone number (Uganda format: +256...)';

-- Modify column to add default value
-- ALTER TABLE visit MODIFY COLUMN who_stage TINYINT UNSIGNED DEFAULT 1 COMMENT 'WHO clinical staging (1-4)';

-- Modify column to change NULL constraint
-- ALTER TABLE patient MODIFY COLUMN next_of_kin VARCHAR(150) NOT NULL COMMENT 'NOK name';

-- Modify column to change comment
-- ALTER TABLE lab_test MODIFY COLUMN result_numeric DECIMAL(18,4) DEFAULT NULL COMMENT 'For numeric results (VL, CD4, etc.) - Updated precision';

-- ============================================================================
-- ALTER TABLE COMMANDS - ADD INDEXES
-- ============================================================================

-- Add index for performance optimization
-- ALTER TABLE person ADD INDEX idx_phone_contact (phone_contact);

-- Add composite index
-- ALTER TABLE visit ADD INDEX idx_staff_date (staff_id, visit_date DESC);

-- Add unique index
-- ALTER TABLE patient ADD UNIQUE INDEX uk_enrollment_code (enrollment_date, patient_code);

-- Add full-text index (for text search)
-- ALTER TABLE visit ADD FULLTEXT INDEX ft_symptoms (symptoms);

-- ============================================================================
-- ALTER TABLE COMMANDS - DROP COLUMNS/INDEXES
-- ============================================================================

-- Drop a column (use with caution - backup first!)
-- ALTER TABLE person DROP COLUMN email;

-- Drop an index
-- ALTER TABLE person DROP INDEX idx_phone_contact;

-- Drop a foreign key constraint
-- ALTER TABLE visit DROP FOREIGN KEY fk_visit_patient;

-- ============================================================================
-- ALTER TABLE COMMANDS - RENAME
-- ============================================================================

-- Rename a column
-- ALTER TABLE person CHANGE COLUMN phone_contact phone_number VARCHAR(20) DEFAULT NULL COMMENT 'Phone number (Uganda format: +256...)';

-- Rename a table
-- ALTER TABLE counseling_session RENAME TO counseling;

-- ============================================================================
-- ALTER TABLE COMMANDS - ADD CONSTRAINTS
-- ============================================================================

-- Add check constraint (MySQL 8.0.16+)
-- ALTER TABLE visit ADD CONSTRAINT chk_weight_positive CHECK (weight_kg IS NULL OR weight_kg > 0);

-- Add foreign key constraint
-- ALTER TABLE visit ADD CONSTRAINT fk_visit_patient_new FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- ALTER TABLE COMMANDS - MODIFY TABLE OPTIONS
-- ============================================================================

-- Change table engine
-- ALTER TABLE person ENGINE = InnoDB;

-- Change table character set
-- ALTER TABLE person CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Change auto_increment value
-- ALTER TABLE patient AUTO_INCREMENT = 1000;

-- ============================================================================
-- DATA QUERIES AND ANALYSIS
-- ============================================================================

USE hiv_patient_care;

-- Sample data queries
SELECT * FROM person LIMIT 5;
SELECT * FROM patient LIMIT 5;
SELECT * FROM staff LIMIT 5;

-- Count records in each table
SELECT 
    'person' AS table_name, COUNT(*) AS record_count FROM person
UNION ALL
SELECT 'patient', COUNT(*) FROM patient
UNION ALL
SELECT 'staff', COUNT(*) FROM staff
UNION ALL
SELECT 'visit', COUNT(*) FROM visit
UNION ALL
SELECT 'lab_test', COUNT(*) FROM lab_test
UNION ALL
SELECT 'dispense', COUNT(*) FROM dispense
UNION ALL
SELECT 'appointment', COUNT(*) FROM appointment
UNION ALL
SELECT 'counseling_session', COUNT(*) FROM counseling_session
UNION ALL
SELECT 'cag', COUNT(*) FROM cag
UNION ALL
SELECT 'patient_cag', COUNT(*) FROM patient_cag
UNION ALL
SELECT 'adherence_log', COUNT(*) FROM adherence_log
UNION ALL
SELECT 'alert', COUNT(*) FROM alert
UNION ALL
SELECT 'audit_log', COUNT(*) FROM audit_log
ORDER BY record_count DESC;

-- ============================================================================
-- TABLE SIZE AND STATISTICS
-- ============================================================================

-- View table sizes
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
    ROUND((data_length / 1024 / 1024), 2) AS 'Data (MB)',
    ROUND((index_length / 1024 / 1024), 2) AS 'Index (MB)',
    table_rows AS 'Rows'
FROM information_schema.TABLES
WHERE table_schema = 'hiv_patient_care'
ORDER BY (data_length + index_length) DESC;

-- View column statistics
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'hiv_patient_care'
  AND TABLE_NAME = 'patient'
ORDER BY ORDINAL_POSITION;

-- ============================================================================
-- PERFORMANCE AND MAINTENANCE
-- ============================================================================

-- Analyze table (update statistics)
ANALYZE TABLE patient, visit, lab_test, dispense;

-- Optimize table (reclaim unused space)
-- OPTIMIZE TABLE patient, visit, lab_test;

-- Check table status
SHOW TABLE STATUS FROM hiv_patient_care WHERE Name IN ('patient', 'visit', 'lab_test');

-- View table locks
SHOW OPEN TABLES WHERE In_use > 0;

-- View process list
SHOW PROCESSLIST;

-- View current connections
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- ============================================================================
-- FOREIGN KEY INFORMATION
-- ============================================================================

-- View all foreign keys in database
SELECT 
    k.CONSTRAINT_NAME,
    k.TABLE_NAME,
    k.COLUMN_NAME,
    k.REFERENCED_TABLE_NAME,
    k.REFERENCED_COLUMN_NAME,
    r.UPDATE_RULE,
    r.DELETE_RULE
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.REFERENTIAL_CONSTRAINTS r
    ON k.CONSTRAINT_NAME = r.CONSTRAINT_NAME
    AND k.TABLE_SCHEMA = r.CONSTRAINT_SCHEMA
WHERE k.TABLE_SCHEMA = 'hiv_patient_care'
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.CONSTRAINT_NAME;

-- ============================================================================
-- CONSTRAINT INFORMATION
-- ============================================================================

-- View all check constraints
SELECT 
    cc.CONSTRAINT_NAME,
    tc.TABLE_NAME,
    cc.CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS cc
JOIN information_schema.TABLE_CONSTRAINTS tc
    ON cc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    AND cc.CONSTRAINT_SCHEMA = tc.TABLE_SCHEMA
WHERE cc.CONSTRAINT_SCHEMA = 'hiv_patient_care'
ORDER BY tc.TABLE_NAME, cc.CONSTRAINT_NAME;

-- View all unique constraints
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'hiv_patient_care'
  AND CONSTRAINT_NAME LIKE 'uk_%'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ============================================================================
-- VIEW AND PROCEDURE INFORMATION
-- ============================================================================

-- List all views
SELECT 
    TABLE_NAME AS view_name,
    VIEW_DEFINITION
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'hiv_patient_care'
ORDER BY TABLE_NAME;

-- List all stored procedures
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hiv_patient_care'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;

-- List all triggers
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    ACTION_STATEMENT
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'hiv_patient_care'
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;

-- List all events
SELECT 
    EVENT_NAME,
    EVENT_DEFINITION,
    INTERVAL_VALUE,
    INTERVAL_FIELD,
    STATUS,
    LAST_EXECUTED,
    EXECUTE_AT,
    STARTS,
    ENDS
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = 'hiv_patient_care'
ORDER BY EVENT_NAME;

-- ============================================================================
-- DATABASE MAINTENANCE COMMANDS
-- ============================================================================

-- Flush tables (close all open tables)
-- FLUSH TABLES;

-- Flush logs
-- FLUSH LOGS;

-- Check database integrity
-- CHECK TABLE patient, visit, lab_test;

-- Repair table (if needed)
-- REPAIR TABLE patient;

-- ============================================================================
-- BACKUP AND RESTORE COMMANDS (for reference - run from command line)
-- ============================================================================

-- Full database backup:
-- mysqldump -u root -p hiv_patient_care > backup_hiv_patient_care_$(date +\%Y\%m\%d).sql

-- Backup with structure and data:
-- mysqldump -u root -p --routines --triggers hiv_patient_care > full_backup.sql

-- Backup only structure:
-- mysqldump -u root -p --no-data hiv_patient_care > structure_only.sql

-- Backup only data:
-- mysqldump -u root -p --no-create-info hiv_patient_care > data_only.sql

-- Restore database:
-- mysql -u root -p hiv_patient_care < backup_hiv_patient_care_20241208.sql

-- ============================================================================
-- USEFUL ADMINISTRATIVE QUERIES
-- ============================================================================

-- View database character set and collation
SELECT 
    DEFAULT_CHARACTER_SET_NAME,
    DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'hiv_patient_care';

-- View MySQL version
SELECT VERSION();

-- View current database
SELECT DATABASE();

-- View current user
SELECT USER(), CURRENT_USER();

-- View system variables
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';
SHOW VARIABLES LIKE 'event_scheduler';

-- Enable event scheduler (if needed)
-- SET GLOBAL event_scheduler = ON;

-- ============================================================================
-- DATA VALIDATION QUERIES
-- ============================================================================

-- Find patients with invalid enrollment dates (future dates)
SELECT 
    patient_id,
    patient_code,
    enrollment_date,
    art_start_date
FROM patient
WHERE enrollment_date > CURDATE()
   OR (art_start_date IS NOT NULL AND art_start_date < enrollment_date);

-- Find visits with future dates
SELECT 
    visit_id,
    patient_id,
    visit_date
FROM visit
WHERE visit_date > CURDATE();

-- Find lab tests with invalid dates
SELECT 
    lab_test_id,
    patient_id,
    test_type,
    test_date
FROM lab_test
WHERE test_date > CURDATE();

-- Find patients with missing required data
SELECT 
    p.patient_id,
    p.patient_code,
    per.first_name,
    per.last_name,
    per.nin
FROM patient p
JOIN person per ON p.person_id = per.person_id
WHERE per.nin IS NULL 
   OR per.first_name IS NULL 
   OR per.last_name IS NULL
   OR p.enrollment_date IS NULL;

-- ============================================================================
-- TEST SCRIPTS FOR STORED PROCEDURES, TRIGGERS, CONSTRAINTS, AND PRIVILEGES
-- ============================================================================

-- ============================================================================
-- TEST SECTION 1: STORED PROCEDURES TESTING
-- ============================================================================

-- Test 1.1: sp_compute_adherence
-- Test adherence calculation for a patient
SELECT '=== TEST 1.1: sp_compute_adherence ===' AS test_name;
-- Get a patient with dispense records
SELECT @test_patient_id := patient_id FROM (
    SELECT DISTINCT patient_id FROM dispense LIMIT 1
) AS temp_patient LIMIT 1;
-- Test the procedure
CALL sp_compute_adherence(@test_patient_id, DATE_SUB(CURDATE(), INTERVAL 90 DAY), CURDATE());
-- Verify result was saved
SELECT * FROM adherence_log 
WHERE patient_id = @test_patient_id 
  AND method_used = 'Computed' 
ORDER BY log_date DESC LIMIT 1;

-- Test 1.2: sp_check_overdue_vl
SELECT '=== TEST 1.2: sp_check_overdue_vl ===' AS test_name;
-- Count alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'Overdue VL' AND is_resolved = FALSE;
-- Run procedure
CALL sp_check_overdue_vl();
-- Count alerts after
SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'Overdue VL' AND is_resolved = FALSE;

-- Test 1.3: sp_mark_missed_appointments
SELECT '=== TEST 1.3: sp_mark_missed_appointments ===' AS test_name;
-- Count missed appointments before
SELECT COUNT(*) AS missed_before FROM appointment WHERE status = 'Missed';
-- Run procedure
CALL sp_mark_missed_appointments(14);
-- Count missed appointments after
SELECT COUNT(*) AS missed_after FROM appointment WHERE status = 'Missed';

-- Test 1.4: sp_update_patient_status_ltfu
SELECT '=== TEST 1.4: sp_update_patient_status_ltfu ===' AS test_name;
-- Count LTFU patients before
SELECT COUNT(*) AS ltfu_before FROM patient WHERE current_status = 'LTFU';
-- Run procedure
CALL sp_update_patient_status_ltfu();
-- Count LTFU patients after
SELECT COUNT(*) AS ltfu_after FROM patient WHERE current_status = 'LTFU';

-- Test 1.5: sp_check_missed_refills
SELECT '=== TEST 1.5: sp_check_missed_refills ===' AS test_name;
-- Count missed refill alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'Missed Refill' AND is_resolved = FALSE;
-- Run procedure
CALL sp_check_missed_refills();
-- Count missed refill alerts after
SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'Missed Refill' AND is_resolved = FALSE;

-- Test 1.6: sp_patient_dashboard
SELECT '=== TEST 1.6: sp_patient_dashboard ===' AS test_name;
-- Get a patient code
SELECT @test_patient_code := patient_code FROM patient LIMIT 1;
-- Test the procedure
CALL sp_patient_dashboard(@test_patient_code);

-- Test 1.7: sp_patient_visits
SELECT '=== TEST 1.7: sp_patient_visits ===' AS test_name;
CALL sp_patient_visits(@test_patient_code, 10);

-- Test 1.8: sp_patient_lab_tests
SELECT '=== TEST 1.8: sp_patient_lab_tests ===' AS test_name;
CALL sp_patient_lab_tests(@test_patient_code, 'Viral Load', 10);
CALL sp_patient_lab_tests(@test_patient_code, NULL, 10);

-- Test 1.9: sp_patient_medications
SELECT '=== TEST 1.9: sp_patient_medications ===' AS test_name;
CALL sp_patient_medications(@test_patient_code, 10);

-- Test 1.10: sp_patient_appointments
SELECT '=== TEST 1.10: sp_patient_appointments ===' AS test_name;
CALL sp_patient_appointments(@test_patient_code, 'Scheduled', 10);
CALL sp_patient_appointments(@test_patient_code, NULL, 10);

-- Test 1.11: sp_patient_adherence
SELECT '=== TEST 1.11: sp_patient_adherence ===' AS test_name;
CALL sp_patient_adherence(@test_patient_code, 12);

-- Test 1.12: sp_patient_alerts
SELECT '=== TEST 1.12: sp_patient_alerts ===' AS test_name;
CALL sp_patient_alerts(@test_patient_code, FALSE, 20);
CALL sp_patient_alerts(@test_patient_code, TRUE, 20);

-- Test 1.13: sp_patient_progress_timeline
SELECT '=== TEST 1.13: sp_patient_progress_timeline ===' AS test_name;
CALL sp_patient_progress_timeline(@test_patient_code, DATE_SUB(CURDATE(), INTERVAL 365 DAY), CURDATE(), 50);

-- Test 1.14: sp_patient_next_appointment
SELECT '=== TEST 1.14: sp_patient_next_appointment ===' AS test_name;
CALL sp_patient_next_appointment(@test_patient_code);

-- Test 1.15: sp_patient_summary_stats
SELECT '=== TEST 1.15: sp_patient_summary_stats ===' AS test_name;
CALL sp_patient_summary_stats(@test_patient_code);

-- Test 1.16: sp_cag_add_patient
SELECT '=== TEST 1.16: sp_cag_add_patient ===' AS test_name;
-- Get an active CAG and active patient
SELECT @test_cag_id := cag_id FROM cag WHERE status = 'Active' LIMIT 1;
SELECT @test_patient_id := patient_id FROM patient WHERE current_status = 'Active' LIMIT 1;
-- Remove patient from CAG first if exists
UPDATE patient_cag SET is_active = FALSE WHERE patient_id = @test_patient_id AND cag_id = @test_cag_id;
-- Test adding patient
CALL sp_cag_add_patient(@test_patient_id, @test_cag_id, 'Member');

-- Test 1.17: sp_cag_remove_patient
SELECT '=== TEST 1.17: sp_cag_remove_patient ===' AS test_name;
-- Only test if patient is in CAG
SELECT COUNT(*) INTO @in_cag FROM patient_cag WHERE patient_id = @test_patient_id AND cag_id = @test_cag_id AND is_active = TRUE;
IF @in_cag > 0 THEN
    CALL sp_cag_remove_patient(@test_patient_id, @test_cag_id, 'Test removal');
END IF;

-- Test 1.18: sp_cag_get_members
SELECT '=== TEST 1.18: sp_cag_get_members ===' AS test_name;
CALL sp_cag_get_members(@test_cag_id);

-- Test 1.19: sp_cag_get_rotations
SELECT '=== TEST 1.19: sp_cag_get_rotations ===' AS test_name;
CALL sp_cag_get_rotations(@test_cag_id, DATE_SUB(CURDATE(), INTERVAL 365 DAY), CURDATE());

-- Test 1.20: sp_cag_get_statistics
SELECT '=== TEST 1.20: sp_cag_get_statistics ===' AS test_name;
CALL sp_cag_get_statistics(@test_cag_id);

-- ============================================================================
-- TEST SECTION 2: TRIGGERS TESTING
-- ============================================================================

-- Test 2.1: trg_lab_test_high_vl_alert (INSERT trigger)
SELECT '=== TEST 2.1: trg_lab_test_high_vl_alert (INSERT) ===' AS test_name;
-- Count alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'High Viral Load' AND is_resolved = FALSE;
-- Get a patient and staff ID
SELECT @test_patient_id := patient_id FROM patient LIMIT 1;
SELECT @test_staff_id := staff_id FROM staff LIMIT 1;
-- Insert a high VL test (should trigger alert)
INSERT INTO lab_test (
    patient_id, staff_id, test_type, test_date, 
    result_numeric, result_status, units
) VALUES (
    @test_patient_id, @test_staff_id, 'Viral Load', CURDATE(),
    5000, 'Completed', 'copies/mL'
);
-- Count alerts after
SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'High Viral Load' AND is_resolved = FALSE;
-- Verify alert was created
SELECT * FROM alert 
WHERE patient_id = @test_patient_id 
  AND alert_type = 'High Viral Load' 
  AND is_resolved = FALSE 
ORDER BY triggered_at DESC LIMIT 1;

-- Test 2.2: trg_lab_test_high_vl_alert_update (UPDATE trigger)
SELECT '=== TEST 2.2: trg_lab_test_high_vl_alert_update (UPDATE) ===' AS test_name;
-- Get a lab test with low VL
SELECT @test_lab_id := lab_test_id FROM lab_test 
WHERE test_type = 'Viral Load' 
  AND result_numeric < 1000 
  AND result_status = 'Completed' 
LIMIT 1;
-- Count alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'High Viral Load' AND is_resolved = FALSE;
-- Update to high VL (should trigger alert)
IF @test_lab_id IS NOT NULL THEN
    UPDATE lab_test 
    SET result_numeric = 2000, result_status = 'Completed'
    WHERE lab_test_id = @test_lab_id;
    -- Count alerts after
    SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'High Viral Load' AND is_resolved = FALSE;
END IF;

-- Test 2.3: trg_appointment_missed_alert (UPDATE trigger)
SELECT '=== TEST 2.3: trg_appointment_missed_alert (UPDATE) ===' AS test_name;
-- Get a scheduled appointment
SELECT @test_appt_id := appointment_id FROM appointment 
WHERE status = 'Scheduled' 
LIMIT 1;
-- Count alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'Missed Appointment' AND is_resolved = FALSE;
-- Update to missed (should trigger alert)
IF @test_appt_id IS NOT NULL THEN
    UPDATE appointment 
    SET status = 'Missed'
    WHERE appointment_id = @test_appt_id;
    -- Count alerts after
    SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'Missed Appointment' AND is_resolved = FALSE;
END IF;

-- Test 2.4: trg_patient_audit_insert (INSERT trigger)
SELECT '=== TEST 2.4: trg_patient_audit_insert (INSERT) ===' AS test_name;
-- Count audit logs before
SELECT COUNT(*) AS audit_before FROM audit_log WHERE table_name = 'patient';
-- Note: Cannot easily test patient insert without creating a person first
-- This is a verification query
SELECT * FROM audit_log 
WHERE table_name = 'patient' 
  AND action = 'INSERT' 
ORDER BY action_time DESC LIMIT 5;

-- Test 2.5: trg_patient_audit_update (UPDATE trigger)
SELECT '=== TEST 2.5: trg_patient_audit_update (UPDATE) ===' AS test_name;
-- Get a patient
SELECT @test_patient_id := patient_id FROM patient LIMIT 1;
-- Count audit logs before
SELECT COUNT(*) AS audit_before FROM audit_log WHERE table_name = 'patient' AND action = 'UPDATE';
-- Update patient (should trigger audit)
UPDATE patient 
SET next_of_kin = 'Test NOK Update'
WHERE patient_id = @test_patient_id;
-- Count audit logs after
SELECT COUNT(*) AS audit_after FROM audit_log WHERE table_name = 'patient' AND action = 'UPDATE';
-- Verify audit entry
SELECT * FROM audit_log 
WHERE table_name = 'patient' 
  AND action = 'UPDATE' 
  AND record_id = CAST(@test_patient_id AS CHAR)
ORDER BY action_time DESC LIMIT 1;

-- Test 2.6: trg_visit_audit_insert (INSERT trigger)
SELECT '=== TEST 2.6: trg_visit_audit_insert (INSERT) ===' AS test_name;
-- Count audit logs before
SELECT COUNT(*) AS audit_before FROM audit_log WHERE table_name = 'visit';
-- Get patient and staff
SELECT @test_patient_id := patient_id FROM patient LIMIT 1;
SELECT @test_staff_id := staff_id FROM staff LIMIT 1;
-- Insert visit (should trigger audit)
INSERT INTO visit (patient_id, staff_id, visit_date, who_stage)
VALUES (@test_patient_id, @test_staff_id, CURDATE(), 1);
-- Count audit logs after
SELECT COUNT(*) AS audit_after FROM audit_log WHERE table_name = 'visit';
-- Verify audit entry
SELECT * FROM audit_log 
WHERE table_name = 'visit' 
ORDER BY action_time DESC LIMIT 1;

-- Test 2.7: trg_lab_test_audit_insert (INSERT trigger)
SELECT '=== TEST 2.7: trg_lab_test_audit_insert (INSERT) ===' AS test_name;
-- Count audit logs before
SELECT COUNT(*) AS audit_before FROM audit_log WHERE table_name = 'lab_test';
-- Insert lab test (should trigger audit)
INSERT INTO lab_test (patient_id, staff_id, test_type, test_date, result_status)
VALUES (@test_patient_id, @test_staff_id, 'CD4', CURDATE(), 'Pending');
-- Count audit logs after
SELECT COUNT(*) AS audit_after FROM audit_log WHERE table_name = 'lab_test';
-- Verify audit entry
SELECT * FROM audit_log 
WHERE table_name = 'lab_test' 
ORDER BY action_time DESC LIMIT 1;

-- Test 2.8: trg_dispense_audit_insert (INSERT trigger)
SELECT '=== TEST 2.8: trg_dispense_audit_insert (INSERT) ===' AS test_name;
-- Count audit logs before
SELECT COUNT(*) AS audit_before FROM audit_log WHERE table_name = 'dispense';
-- Get regimen and staff
SELECT @test_regimen_id := regimen_id FROM regimen LIMIT 1;
SELECT @test_staff_id := staff_id FROM staff WHERE cadre = 'Pharmacist' LIMIT 1;
-- Insert dispense (should trigger audit)
IF @test_regimen_id IS NOT NULL AND @test_staff_id IS NOT NULL THEN
    INSERT INTO dispense (patient_id, staff_id, regimen_id, dispense_date, days_supply, quantity_dispensed, next_refill_date)
    VALUES (@test_patient_id, @test_staff_id, @test_regimen_id, CURDATE(), 30, 90, DATE_ADD(CURDATE(), INTERVAL 30 DAY));
    -- Count audit logs after
    SELECT COUNT(*) AS audit_after FROM audit_log WHERE table_name = 'dispense';
    -- Verify audit entry
    SELECT * FROM audit_log 
    WHERE table_name = 'dispense' 
    ORDER BY action_time DESC LIMIT 1;
END IF;

-- Test 2.9: trg_adherence_low_alert (INSERT trigger)
SELECT '=== TEST 2.9: trg_adherence_low_alert (INSERT) ===' AS test_name;
-- Count alerts before
SELECT COUNT(*) AS alerts_before FROM alert WHERE alert_type = 'Low Adherence' AND is_resolved = FALSE;
-- Insert low adherence (should trigger alert)
INSERT INTO adherence_log (patient_id, log_date, adherence_percent, method_used)
VALUES (@test_patient_id, CURDATE(), 75.00, 'Self Report');
-- Count alerts after
SELECT COUNT(*) AS alerts_after FROM alert WHERE alert_type = 'Low Adherence' AND is_resolved = FALSE;
-- Verify alert was created
SELECT * FROM alert 
WHERE patient_id = @test_patient_id 
  AND alert_type = 'Low Adherence' 
  AND is_resolved = FALSE 
ORDER BY triggered_at DESC LIMIT 1;

-- ============================================================================
-- TEST SECTION 3: CONSTRAINT TESTING
-- ============================================================================

-- Test 3.1: CHECK CONSTRAINT - chk_art_after_enrollment
SELECT '=== TEST 3.1: CHECK CONSTRAINT chk_art_after_enrollment ===' AS test_name;
-- This should FAIL (art_start_date before enrollment_date)
-- Uncomment to test:
-- UPDATE patient SET art_start_date = DATE_SUB(enrollment_date, INTERVAL 1 DAY) WHERE patient_id = @test_patient_id;
-- This should SUCCEED
UPDATE patient SET art_start_date = enrollment_date WHERE patient_id = @test_patient_id AND art_start_date IS NULL;
SELECT 'Constraint test: art_start_date must be >= enrollment_date' AS result;

-- Test 3.2: CHECK CONSTRAINT - chk_who_stage_range
SELECT '=== TEST 3.2: CHECK CONSTRAINT chk_who_stage_range ===' AS test_name;
-- This should FAIL (WHO stage out of range)
-- Uncomment to test:
-- INSERT INTO visit (patient_id, staff_id, visit_date, who_stage) VALUES (@test_patient_id, @test_staff_id, CURDATE(), 5);
-- This should SUCCEED
INSERT INTO visit (patient_id, staff_id, visit_date, who_stage) VALUES (@test_patient_id, @test_staff_id, CURDATE(), 2);
SELECT 'Constraint test: who_stage must be between 1 and 4' AS result;

-- Test 3.3: CHECK CONSTRAINT - chk_days_supply_range
SELECT '=== TEST 3.3: CHECK CONSTRAINT chk_days_supply_range ===' AS test_name;
-- This should FAIL (days_supply out of range)
-- Uncomment to test:
-- INSERT INTO dispense (patient_id, staff_id, regimen_id, dispense_date, days_supply, quantity_dispensed, next_refill_date) 
-- VALUES (@test_patient_id, @test_staff_id, @test_regimen_id, CURDATE(), 400, 1200, DATE_ADD(CURDATE(), INTERVAL 400 DAY));
-- This should SUCCEED
SELECT 'Constraint test: days_supply must be between 1 and 365' AS result;

-- Test 3.4: CHECK CONSTRAINT - chk_adherence_range
SELECT '=== TEST 3.4: CHECK CONSTRAINT chk_adherence_range ===' AS test_name;
-- This should FAIL (adherence out of range)
-- Uncomment to test:
-- INSERT INTO adherence_log (patient_id, log_date, adherence_percent, method_used) 
-- VALUES (@test_patient_id, CURDATE(), 150.00, 'Self Report');
-- This should SUCCEED
INSERT INTO adherence_log (patient_id, log_date, adherence_percent, method_used) 
VALUES (@test_patient_id, CURDATE(), 95.00, 'Self Report');
SELECT 'Constraint test: adherence_percent must be between 0 and 100' AS result;

-- Test 3.5: CHECK CONSTRAINT - chk_exit_date_after_join
SELECT '=== TEST 3.5: CHECK CONSTRAINT chk_exit_date_after_join ===' AS test_name;
-- This should FAIL (exit_date before join_date)
-- Uncomment to test:
-- UPDATE patient_cag SET exit_date = DATE_SUB(join_date, INTERVAL 1 DAY) WHERE patient_cag_id = 1;
-- This should SUCCEED
SELECT 'Constraint test: exit_date must be >= join_date' AS result;

-- Test 3.6: CHECK CONSTRAINT - chk_vl_result_non_negative
SELECT '=== TEST 3.6: CHECK CONSTRAINT chk_vl_result_non_negative ===' AS test_name;
-- This should FAIL (negative VL)
-- Uncomment to test:
-- INSERT INTO lab_test (patient_id, staff_id, test_type, test_date, result_numeric, result_status) 
-- VALUES (@test_patient_id, @test_staff_id, 'Viral Load', CURDATE(), -100, 'Completed');
-- This should SUCCEED
SELECT 'Constraint test: Viral Load result must be >= 0' AS result;

-- Test 3.7: FOREIGN KEY CONSTRAINT - fk_patient_person
SELECT '=== TEST 3.7: FOREIGN KEY CONSTRAINT fk_patient_person ===' AS test_name;
-- This should FAIL (non-existent person_id)
-- Uncomment to test:
-- INSERT INTO patient (person_id, patient_code, enrollment_date) VALUES (999999, 'TEST/001', CURDATE());
-- This should SUCCEED
SELECT 'Constraint test: patient.person_id must reference person.person_id' AS result;

-- Test 3.8: FOREIGN KEY CONSTRAINT - fk_visit_patient
SELECT '=== TEST 3.8: FOREIGN KEY CONSTRAINT fk_visit_patient ===' AS test_name;
-- This should FAIL (non-existent patient_id)
-- Uncomment to test:
-- INSERT INTO visit (patient_id, staff_id, visit_date) VALUES (999999, @test_staff_id, CURDATE());
-- This should SUCCEED
SELECT 'Constraint test: visit.patient_id must reference patient.patient_id' AS result;

-- Test 3.9: UNIQUE CONSTRAINT - uk_nin
SELECT '=== TEST 3.9: UNIQUE CONSTRAINT uk_nin ===' AS test_name;
-- This should FAIL (duplicate NIN)
-- Uncomment to test:
-- INSERT INTO person (nin, first_name, last_name, sex, date_of_birth, district, subcounty) 
-- SELECT nin, 'Duplicate', 'Test', sex, date_of_birth, district, subcounty FROM person LIMIT 1;
-- This should SUCCEED
SELECT 'Constraint test: person.nin must be unique' AS result;

-- Test 3.10: UNIQUE CONSTRAINT - uk_patient_code
SELECT '=== TEST 3.10: UNIQUE CONSTRAINT uk_patient_code ===' AS test_name;
-- This should FAIL (duplicate patient_code)
-- Uncomment to test:
-- INSERT INTO patient (person_id, patient_code, enrollment_date) 
-- SELECT person_id, patient_code, enrollment_date FROM patient LIMIT 1;
-- This should SUCCEED
SELECT 'Constraint test: patient.patient_code must be unique' AS result;

-- ============================================================================
-- TEST SECTION 4: PRIVILEGES AND ROLE-BASED ACCESS TESTING
-- ============================================================================

-- Test 4.1: Verify roles exist
SELECT '=== TEST 4.1: Verify Roles Exist ===' AS test_name;
SELECT role_name FROM mysql.roles_edges 
WHERE FROM_USER IN ('db_admin', 'db_clinician', 'db_lab', 'db_pharmacy', 'db_counselor', 'db_readonly', 'db_patient')
GROUP BY role_name;

-- Test 4.2: Verify user role assignments
SELECT '=== TEST 4.2: Verify User Role Assignments ===' AS test_name;
SELECT 
    FROM_USER AS role_name,
    TO_USER AS username,
    TO_HOST AS host
FROM mysql.role_edges
WHERE FROM_USER IN ('db_admin', 'db_clinician', 'db_lab', 'db_pharmacy', 'db_counselor', 'db_readonly', 'db_patient')
ORDER BY FROM_USER, TO_USER;

-- Test 4.3: Test db_admin privileges (should have ALL)
SELECT '=== TEST 4.3: Test db_admin Privileges ===' AS test_name;
-- Note: Run this while logged in as a user with db_admin role
-- SHOW GRANTS FOR CURRENT_USER();
SELECT 'Run: SHOW GRANTS FOR CURRENT_USER(); while logged in as db_admin user' AS instruction;

-- Test 4.4: Test db_clinician privileges (should have SELECT on all, INSERT/UPDATE on specific tables)
SELECT '=== TEST 4.4: Test db_clinician Privileges ===' AS test_name;
-- Note: Run these while logged in as a user with db_clinician role
-- Should SUCCEED:
-- SELECT * FROM patient LIMIT 1;
-- INSERT INTO visit (patient_id, staff_id, visit_date) VALUES (1, 1, CURDATE());
-- Should FAIL:
-- INSERT INTO dispense (patient_id, staff_id, regimen_id, dispense_date, days_supply, quantity_dispensed, next_refill_date) 
-- VALUES (1, 1, 1, CURDATE(), 30, 90, DATE_ADD(CURDATE(), INTERVAL 30 DAY));
SELECT 'Run privilege tests while logged in as db_clinician user' AS instruction;

-- Test 4.5: Test db_lab privileges (should have SELECT on patient/staff, INSERT/UPDATE on lab_test)
SELECT '=== TEST 4.5: Test db_lab Privileges ===' AS test_name;
-- Note: Run these while logged in as a user with db_lab role
-- Should SUCCEED:
-- SELECT * FROM patient LIMIT 1;
-- INSERT INTO lab_test (patient_id, staff_id, test_type, test_date, result_status) 
-- VALUES (1, 1, 'Viral Load', CURDATE(), 'Completed');
-- Should FAIL:
-- INSERT INTO visit (patient_id, staff_id, visit_date) VALUES (1, 1, CURDATE());
SELECT 'Run privilege tests while logged in as db_lab user' AS instruction;

-- Test 4.6: Test db_pharmacy privileges (should have SELECT on patient/regimen, INSERT/UPDATE on dispense)
SELECT '=== TEST 4.6: Test db_pharmacy Privileges ===' AS test_name;
-- Note: Run these while logged in as a user with db_pharmacy role
-- Should SUCCEED:
-- SELECT * FROM patient LIMIT 1;
-- SELECT * FROM regimen LIMIT 1;
-- Should FAIL:
-- INSERT INTO visit (patient_id, staff_id, visit_date) VALUES (1, 1, CURDATE());
SELECT 'Run privilege tests while logged in as db_pharmacy user' AS instruction;

-- Test 4.7: Test db_readonly privileges (should have SELECT only)
SELECT '=== TEST 4.7: Test db_readonly Privileges ===' AS test_name;
-- Note: Run these while logged in as a user with db_readonly role
-- Should SUCCEED:
-- SELECT * FROM patient LIMIT 1;
-- Should FAIL:
-- INSERT INTO visit (patient_id, staff_id, visit_date) VALUES (1, 1, CURDATE());
-- UPDATE patient SET next_of_kin = 'Test' WHERE patient_id = 1;
SELECT 'Run privilege tests while logged in as db_readonly user' AS instruction;

-- Test 4.8: Test stored procedure execution privileges
SELECT '=== TEST 4.8: Test Stored Procedure Execution Privileges ===' AS test_name;
-- Verify which roles can execute which procedures
SELECT 
    ROUTINE_NAME,
    GRANTEE,
    PRIVILEGE_TYPE
FROM information_schema.ROUTINE_PRIVILEGES
WHERE TABLE_SCHEMA = 'hiv_patient_care'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME, GRANTEE;

-- Test 4.9: Test view access privileges
SELECT '=== TEST 4.9: Test View Access Privileges ===' AS test_name;
-- List all views and their access
SELECT 
    TABLE_NAME AS view_name,
    TABLE_SCHEMA
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'hiv_patient_care'
ORDER BY TABLE_NAME;

-- Test 4.10: Comprehensive privilege summary
SELECT '=== TEST 4.10: Comprehensive Privilege Summary ===' AS test_name;
SELECT 
    GRANTEE,
    TABLE_SCHEMA,
    TABLE_NAME,
    PRIVILEGE_TYPE,
    IS_GRANTABLE
FROM information_schema.TABLE_PRIVILEGES
WHERE TABLE_SCHEMA = 'hiv_patient_care'
  AND GRANTEE LIKE '%db_%'
ORDER BY GRANTEE, TABLE_NAME, PRIVILEGE_TYPE;

-- ============================================================================
-- TEST SECTION 5: INTEGRATION TESTS
-- ============================================================================

-- Test 5.1: End-to-end patient workflow
SELECT '=== TEST 5.1: End-to-End Patient Workflow ===' AS test_name;
-- Create person -> Create patient -> Create visit -> Create lab test -> Create dispense
-- This is a comprehensive test that verifies multiple components work together
SELECT 
    'Workflow Test: Person -> Patient -> Visit -> Lab Test -> Dispense' AS workflow_step,
    COUNT(DISTINCT p.person_id) AS persons,
    COUNT(DISTINCT pt.patient_id) AS patients,
    COUNT(DISTINCT v.visit_id) AS visits,
    COUNT(DISTINCT lt.lab_test_id) AS lab_tests,
    COUNT(DISTINCT d.dispense_id) AS dispenses
FROM person p
LEFT JOIN patient pt ON p.person_id = pt.person_id
LEFT JOIN visit v ON pt.patient_id = v.patient_id
LEFT JOIN lab_test lt ON pt.patient_id = lt.patient_id
LEFT JOIN dispense d ON pt.patient_id = d.patient_id;

-- Test 5.2: Alert generation workflow
SELECT '=== TEST 5.2: Alert Generation Workflow ===' AS test_name;
-- Verify alerts are generated by triggers and procedures
SELECT 
    alert_type,
    alert_level,
    COUNT(*) AS alert_count,
    SUM(CASE WHEN is_resolved = FALSE THEN 1 ELSE 0 END) AS active_alerts,
    SUM(CASE WHEN is_resolved = TRUE THEN 1 ELSE 0 END) AS resolved_alerts
FROM alert
GROUP BY alert_type, alert_level
ORDER BY alert_type, alert_level;

-- Test 5.3: Audit trail completeness
SELECT '=== TEST 5.3: Audit Trail Completeness ===' AS test_name;
-- Verify audit logs are being created
SELECT 
    table_name,
    action,
    COUNT(*) AS action_count,
    MAX(action_time) AS last_action
FROM audit_log
GROUP BY table_name, action
ORDER BY table_name, action;

-- Test 5.4: Data integrity across relationships
SELECT '=== TEST 5.4: Data Integrity Across Relationships ===' AS test_name;
-- Check for orphaned records
SELECT 
    'Orphaned patient records' AS check_type,
    COUNT(*) AS orphaned_count
FROM patient p
LEFT JOIN person per ON p.person_id = per.person_id
WHERE per.person_id IS NULL
UNION ALL
SELECT 
    'Orphaned visit records',
    COUNT(*)
FROM visit v
LEFT JOIN patient p ON v.patient_id = p.patient_id
WHERE p.patient_id IS NULL
UNION ALL
SELECT 
    'Orphaned lab_test records',
    COUNT(*)
FROM lab_test lt
LEFT JOIN patient p ON lt.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- ============================================================================
-- TEST SUMMARY REPORT
-- ============================================================================

SELECT '=== TEST SUMMARY REPORT ===' AS report_section;

-- Summary of stored procedures
SELECT 
    'Stored Procedures' AS component_type,
    COUNT(*) AS total_count,
    COUNT(DISTINCT ROUTINE_NAME) AS unique_procedures
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hiv_patient_care'
  AND ROUTINE_TYPE = 'PROCEDURE';

-- Summary of triggers
SELECT 
    'Triggers' AS component_type,
    COUNT(*) AS total_count,
    COUNT(DISTINCT TRIGGER_NAME) AS unique_triggers
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'hiv_patient_care';

-- Summary of constraints
SELECT 
    'Constraints' AS component_type,
    COUNT(*) AS total_count
FROM (
    SELECT tc.CONSTRAINT_NAME 
    FROM information_schema.TABLE_CONSTRAINTS tc 
    WHERE tc.TABLE_SCHEMA = 'hiv_patient_care'
    UNION ALL
    SELECT cc.CONSTRAINT_NAME 
    FROM information_schema.CHECK_CONSTRAINTS cc
    JOIN information_schema.TABLE_CONSTRAINTS tc
        ON cc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
        AND cc.CONSTRAINT_SCHEMA = tc.TABLE_SCHEMA
    WHERE cc.CONSTRAINT_SCHEMA = 'hiv_patient_care'
) AS all_constraints;

-- Summary of roles
SELECT 
    'Roles' AS component_type,
    COUNT(DISTINCT FROM_USER) AS total_roles,
    COUNT(DISTINCT TO_USER) AS total_users
FROM mysql.role_edges
WHERE FROM_USER LIKE 'db_%';

-- ============================================================================
-- END OF TEST SCRIPTS
-- ============================================================================