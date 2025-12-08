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
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    UPDATE_RULE,
    DELETE_RULE
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
    CONSTRAINT_NAME,
    TABLE_NAME,
    CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'hiv_patient_care'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

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
    NEXT_EXECUTION_TIME
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
-- END OF FILE
-- ============================================================================