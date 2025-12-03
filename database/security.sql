-- ============================================================================
-- SECURITY: ROLES AND PRIVILEGES
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

-- ============================================================================
-- Create Database Roles
-- ============================================================================

-- Drop existing roles
DROP ROLE IF EXISTS 'db_admin';
DROP ROLE IF EXISTS 'db_clinician';
DROP ROLE IF EXISTS 'db_lab';
DROP ROLE IF EXISTS 'db_pharmacy';
DROP ROLE IF EXISTS 'db_counselor';
DROP ROLE IF EXISTS 'db_readonly';
DROP ROLE IF EXISTS 'db_patient';

-- Create roles
CREATE ROLE 'db_admin';
CREATE ROLE 'db_clinician';
CREATE ROLE 'db_lab';
CREATE ROLE 'db_pharmacy';
CREATE ROLE 'db_counselor';
CREATE ROLE 'db_readonly';
CREATE ROLE 'db_patient';

-- ============================================================================
-- GRANT PRIVILEGES: db_admin
-- Full access: all tables, procedures, views, schema changes
-- ============================================================================

GRANT ALL PRIVILEGES ON *.* TO 'db_admin';
GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'db_admin';
GRANT EXECUTE ON PROCEDURE *.* TO 'db_admin';
GRANT CREATE, ALTER, DROP, INDEX, CREATE VIEW, SHOW VIEW ON *.* TO 'db_admin';

-- ============================================================================
-- GRANT PRIVILEGES: db_clinician
-- Clinical staff: read all, write to visit, appointment, patient, lab_test, adherence_log, alert
-- ============================================================================

GRANT SELECT ON *.* TO 'db_clinician';
GRANT INSERT, UPDATE ON `visit` TO 'db_clinician';
GRANT INSERT, UPDATE ON `appointment` TO 'db_clinician';
GRANT INSERT, UPDATE ON `patient` TO 'db_clinician';
GRANT INSERT, UPDATE ON `lab_test` TO 'db_clinician';
GRANT INSERT, UPDATE ON `adherence_log` TO 'db_clinician';
GRANT INSERT, UPDATE ON `alert` TO 'db_clinician';
GRANT SELECT ON `audit_log` TO 'db_clinician';

-- Execute procedures
GRANT EXECUTE ON PROCEDURE `sp_compute_adherence` TO 'db_clinician';
GRANT EXECUTE ON PROCEDURE `sp_check_overdue_vl` TO 'db_clinician';
GRANT EXECUTE ON PROCEDURE `sp_mark_missed_appointments` TO 'db_clinician';
GRANT EXECUTE ON PROCEDURE `sp_update_patient_status_ltfu` TO 'db_clinician';
GRANT EXECUTE ON PROCEDURE `sp_check_missed_refills` TO 'db_clinician';

-- ============================================================================
-- GRANT PRIVILEGES: db_lab
-- Lab technicians: read patient/staff data, write lab test results
-- ============================================================================

GRANT SELECT ON `patient` TO 'db_lab';
GRANT SELECT ON `person` TO 'db_lab';
GRANT SELECT ON `staff` TO 'db_lab';
GRANT SELECT ON `lab_test` TO 'db_lab';
GRANT INSERT, UPDATE ON `lab_test` TO 'db_lab';
GRANT SELECT ON `visit` TO 'db_lab';
GRANT SELECT ON `regimen` TO 'db_lab';
GRANT SELECT ON `dispense` TO 'db_lab';

-- ============================================================================
-- GRANT PRIVILEGES: db_pharmacy
-- Pharmacists: read patient/regimen data, write dispense records
-- ============================================================================

GRANT SELECT ON `patient` TO 'db_pharmacy';
GRANT SELECT ON `person` TO 'db_pharmacy';
GRANT SELECT ON `regimen` TO 'db_pharmacy';
GRANT SELECT ON `dispense` TO 'db_pharmacy';
GRANT SELECT ON `visit` TO 'db_pharmacy';
GRANT INSERT, UPDATE ON `dispense` TO 'db_pharmacy';
GRANT SELECT ON `lab_test` TO 'db_pharmacy';
GRANT SELECT ON `appointment` TO 'db_pharmacy';
GRANT SELECT ON `alert` TO 'db_pharmacy';

