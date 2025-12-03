-- ============================================================================
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- Database Schema (MySQL 8.0+) 
-- ============================================================================
--
-- This file creates all the database tables for the HIV care system.
-- Think of it as building the foundation - we're setting up where all the
-- patient and staff information will be stored.
--
-- Before we start creating tables, we need to do some housekeeping:
-- Turn off foreign key checks temporarily (so we can create tables in any order)
-- Set up the database to work properly with our data
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;  -- Let's create tables without worrying about relationships first
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";  -- Allow zero values in auto-increment columns
SET AUTOCOMMIT = 0;  -- We'll commit everything at the end
START TRANSACTION;  -- Start a transaction so we can rollback if something goes wrong
SET time_zone = "+00:00";  -- Use UTC timezone for consistency

-- ============================================================================
-- SUPER TYPE: person (Generalization)
-- ============================================================================
--
-- This is the "parent" table that holds basic information about ANY person
-- in our system - whether they're a patient or staff member.
-- 
-- Why do we do this? Well, both patients and staff have names, dates of birth,
-- phone numbers, and addresses. Instead of duplicating this information in
-- two separate tables, we store it once here and both patients and staff
-- "inherit" from this table. This is called "generalization" in database design.
--
-- Think of it like a family tree - person is the grandparent, and patient
-- and staff are the children who inherit common traits.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `person` (
  -- Every person gets a unique ID number that the system generates automatically
  `person_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  
  -- National ID from Uganda's NIRA system. Format: CF12345-67890-1
  -- This MUST be unique - no two people can have the same NIN
  `nin` VARCHAR(20) NOT NULL UNIQUE COMMENT 'National Identification Number (NIRA-issued: CFxxxxx-xxxxx...)',
  
  -- Basic name information - first and last name are required
  `first_name` VARCHAR(100) NOT NULL,  -- Person's first/given name
  `last_name` VARCHAR(100) NOT NULL,   -- Person's surname/family name
  
  -- Many Ugandans have a third name (local or tribal name) - this is optional
  `other_name` VARCHAR(100) DEFAULT NULL COMMENT 'Optional local/tribal name',
  
  -- Gender/sex - we use M, F, or Other to match Uganda's HMIS reporting standards
  `sex` ENUM('M', 'F', 'Other') NOT NULL COMMENT 'Gender - matches HMIS classification',
  
  -- Date of birth - needed to calculate age and for reporting
  `date_of_birth` DATE NOT NULL,
  
  -- Contact information - phone number in Uganda format (+256...)
  `phone_contact` VARCHAR(20) DEFAULT NULL COMMENT 'MTN/Airtel phone - Uganda phone formats',
  
  -- Location information - Uganda uses a hierarchy: District → Subcounty → Parish → Village
  -- This helps with community tracing and HMIS reporting
  `district` VARCHAR(100) NOT NULL COMMENT 'District of residence (e.g., Mukono, Kampala)',
  `subcounty` VARCHAR(100) NOT NULL COMMENT 'Used in HMIS reporting',
  `parish` VARCHAR(100) DEFAULT NULL COMMENT 'Required for community tracing - helps find patients',
  `village` VARCHAR(100) DEFAULT NULL COMMENT 'Village/zone (e.g., Kigombya)',
  
  -- When was this person record created? System tracks this automatically
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Primary key: This is the main way we identify each person
  PRIMARY KEY (`person_id`),
  
  -- Indexes help the database find records faster
  -- We'll search by NIN a lot, so make it unique and indexed
  UNIQUE KEY `uk_nin` (`nin`),
  KEY `idx_district` (`district`),  -- Quick lookups by district
  KEY `idx_name` (`first_name`, `last_name`)  -- Quick lookups by name
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: patient (Specialization from person)
-- ============================================================================
--
-- This table stores information specific to patients (people receiving HIV care).
-- Remember, patients "inherit" from the person table - so they have all the
-- basic info (name, DOB, address) from there, PLUS the patient-specific
-- information stored here.
--
-- This is called "specialization" - we're taking the general "person" concept
-- and making it more specific for patients.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `patient` (
  -- Each patient gets their own unique ID
  `patient_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  
  -- This links back to the person table - every patient IS a person first
  -- This is the "inheritance" connection we talked about
  `person_id` INT UNSIGNED NOT NULL,
  
  -- The hospital's unique code for this patient (like MGH/ART/0001)
  -- Patients use this code to access their own data
  `patient_code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Hospital-specific ART ID (e.g., MGH/ART/0001)',
  
  -- When did this patient first register at the HIV clinic?
  `enrollment_date` DATE NOT NULL COMMENT 'First registration at HIV clinic',
  
  -- When did they actually start taking ART medication?
  -- This might be different from enrollment (sometimes patients enroll but don't start immediately)
  `art_start_date` DATE DEFAULT NULL COMMENT 'When ART started',
  
  -- Current status of the patient - this is "disjoint categorization" meaning
  -- a patient can only be ONE of these at a time (not multiple)
  -- Active = currently receiving care
  -- Transferred-Out = moved to another facility
  -- LTFU = Lost to Follow-Up (haven't been seen in 90+ days)
  -- Dead = patient has passed away
  `current_status` ENUM('Active', 'Transferred-Out', 'LTFU', 'Dead') NOT NULL DEFAULT 'Active' COMMENT 'Ugandan HMIS standard statuses - Disjoint Categorization',
  
  -- Emergency contact information - who should we call if needed?
  `next_of_kin` VARCHAR(150) DEFAULT NULL COMMENT 'NOK name',
  `nok_phone` VARCHAR(20) DEFAULT NULL COMMENT 'NOK phone',
  
  -- Support systems - many patients are part of Community ART Groups (CAGs)
  -- where they help each other with adherence
  `support_group` VARCHAR(150) DEFAULT NULL COMMENT 'e.g., Community ART group (CAG)',
  
  -- Treatment partner - someone who helps the patient remember to take medication
  `treatment_partner` VARCHAR(150) DEFAULT NULL COMMENT 'Person helping with adherence',
  
  -- Primary key and indexes for fast lookups
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `uk_patient_code` (`patient_code`),  -- Patient codes must be unique
  UNIQUE KEY `uk_person_patient` (`person_id`),  -- One person = one patient record
  KEY `idx_status` (`current_status`),  -- Quick lookups by status (find all Active patients)
  KEY `idx_enrollment` (`enrollment_date`),  -- Quick lookups by enrollment date
  
  -- Foreign key constraint: This patient MUST have a corresponding person record
  -- We use RESTRICT on delete - can't delete a person if they're a patient
  -- CASCADE on update - if person_id changes, update this automatically
  CONSTRAINT `fk_patient_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  
  -- Business rule: ART start date can't be before enrollment date
  -- (You can't start treatment before you enroll!)
  CONSTRAINT `chk_art_after_enrollment` CHECK (`art_start_date` IS NULL OR `art_start_date` >= `enrollment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: staff (Specialization from person)
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
-- ROLE TABLE (for system access - not job cadres)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `role` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'System privilege role',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_role_name` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- STAFF_ROLE (Overlapping Specialization Mapping)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `staff_role` (
  `staff_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`staff_id`, `role_id`),
  CONSTRAINT `fk_staff_role_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_staff_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VISIT TABLE (HMIS 031 compliant)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `visit` (
  `visit_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Clinician',
  `visit_date` DATE NOT NULL,
  `who_stage` TINYINT UNSIGNED DEFAULT NULL COMMENT 'WHO Stage 1-4',
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
-- LAB_TEST TABLE (Aligned with CPHL Uganda viral load program)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `lab_test` (
  `lab_test_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `visit_id` BIGINT UNSIGNED DEFAULT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Staff who ordered/performed test',
  `test_type` ENUM('Viral Load', 'CD4', 'HB', 'Creatinine', 'Malaria RDT', 'TB-LAM', 'Urinalysis') NOT NULL COMMENT 'Categorization',
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
-- REGIMEN TABLE (Uganda ART regimen catalog)
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
-- DISPENSE TABLE (MOH Pharmacy Dispensing Log compliant)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `dispense` (
  `dispense_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Pharmacist',
  `regimen_id` INT UNSIGNED NOT NULL,
  `dispense_date` DATE NOT NULL,
  `days_supply` INT UNSIGNED NOT NULL COMMENT 'Days of medication supplied',
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
-- COUNSELING_SESSION TABLE (Uganda adherence counseling context)
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
-- ADHERENCE_LOG TABLE (CAG & refill-based adherence tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `adherence_log` (
  `adherence_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `log_date` DATE NOT NULL,
  `adherence_percent` DECIMAL(5,2) NOT NULL COMMENT '0-100%',
  `method_used` ENUM('Pill Count', 'Pharmacy Refill', 'Self Report', 'CAG Report', 'Computed') NOT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`adherence_id`),
  KEY `idx_log_date` (`log_date`),
  KEY `idx_patient_adherence` (`patient_id`, `log_date`),
  CONSTRAINT `fk_adherence_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_adherence_range` CHECK (`adherence_percent` >= 0 AND `adherence_percent` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ALERT TABLE (Ugandan ART program indicators)
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

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
