-- ============================================================================
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- Database Schema (MySQL 8.0+)
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================================
-- SUPER TYPE: person (Generalization)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `person` (
  `person_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nin` VARCHAR(14) NOT NULL UNIQUE COMMENT 'National Identification Number',
  `first_name` VARCHAR(100) NOT NULL,
  `middle_name` VARCHAR(100) DEFAULT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `date_of_birth` DATE NOT NULL,
  `gender` ENUM('Male', 'Female', 'Other') NOT NULL,
  `phone_number` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `district` VARCHAR(100) NOT NULL COMMENT 'Uganda District',
  `subcounty` VARCHAR(100) NOT NULL,
  `parish` VARCHAR(100) DEFAULT NULL,
  `village` VARCHAR(100) DEFAULT NULL,
  `address_line` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`person_id`),
  UNIQUE KEY `uk_nin` (`nin`),
  KEY `idx_district` (`district`),
  KEY `idx_name` (`first_name`, `last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: patient (Specialization from person)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `patient` (
  `patient_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `person_id` INT UNSIGNED NOT NULL,
  `patient_number` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Hospital Patient Number',
  `enrollment_date` DATE NOT NULL,
  `art_start_date` DATE DEFAULT NULL COMMENT 'ART initiation date',
  `current_status` ENUM('Active', 'Transferred-Out', 'LTFU', 'Dead') NOT NULL DEFAULT 'Active' COMMENT 'Disjoint Categorization',
  `baseline_cd4` INT UNSIGNED DEFAULT NULL,
  `baseline_vl` DECIMAL(10,2) DEFAULT NULL COMMENT 'Baseline Viral Load',
  `who_stage` ENUM('Stage 1', 'Stage 2', 'Stage 3', 'Stage 4') DEFAULT NULL,
  `tb_status` ENUM('No TB', 'TB Suspected', 'TB Confirmed', 'On TB Treatment', 'TB Completed') DEFAULT 'No TB',
  `pregnancy_status` ENUM('Not Pregnant', 'Pregnant', 'Breastfeeding', 'Not Applicable') DEFAULT 'Not Applicable',
  `next_of_kin_name` VARCHAR(255) DEFAULT NULL,
  `next_of_kin_phone` VARCHAR(20) DEFAULT NULL,
  `next_of_kin_relationship` VARCHAR(50) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `uk_patient_number` (`patient_number`),
  UNIQUE KEY `uk_person_patient` (`person_id`),
  KEY `idx_status` (`current_status`),
  KEY `idx_enrollment` (`enrollment_date`),
  CONSTRAINT `fk_patient_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_art_after_enrollment` CHECK (`art_start_date` IS NULL OR `art_start_date` >= `enrollment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUB TYPE: staff (Specialization from person)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `staff` (
  `staff_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `person_id` INT UNSIGNED NOT NULL,
  `staff_number` VARCHAR(50) NOT NULL UNIQUE,
  `employment_date` DATE NOT NULL,
  `employment_status` ENUM('Active', 'Inactive', 'Terminated') NOT NULL DEFAULT 'Active',
  `qualification` VARCHAR(255) DEFAULT NULL,
  `specialization` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`staff_id`),
  UNIQUE KEY `uk_staff_number` (`staff_number`),
  UNIQUE KEY `uk_person_staff` (`person_id`),
  CONSTRAINT `fk_staff_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ROLE TABLE (for Overlapping Specialization)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `role` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(50) NOT NULL UNIQUE,
  `role_description` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_role_name` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- STAFF_ROLE (Overlapping Specialization Mapping)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `staff_role` (
  `staff_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `assigned_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`staff_role_id`),
  UNIQUE KEY `uk_staff_role` (`staff_id`, `role_id`),
  CONSTRAINT `fk_staff_role_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_staff_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VISIT TABLE (HMIS 031 fields)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `visit` (
  `visit_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `visit_date` DATE NOT NULL,
  `visit_type` ENUM('Initial', 'Follow-up', 'Emergency', 'Refill') NOT NULL,
  `staff_id` INT UNSIGNED NOT NULL COMMENT 'Attending clinician',
  `weight` DECIMAL(5,2) DEFAULT NULL COMMENT 'Weight in kg',
  `height` DECIMAL(5,2) DEFAULT NULL COMMENT 'Height in cm',
  `bp_systolic` INT UNSIGNED DEFAULT NULL,
  `bp_diastolic` INT UNSIGNED DEFAULT NULL,
  `temperature` DECIMAL(4,2) DEFAULT NULL COMMENT 'Temperature in Celsius',
  `pulse` INT UNSIGNED DEFAULT NULL,
  `respiratory_rate` INT UNSIGNED DEFAULT NULL,
  `clinical_notes` TEXT DEFAULT NULL,
  `diagnosis` TEXT DEFAULT NULL,
  `who_stage` ENUM('Stage 1', 'Stage 2', 'Stage 3', 'Stage 4') DEFAULT NULL,
  `tb_screening_result` ENUM('Negative', 'Positive', 'Suspected', 'Not Done') DEFAULT 'Not Done',
  `pregnancy_test_result` ENUM('Negative', 'Positive', 'Not Done', 'Not Applicable') DEFAULT 'Not Applicable',
  `next_appointment_date` DATE DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`visit_id`),
  KEY `idx_visit_date` (`visit_date`),
  KEY `idx_patient_visit` (`patient_id`, `visit_date`),
  KEY `idx_staff_visit` (`staff_id`),
  CONSTRAINT `fk_visit_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_visit_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_visit_date_not_future` CHECK (`visit_date` <= CURDATE())
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LAB_TEST TABLE (Categorization: test_type)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `lab_test` (
  `lab_test_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `test_type` ENUM('Viral Load', 'CD4', 'HB', 'Creatinine', 'Malaria RDT', 'TB-LAM', 'Urinalysis') NOT NULL COMMENT 'Categorization',
  `test_date` DATE NOT NULL,
  `ordered_by` INT UNSIGNED DEFAULT NULL COMMENT 'Staff who ordered',
  `performed_by` INT UNSIGNED DEFAULT NULL COMMENT 'Lab technician',
  `sample_id` VARCHAR(100) DEFAULT NULL COMMENT 'CPHL Sample ID for VL',
  `sample_collection_date` DATE DEFAULT NULL,
  `result_value` VARCHAR(255) DEFAULT NULL COMMENT 'Numeric or text result',
  `result_numeric` DECIMAL(10,2) DEFAULT NULL COMMENT 'For numeric results (VL, CD4, etc.)',
  `result_text` TEXT DEFAULT NULL COMMENT 'For text results',
  `result_unit` VARCHAR(20) DEFAULT NULL COMMENT 'Unit of measurement',
  `reference_range` VARCHAR(100) DEFAULT NULL,
  `is_abnormal` BOOLEAN DEFAULT NULL,
  `status` ENUM('Pending', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`lab_test_id`),
  KEY `idx_test_date` (`test_date`),
  KEY `idx_patient_test` (`patient_id`, `test_type`, `test_date`),
  KEY `idx_test_type` (`test_type`),
  KEY `idx_sample_id` (`sample_id`),
  CONSTRAINT `fk_lab_test_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_test_ordered_by` FOREIGN KEY (`ordered_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_test_performed_by` FOREIGN KEY (`performed_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_test_date_not_future` CHECK (`test_date` <= CURDATE()),
  CONSTRAINT `chk_vl_result_non_negative` CHECK (`test_type` != 'Viral Load' OR `result_numeric` IS NULL OR `result_numeric` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- REGIMEN TABLE (ART Regimens - Uganda MOH naming)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `regimen` (
  `regimen_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `regimen_code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'MOH Regimen Code',
  `regimen_name` VARCHAR(255) NOT NULL COMMENT 'e.g., TDF/3TC/DTG',
  `regimen_line` ENUM('First Line', 'Second Line', 'Third Line') NOT NULL,
  `is_pediatric` BOOLEAN NOT NULL DEFAULT FALSE,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `description` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`regimen_id`),
  UNIQUE KEY `uk_regimen_code` (`regimen_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DISPENSE TABLE (Pharmacy Dispensing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `dispense` (
  `dispense_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `regimen_id` INT UNSIGNED NOT NULL,
  `dispense_date` DATE NOT NULL,
  `dispensed_by` INT UNSIGNED NOT NULL COMMENT 'Pharmacist',
  `days_supply` INT UNSIGNED NOT NULL COMMENT 'Days of medication supplied',
  `quantity` INT UNSIGNED NOT NULL,
  `next_refill_date` DATE NOT NULL COMMENT 'Calculated: dispense_date + days_supply',
  `batch_number` VARCHAR(100) DEFAULT NULL,
  `expiry_date` DATE DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`dispense_id`),
  KEY `idx_dispense_date` (`dispense_date`),
  KEY `idx_patient_dispense` (`patient_id`, `dispense_date`),
  KEY `idx_next_refill` (`next_refill_date`),
  CONSTRAINT `fk_dispense_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_dispense_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_dispense_staff` FOREIGN KEY (`dispensed_by`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_dispense_date_not_future` CHECK (`dispense_date` <= CURDATE()),
  CONSTRAINT `chk_days_supply_range` CHECK (`days_supply` > 0 AND `days_supply` <= 365),
  CONSTRAINT `chk_next_refill_calc` CHECK (`next_refill_date` = DATE_ADD(`dispense_date`, INTERVAL `days_supply` DAY))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- APPOINTMENT TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `appointment` (
  `appointment_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `appointment_date` DATE NOT NULL,
  `appointment_time` TIME DEFAULT NULL,
  `appointment_type` ENUM('Routine', 'Follow-up', 'VL Review', 'Counseling', 'Emergency') NOT NULL,
  `scheduled_by` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('Scheduled', 'Attended', 'Missed', 'Cancelled', 'Rescheduled') NOT NULL DEFAULT 'Scheduled',
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`appointment_id`),
  KEY `idx_appointment_date` (`appointment_date`, `status`),
  KEY `idx_patient_appointment` (`patient_id`, `appointment_date`),
  CONSTRAINT `fk_appointment_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_appointment_staff` FOREIGN KEY (`scheduled_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COUNSELING_SESSION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `counseling_session` (
  `counseling_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `session_date` DATE NOT NULL,
  `counselor_id` INT UNSIGNED NOT NULL,
  `session_type` ENUM('Adherence Support', 'Psychosocial', 'Disclosure', 'Pre-ART', 'Post-ART', 'Other') NOT NULL,
  `session_duration` INT UNSIGNED DEFAULT NULL COMMENT 'Duration in minutes',
  `topics_discussed` TEXT DEFAULT NULL,
  `outcomes` TEXT DEFAULT NULL,
  `follow_up_required` BOOLEAN DEFAULT FALSE,
  `next_session_date` DATE DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`counseling_id`),
  KEY `idx_session_date` (`session_date`),
  KEY `idx_patient_counseling` (`patient_id`, `session_date`),
  CONSTRAINT `fk_counseling_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_counseling_counselor` FOREIGN KEY (`counselor_id`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADHERENCE_LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `adherence_log` (
  `adherence_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `assessment_date` DATE NOT NULL,
  `assessment_method` ENUM('Pill Count', 'Self-Report', 'CAG', 'Computed') NOT NULL,
  `assessed_by` INT UNSIGNED DEFAULT NULL,
  `adherence_percentage` DECIMAL(5,2) NOT NULL COMMENT '0-100%',
  `pills_missed` INT UNSIGNED DEFAULT NULL,
  `pills_expected` INT UNSIGNED DEFAULT NULL,
  `days_missed` INT UNSIGNED DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`adherence_id`),
  KEY `idx_assessment_date` (`assessment_date`),
  KEY `idx_patient_adherence` (`patient_id`, `assessment_date`),
  CONSTRAINT `fk_adherence_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adherence_staff` FOREIGN KEY (`assessed_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_adherence_range` CHECK (`adherence_percentage` >= 0 AND `adherence_percentage` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ALERT TABLE (Automated Alerts)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `alert` (
  `alert_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `alert_type` ENUM('High Viral Load', 'Overdue VL', 'Missed Refill', 'Missed Appointment', 'Low Adherence', 'LTFU Risk', 'Other') NOT NULL,
  `alert_message` TEXT NOT NULL,
  `severity` ENUM('Low', 'Medium', 'High', 'Critical') NOT NULL DEFAULT 'Medium',
  `status` ENUM('Active', 'Acknowledged', 'Resolved', 'Dismissed') NOT NULL DEFAULT 'Active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `acknowledged_at` TIMESTAMP NULL DEFAULT NULL,
  `acknowledged_by` INT UNSIGNED DEFAULT NULL,
  `resolved_at` TIMESTAMP NULL DEFAULT NULL,
  `resolved_by` INT UNSIGNED DEFAULT NULL,
  `related_entity_type` VARCHAR(50) DEFAULT NULL COMMENT 'e.g., lab_test, appointment, dispense',
  `related_entity_id` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`alert_id`),
  KEY `idx_alert_status` (`status`, `severity`),
  KEY `idx_patient_alert` (`patient_id`, `status`),
  KEY `idx_alert_type` (`alert_type`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_alert_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_acknowledged_by` FOREIGN KEY (`acknowledged_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT_LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `audit_log` (
  `audit_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `table_name` VARCHAR(100) NOT NULL,
  `record_id` INT UNSIGNED NOT NULL,
  `action` ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  `old_values` JSON DEFAULT NULL COMMENT 'Previous values (for UPDATE/DELETE)',
  `new_values` JSON DEFAULT NULL COMMENT 'New values (for INSERT/UPDATE)',
  `changed_by` INT UNSIGNED DEFAULT NULL COMMENT 'Staff who made the change',
  `changed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`audit_id`),
  KEY `idx_table_record` (`table_name`, `record_id`),
  KEY `idx_changed_at` (`changed_at`),
  KEY `idx_action` (`action`),
  CONSTRAINT `fk_audit_staff` FOREIGN KEY (`changed_by`) REFERENCES `staff` (`staff_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Additional composite indexes for common queries
CREATE INDEX `idx_patient_status_enrollment` ON `patient` (`current_status`, `enrollment_date`);
CREATE INDEX `idx_visit_patient_date` ON `visit` (`patient_id`, `visit_date` DESC);
CREATE INDEX `idx_lab_test_patient_type_date` ON `lab_test` (`patient_id`, `test_type`, `test_date` DESC);
CREATE INDEX `idx_dispense_patient_date` ON `dispense` (`patient_id`, `dispense_date` DESC);
CREATE INDEX `idx_appointment_patient_status` ON `appointment` (`patient_id`, `status`, `appointment_date`);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