-- ============================================================================
-- GRANT PRIVILEGES: db_counselor
-- Counselors: read patient data, write counseling_session, adherence_log, appointment
-- ============================================================================

GRANT SELECT ON `patient` TO 'db_counselor';
GRANT SELECT ON `person` TO 'db_counselor';
GRANT SELECT ON `adherence_log` TO 'db_counselor';
GRANT SELECT ON `visit` TO 'db_counselor';
GRANT INSERT, UPDATE ON `counseling_session` TO 'db_counselor';
GRANT INSERT, UPDATE ON `adherence_log` TO 'db_counselor';
GRANT INSERT, UPDATE ON `appointment` TO 'db_counselor';
GRANT SELECT ON `lab_test` TO 'db_counselor';
GRANT SELECT ON `dispense` TO 'db_counselor';
GRANT SELECT ON `alert` TO 'db_counselor';

-- ============================================================================
-- GRANT PRIVILEGES: db_readonly
-- Records officers: read-only access to all tables and views
-- ============================================================================

GRANT SELECT ON *.* TO 'db_readonly';

-- Read-only access to views
GRANT SELECT ON `v_active_patients_summary` TO 'db_readonly';
GRANT SELECT ON `v_patient_care_timeline` TO 'db_readonly';
GRANT SELECT ON `v_active_alerts_summary` TO 'db_readonly';
GRANT SELECT ON `v_viral_load_monitoring` TO 'db_readonly';
GRANT SELECT ON `v_adherence_summary` TO 'db_readonly';
GRANT SELECT ON `v_staff_with_roles` TO 'db_readonly';

-- ============================================================================
-- Example: Create Users and Assign Roles
-- ============================================================================

-- Note: In production, create actual users and assign roles like this:
-- CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_admin' TO 'admin_user'@'localhost';
-- SET DEFAULT ROLE 'db_admin' FOR 'admin_user'@'localhost';

-- CREATE USER 'doctor1'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_clinician' TO 'doctor1'@'localhost';
-- SET DEFAULT ROLE 'db_clinician' FOR 'doctor1'@'localhost';

-- CREATE USER 'lab_tech1'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_lab' TO 'lab_tech1'@'localhost';
-- SET DEFAULT ROLE 'db_lab' FOR 'lab_tech1'@'localhost';

-- CREATE USER 'pharmacist1'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_pharmacy' TO 'pharmacist1'@'localhost';
-- SET DEFAULT ROLE 'db_pharmacy' FOR 'pharmacist1'@'localhost';

-- CREATE USER 'counselor1'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_counselor' TO 'counselor1'@'localhost';
-- SET DEFAULT ROLE 'db_counselor' FOR 'counselor1'@'localhost';

-- CREATE USER 'records_officer1'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT 'db_readonly' TO 'records_officer1'@'localhost';
-- SET DEFAULT ROLE 'db_readonly' FOR 'records_officer1'@'localhost';

-- ============================================================================
-- GRANT PRIVILEGES: db_patient
-- Patients: read-only access to own data via patient views and procedures
-- Can read own patient and person records for verification
-- ============================================================================
GRANT SELECT ON `v_patient_dashboard` TO 'db_patient';
GRANT SELECT ON `v_patient_visit_history` TO 'db_patient';
GRANT SELECT ON `v_patient_lab_history` TO 'db_patient';
GRANT SELECT ON `v_patient_medication_history` TO 'db_patient';
GRANT SELECT ON `v_patient_appointments` TO 'db_patient';
GRANT SELECT ON `v_patient_adherence_history` TO 'db_patient';
GRANT SELECT ON `v_patient_alerts` TO 'db_patient';
GRANT SELECT ON `v_patient_progress_timeline` TO 'db_patient';

-- Execute patient self-service procedures
GRANT EXECUTE ON PROCEDURE `sp_patient_dashboard` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_visits` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_lab_tests` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_medications` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_appointments` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_adherence` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_alerts` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_progress_timeline` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_next_appointment` TO 'db_patient';
GRANT EXECUTE ON PROCEDURE `sp_patient_summary_stats` TO 'db_patient';

-- Patients can read own patient record for verification
GRANT SELECT ON `patient` TO 'db_patient';
GRANT SELECT ON `person` TO 'db_patient';

-- ============================================================================
-- FLUSH PRIVILEGES
-- ============================================================================

FLUSH PRIVILEGES;

