-- ============================================================================
-- FIX PATIENT INSERT
-- This script inserts patient records if they don't exist
-- Run this if person records exist but patient records are missing
-- ============================================================================

USE hiv_patient_care;

-- Check current state
SELECT 
    'Current State' AS check_type,
    (SELECT COUNT(*) FROM person WHERE person_id >= 31) AS person_count,
    (SELECT COUNT(*) FROM patient) AS patient_count;

-- Insert patients using INSERT IGNORE to handle duplicates
INSERT IGNORE INTO `patient` (`person_id`, `patient_code`, `enrollment_date`, `art_start_date`, `current_status`, `next_of_kin`, `nok_phone`, `support_group`, `treatment_partner`) VALUES
(31, 'MGH/ART/0001', '2024-04-04', '2024-04-26', 'Transferred-Out', 'Next of Kin 1', NULL, NULL, NULL),
(32, 'MGH/ART/0002', '2020-04-10', '2020-05-06', 'Dead', 'Next of Kin 2', '+256794269221', 'Kasawo CAG', 'Partner 2'),
(33, 'MGH/ART/0003', '2020-05-25', '2020-06-14', 'LTFU', 'Next of Kin 3', NULL, NULL, NULL),
(34, 'MGH/ART/0004', '2021-06-20', '2021-06-23', 'Dead', 'Next of Kin 4', '+256781292926', 'Kigombya CAG', 'Partner 4'),
(35, 'MGH/ART/0005', '2021-07-13', '2021-07-25', 'Transferred-Out', 'Next of Kin 5', '+256785207272', NULL, NULL),
(36, 'MGH/ART/0006', '2023-02-05', '2023-02-07', 'Active', 'Next of Kin 6', NULL, NULL, 'Partner 6'),
(37, 'MGH/ART/0007', '2021-08-24', '2021-09-17', 'Active', 'Next of Kin 7', '+256776378073', 'Kasawo CAG', NULL),
(38, 'MGH/ART/0008', '2022-02-23', '2022-03-23', 'Active', 'Next of Kin 8', '+256728977658', NULL, NULL),
(39, 'MGH/ART/0009', '2022-01-02', '2022-01-24', 'Active', 'Next of Kin 9', NULL, 'Nakawa CAG', 'Partner 9'),
(40, 'MGH/ART/0010', '2020-08-13', '2020-08-17', 'Dead', 'Next of Kin 10', '+256722560974', NULL, 'Partner 10');

-- Verify insertion
SELECT 
    'After Insert' AS check_type,
    (SELECT COUNT(*) FROM patient) AS patient_count,
    (SELECT COUNT(*) FROM person WHERE person_id >= 31) AS person_count;

