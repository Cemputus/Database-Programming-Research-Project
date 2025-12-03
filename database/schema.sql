-- ============================================================================
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- Database Schema (MySQL 8.0+)
-- ============================================================================

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS `hiv_patient_care` 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- Use the database
USE `hiv_patient_care`;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================================
-- SUPER TYPE: person (Generalization)
-- Stores basic information for all people in the system
-- Patients and staff inherit from this table to avoid data duplication
-- ============================================================================

CREATE TABLE IF NOT EXISTS `person` (
  `person_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nin` VARCHAR(20) NOT NULL UNIQUE COMMENT 'National ID from Uganda NIRA (CF for female, CM for male, e.g., CF12345-67890-1 or CM12345-67890-1)',
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `other_name` VARCHAR(100) DEFAULT NULL COMMENT 'Optional third name (local/tribal)',
  `sex` ENUM('M', 'F') NOT NULL COMMENT 'Gender - Male or Female only',
  `date_of_birth` DATE NOT NULL,
  `phone_contact` VARCHAR(20) DEFAULT NULL COMMENT 'Phone number (Uganda format: +256...)',
  `district` VARCHAR(100) NOT NULL COMMENT 'District (e.g., Mukono, Kampala)',
  `subcounty` VARCHAR(100) NOT NULL COMMENT 'Subcounty - required for HMIS reporting',
  `parish` VARCHAR(100) DEFAULT NULL COMMENT 'Parish - used for community tracing',
  `village` VARCHAR(100) DEFAULT NULL COMMENT 'Village/zone (e.g., Kigombya)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`person_id`),
  UNIQUE KEY `uk_nin` (`nin`),
  KEY `idx_district` (`district`),
  KEY `idx_name` (`first_name`, `last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: patient (Specialization from person)
-- Stores HIV patient-specific information
-- Links to person table for basic demographics
-- ============================================================================

CREATE TABLE IF NOT EXISTS `patient` (
  `patient_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `person_id` INT UNSIGNED NOT NULL,
  `patient_code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Hospital-specific ART ID (e.g., MGH/ART/0001)',
  `enrollment_date` DATE NOT NULL COMMENT 'First registration at HIV clinic',
  `art_start_date` DATE DEFAULT NULL COMMENT 'When ART started',
  `current_status` ENUM('Active', 'Transferred-Out', 'LTFU', 'Dead') NOT NULL DEFAULT 'Active' COMMENT 'Patient status - one value only (disjoint)',
  `next_of_kin` VARCHAR(150) DEFAULT NULL COMMENT 'NOK name',
  `nok_phone` VARCHAR(20) DEFAULT NULL COMMENT 'NOK phone',
  `support_group` VARCHAR(150) DEFAULT NULL COMMENT 'Legacy field - use patient_cag table for CAG membership',
  `treatment_partner` VARCHAR(150) DEFAULT NULL COMMENT 'Person helping with adherence',
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `uk_patient_code` (`patient_code`),
  UNIQUE KEY `uk_person_patient` (`person_id`),
  KEY `idx_status` (`current_status`),
  KEY `idx_enrollment` (`enrollment_date`),
  CONSTRAINT `fk_patient_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_art_after_enrollment` CHECK (`art_start_date` IS NULL OR `art_start_date` >= `enrollment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: staff (Specialization from person)
-- Stores staff-specific information
-- Links to person table for basic demographics
-- ============================================================================

CREATE TABLE IF NOT EXISTS `staff` (
  `staff_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `person_id` INT UNSIGNED NOT NULL,
  `staff_code` VARCHAR(30) NOT NULL UNIQUE COMMENT 'Hospital staff ID',
  `cadre` ENUM('Doctor', 'Clinical Officer', 'Nurse', 'Midwife', 'Lab Technician', 'Pharmacist', 'Counselor', 'Records Officer') NOT NULL COMMENT 'Uganda MOH cadres',
  `moH_registration_no` VARCHAR(50) DEFAULT NULL COMMENT 'Professional registration number',
  `hire_date` DATE NOT NULL COMMENT 'When staff joined hospital',
  `active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Whether active',
  PRIMARY KEY (`staff_id`),
  UNIQUE KEY `uk_staff_code` (`staff_code`),
  UNIQUE KEY `uk_person_staff` (`person_id`),
  CONSTRAINT `fk_staff_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ROLE TABLE
-- Defines system access roles (not job cadres)
-- Staff can have multiple roles via staff_role table
-- ============================================================================

CREATE TABLE IF NOT EXISTS `role` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'System privilege role',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_role_name` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- STAFF_ROLE
-- Maps staff to system roles (overlapping specialization)
-- One staff member can have multiple roles simultaneously
-- ============================================================================

CREATE TABLE IF NOT EXISTS `staff_role` (
  `staff_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`staff_id`, `role_id`),
  CONSTRAINT `fk_staff_role_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_staff_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VISIT TABLE
-- Records clinical visits - compliant with HMIS 031 form
-- Tracks vital signs, symptoms, and diagnoses
-- ============================================================================

CREATE TABLE IF NOT EXISTS `visit` (
  `visit_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Clinician',
  `visit_date` DATE NOT NULL,
  `who_stage` TINYINT UNSIGNED DEFAULT NULL COMMENT 'WHO clinical staging (1-4)',
  `weight_kg` DECIMAL(5,2) DEFAULT NULL COMMENT 'Weight in kg',
  `bp` VARCHAR(20) DEFAULT NULL COMMENT 'Blood pressure (e.g., "120/80")',
  `tb_screening` ENUM('Negative', 'Presumptive', 'Positive') DEFAULT NULL,
  `symptoms` TEXT DEFAULT NULL,
  `oi_diagnosis` TEXT DEFAULT NULL COMMENT 'Opportunistic infection diagnosis',
  `next_appointment_date` DATE DEFAULT NULL,
  PRIMARY KEY (`visit_id`),
  KEY `idx_visit_date` (`visit_date`),
  KEY `idx_patient_visit` (`patient_id`, `visit_date`),
  KEY `idx_staff_visit` (`staff_id`),
  CONSTRAINT `fk_visit_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_visit_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_visit_date_not_future` CHECK (`visit_date` <= CURDATE()),
  CONSTRAINT `chk_who_stage_range` CHECK (`who_stage` IS NULL OR (`who_stage` >= 1 AND `who_stage` <= 4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LAB_TEST TABLE
-- Stores laboratory test results
-- Supports CPHL viral load program with sample IDs
-- Test types: Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis
-- ============================================================================

CREATE TABLE IF NOT EXISTS `lab_test` (
  `lab_test_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `visit_id` BIGINT UNSIGNED DEFAULT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Staff who ordered/performed test',
  `test_type` ENUM('Viral Load', 'CD4', 'HB', 'Creatinine', 'Malaria RDT', 'TB-LAM', 'Urinalysis') NOT NULL COMMENT 'Type of lab test (categorization)',
  `result_numeric` DECIMAL(18,4) DEFAULT NULL COMMENT 'For numeric results (VL, CD4, etc.)',
  `result_text` VARCHAR(150) DEFAULT NULL COMMENT 'For text results',
  `test_date` DATE NOT NULL,
  `units` VARCHAR(50) DEFAULT NULL COMMENT 'Unit of measurement',
  `cphl_sample_id` VARCHAR(50) DEFAULT NULL COMMENT 'CPHL Sample ID for VL',
  `result_status` ENUM('Pending', 'Completed', 'Rejected') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`lab_test_id`),
  KEY `idx_test_date` (`test_date`),
  KEY `idx_patient_test` (`patient_id`, `test_type`, `test_date`),
  KEY `idx_test_type` (`test_type`),
  KEY `idx_cphl_sample_id` (`cphl_sample_id`),
  KEY `idx_visit_test` (`visit_id`),
  CONSTRAINT `fk_lab_test_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_test_visit` FOREIGN KEY (`visit_id`) REFERENCES `visit` (`visit_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_test_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_test_date_not_future` CHECK (`test_date` <= CURDATE()),
  CONSTRAINT `chk_vl_result_non_negative` CHECK (`test_type` != 'Viral Load' OR `result_numeric` IS NULL OR `result_numeric` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- REGIMEN TABLE
-- Catalog of ART regimens following Uganda MOH standards
-- Examples: TDF/3TC/DTG (First Line), TDF/3TC/LPV/r (Second Line)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `regimen` (
  `regimen_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `regimen_code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'MOH Regimen Code',
  `regimen_name` VARCHAR(150) NOT NULL COMMENT 'e.g., TDF/3TC/DTG',
  `line` ENUM('First Line', 'Second Line', 'Third Line') NOT NULL,
  PRIMARY KEY (`regimen_id`),
  UNIQUE KEY `uk_regimen_code` (`regimen_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DISPENSE TABLE
-- Records medication dispensing - compliant with MOH pharmacy log
-- Tracks days supply, quantity, and calculates next refill date
-- ============================================================================

CREATE TABLE IF NOT EXISTS `dispense` (
  `dispense_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Pharmacist',
  `regimen_id` INT UNSIGNED NOT NULL,
  `dispense_date` DATE NOT NULL,
  `days_supply` INT UNSIGNED NOT NULL COMMENT 'Days of medication supplied (1-365)',
  `quantity_dispensed` INT UNSIGNED NOT NULL,
  `next_refill_date` DATE NOT NULL COMMENT 'Calculated: dispense_date + days_supply',
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`dispense_id`),
  KEY `idx_dispense_date` (`dispense_date`),
  KEY `idx_patient_dispense` (`patient_id`, `dispense_date`),
  KEY `idx_next_refill` (`next_refill_date`),
  CONSTRAINT `fk_dispense_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_dispense_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_dispense_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_dispense_date_not_future` CHECK (`dispense_date` <= CURDATE()),
  CONSTRAINT `chk_days_supply_range` CHECK (`days_supply` > 0 AND `days_supply` <= 365),
  CONSTRAINT `chk_next_refill_calc` CHECK (`next_refill_date` = DATE_ADD(`dispense_date`, INTERVAL `days_supply` DAY))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- APPOINTMENT TABLE
-- Manages patient appointment scheduling and tracking
-- Tracks status: Scheduled, Attended, Missed, Rescheduled, Cancelled
-- ============================================================================

CREATE TABLE IF NOT EXISTS `appointment` (
  `appointment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL,
  `scheduled_date` DATE NOT NULL,
  `status` ENUM('Scheduled', 'Attended', 'Missed', 'Rescheduled', 'Cancelled') NOT NULL DEFAULT 'Scheduled',
  `reason` VARCHAR(150) DEFAULT NULL,
  PRIMARY KEY (`appointment_id`),
  KEY `idx_appointment_date` (`scheduled_date`, `status`),
  KEY `idx_patient_appointment` (`patient_id`, `scheduled_date`),
  CONSTRAINT `fk_appointment_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_appointment_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COUNSELING_SESSION TABLE
-- Records counseling sessions for adherence support
-- Tracks topics discussed and adherence barriers identified
-- ============================================================================

CREATE TABLE IF NOT EXISTS `counseling_session` (
  `counseling_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `counselor_id` INT UNSIGNED NOT NULL,
  `session_date` DATE NOT NULL,
  `topic` VARCHAR(150) NOT NULL COMMENT 'e.g., Adherence Support, Psychosocial, Disclosure',
  `adherence_barriers` TEXT DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`counseling_id`),
  KEY `idx_session_date` (`session_date`),
  KEY `idx_patient_counseling` (`patient_id`, `session_date`),
  CONSTRAINT `fk_counseling_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_counseling_counselor` FOREIGN KEY (`counselor_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CAG (COMMUNITY ART GROUP) TABLE
-- Ugandan MOH-approved community-based ART delivery model
-- Stable HIV patients form small groups in villages/parishes
-- Members rotate to pick up ART refills and distribute to others
-- ============================================================================

CREATE TABLE IF NOT EXISTS `cag` (
  `cag_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cag_name` VARCHAR(150) NOT NULL UNIQUE COMMENT 'CAG name (e.g., Kigombya CAG)',
  `district` VARCHAR(100) NOT NULL COMMENT 'District where CAG is located',
  `subcounty` VARCHAR(100) NOT NULL COMMENT 'Subcounty',
  `parish` VARCHAR(100) NOT NULL COMMENT 'Parish',
  `village` VARCHAR(100) NOT NULL COMMENT 'Village where CAG operates',
  `formation_date` DATE NOT NULL COMMENT 'When CAG was formed',
  `coordinator_patient_id` INT UNSIGNED DEFAULT NULL COMMENT 'Patient who coordinates the CAG',
  `facility_staff_id` INT UNSIGNED DEFAULT NULL COMMENT 'Staff member who supervises CAG',
  `status` ENUM('Active', 'Inactive', 'Dissolved') NOT NULL DEFAULT 'Active' COMMENT 'CAG status',
  `max_members` TINYINT UNSIGNED DEFAULT 6 COMMENT 'Maximum members (typically 4-6)',
  `notes` TEXT DEFAULT NULL COMMENT 'Additional notes about the CAG',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cag_id`),
  UNIQUE KEY `uk_cag_name` (`cag_name`),
  KEY `idx_cag_location` (`district`, `subcounty`, `parish`, `village`),
  KEY `idx_cag_status` (`status`),
  CONSTRAINT `fk_cag_coordinator` FOREIGN KEY (`coordinator_patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_cag_staff` FOREIGN KEY (`facility_staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PATIENT_CAG TABLE
-- Junction table linking patients to CAGs (many-to-many)
-- Tracks patient membership in Community ART Groups
-- ============================================================================

CREATE TABLE IF NOT EXISTS `patient_cag` (
  `patient_cag_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `cag_id` INT UNSIGNED NOT NULL,
  `join_date` DATE NOT NULL COMMENT 'When patient joined the CAG',
  `role_in_cag` ENUM('Member', 'Coordinator', 'Deputy Coordinator') NOT NULL DEFAULT 'Member' COMMENT 'Patient role in CAG',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Whether patient is currently active in CAG',
  `exit_date` DATE DEFAULT NULL COMMENT 'When patient left the CAG',
  `exit_reason` VARCHAR(200) DEFAULT NULL COMMENT 'Reason for leaving (e.g., Transferred, LTFU, Death)',
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`patient_cag_id`),
  UNIQUE KEY `uk_patient_cag_active` (`patient_id`, `cag_id`, `is_active`),
  KEY `idx_cag_patients` (`cag_id`, `is_active`),
  KEY `idx_patient_cags` (`patient_id`, `is_active`),
  CONSTRAINT `fk_patient_cag_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_patient_cag_cag` FOREIGN KEY (`cag_id`) REFERENCES `cag` (`cag_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_exit_date_after_join` CHECK (`exit_date` IS NULL OR `exit_date` >= `join_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CAG_ROTATION TABLE
-- Tracks rotation of CAG members picking up refills for the group
-- Records who picked up medications for which patients in the CAG
-- ============================================================================

CREATE TABLE IF NOT EXISTS `cag_rotation` (
  `rotation_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cag_id` INT UNSIGNED NOT NULL,
  `pickup_patient_id` INT UNSIGNED NOT NULL COMMENT 'Patient who picked up medications',
  `rotation_date` DATE NOT NULL COMMENT 'Date of pickup',
  `dispense_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Reference to dispense record',
  `patients_served` TINYINT UNSIGNED NOT NULL COMMENT 'Number of patients served in this rotation',
  `notes` TEXT DEFAULT NULL COMMENT 'Notes about the rotation',
  PRIMARY KEY (`rotation_id`),
  KEY `idx_rotation_date` (`rotation_date`),
  KEY `idx_cag_rotation` (`cag_id`, `rotation_date`),
  KEY `idx_pickup_patient` (`pickup_patient_id`),
  CONSTRAINT `fk_rotation_cag` FOREIGN KEY (`cag_id`) REFERENCES `cag` (`cag_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rotation_patient` FOREIGN KEY (`pickup_patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rotation_dispense` FOREIGN KEY (`dispense_id`) REFERENCES `dispense` (`dispense_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_rotation_date_not_future` CHECK (`rotation_date` <= CURDATE())
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADHERENCE_LOG TABLE
-- Tracks medication adherence assessments
-- Methods: Pill Count, Pharmacy Refill, Self Report, CAG Report, Computed
-- Adherence percentage: 0-100%
-- ============================================================================

CREATE TABLE IF NOT EXISTS `adherence_log` (
  `adherence_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `log_date` DATE NOT NULL,
  `adherence_percent` DECIMAL(5,2) NOT NULL COMMENT 'Adherence percentage (0-100%)',
  `method_used` ENUM('Pill Count', 'Pharmacy Refill', 'Self Report', 'CAG Report', 'Computed') NOT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`adherence_id`),
  KEY `idx_log_date` (`log_date`),
  KEY `idx_patient_adherence` (`patient_id`, `log_date`),
  CONSTRAINT `fk_adherence_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_adherence_range` CHECK (`adherence_percent` >= 0 AND `adherence_percent` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ALERT TABLE
-- Automated alerts for critical patient care events
-- Types: High Viral Load, Overdue VL, Missed Appointment, Missed Refill, Low Adherence, Severe OI
-- Levels: Info, Warning, Critical
-- ============================================================================

CREATE TABLE IF NOT EXISTS `alert` (
  `alert_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `alert_type` ENUM('High Viral Load', 'Overdue VL', 'Missed Appointment', 'Missed Refill', 'Low Adherence', 'Severe OI') NOT NULL,
  `alert_level` ENUM('Info', 'Warning', 'Critical') NOT NULL DEFAULT 'Warning',
  `alert_msg` TEXT NOT NULL,
  `triggered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_resolved` BOOLEAN NOT NULL DEFAULT FALSE,
  `resolved_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`alert_id`),
  KEY `idx_alert_status` (`is_resolved`, `alert_level`),
  KEY `idx_patient_alert` (`patient_id`, `is_resolved`),
  KEY `idx_alert_type` (`alert_type`),
  KEY `idx_triggered_at` (`triggered_at`),
  CONSTRAINT `fk_alert_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT_LOG TABLE
-- Tracks all data changes for security and compliance
-- Records who changed what, when, and what changed
-- ============================================================================

CREATE TABLE IF NOT EXISTS `audit_log` (
  `audit_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` INT UNSIGNED DEFAULT NULL,
  `action` VARCHAR(100) NOT NULL COMMENT 'e.g., INSERT, UPDATE, DELETE',
  `table_name` VARCHAR(100) NOT NULL,
  `record_id` VARCHAR(100) NOT NULL,
  `details` TEXT DEFAULT NULL,
  `action_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  KEY `idx_table_record` (`table_name`, `record_id`),
  KEY `idx_action_time` (`action_time`),
  KEY `idx_action` (`action`),
  CONSTRAINT `fk_audit_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADDITIONAL INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX `idx_patient_status_enrollment` ON `patient` (`current_status`, `enrollment_date`);
CREATE INDEX `idx_visit_patient_date` ON `visit` (`patient_id`, `visit_date` DESC);
CREATE INDEX `idx_lab_test_patient_type_date` ON `lab_test` (`patient_id`, `test_type`, `test_date` DESC);
CREATE INDEX `idx_dispense_patient_date` ON `dispense` (`patient_id`, `dispense_date` DESC);
CREATE INDEX `idx_appointment_patient_status` ON `appointment` (`patient_id`, `status`, `scheduled_date`);
CREATE INDEX `idx_cag_formation_date` ON `cag` (`formation_date`);
CREATE INDEX `idx_patient_cag_join_date` ON `patient_cag` (`join_date`, `is_active`);
CREATE INDEX `idx_rotation_cag_date` ON `cag_rotation` (`cag_id`, `rotation_date` DESC);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
