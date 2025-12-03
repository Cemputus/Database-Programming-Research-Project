-- ============================================================================
-- SEED DATA
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- Sample data for testing and development
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- Insert Roles
-- System access roles for staff members
-- ============================================================================

INSERT INTO `role` (`role_name`) VALUES
('db_admin'),
('db_clinician'),
('db_lab'),
('db_pharmacy'),
('db_counselor'),
('db_readonly');

-- ============================================================================
-- Insert Staff (Ugandan Names)
-- Sample staff members with Ugandan names and locations
-- ============================================================================

-- Insert Persons for Staff
INSERT INTO `person` (`nin`, `first_name`, `last_name`, `other_name`, `sex`, `date_of_birth`, `phone_contact`, `district`, `subcounty`, `parish`, `village`) VALUES
('CM12345-67890-1', 'James', 'Nakato', 'Mukasa', 'M', '1980-05-15', '+256701234567', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CF12345-67890-2', 'Sarah', 'Kigozi', 'Nakiganda', 'F', '1985-08-22', '+256702345678', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('CM12345-67890-3', 'David', 'Mugerwa', 'Ssemwogerere', 'M', '1990-03-10', '+256703456789', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('CF12345-67890-4', 'Grace', 'Nalubega', 'Nabukeera', 'F', '1988-11-30', '+256704567890', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CM12345-67890-5', 'Peter', 'Ssebunya', 'Kigozi', 'M', '1992-07-18', '+256705678901', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('CF12345-67890-6', 'Mary', 'Namukasa', 'Nakato', 'F', '1987-04-25', '+256706789012', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('CM12345-67890-7', 'John', 'Kawuma', 'Mukasa', 'M', '1983-09-12', '+256707890123', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CF12345-67890-8', 'Ruth', 'Nakiganda', 'Nabukeera', 'F', '1991-12-05', '+256708901234', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo');

-- Insert Staff
INSERT INTO `staff` (`person_id`, `staff_code`, `cadre`, `moH_registration_no`, `hire_date`, `active`) VALUES
(1, 'STF001', 'Doctor', 'MOH-DOC-001', '2015-01-15', TRUE),
(2, 'STF002', 'Clinical Officer', 'MOH-CO-002', '2016-03-20', TRUE),
(3, 'STF003', 'Lab Technician', 'MOH-LAB-003', '2017-06-10', TRUE),
(4, 'STF004', 'Pharmacist', 'MOH-PHARM-004', '2018-02-14', TRUE),
(5, 'STF005', 'Nurse', 'MOH-NURSE-005', '2019-05-08', TRUE),
(6, 'STF006', 'Counselor', 'MOH-COUNS-006', '2020-08-22', TRUE),
(7, 'STF007', 'Records Officer', NULL, '2021-01-10', TRUE),
(8, 'STF008', 'Midwife', 'MOH-MID-008', '2018-09-15', TRUE);

-- Assign Staff Roles (Overlapping Specialization)
-- Staff can have multiple roles (e.g., Nurse can be db_clinician and db_admin)
INSERT INTO `staff_role` (`staff_id`, `role_id`) VALUES
(1, 2), -- Doctor -> db_clinician
(2, 2), -- Clinical Officer -> db_clinician
(3, 3), -- Lab Technician -> db_lab
(4, 4), -- Pharmacist -> db_pharmacy
(5, 2), -- Nurse -> db_clinician
(5, 1), -- Nurse also -> db_admin (for testing)
(6, 5), -- Counselor -> db_counselor
(7, 6), -- Records Officer -> db_readonly
(8, 2); -- Midwife -> db_clinician

-- ============================================================================
-- Insert ART Regimens (Uganda MOH Standard)
-- Standard ART regimens following Uganda Ministry of Health guidelines
-- ============================================================================

INSERT INTO `regimen` (`regimen_code`, `regimen_name`, `line`) VALUES
('TDF-3TC-DTG', 'TDF/3TC/DTG', 'First Line'),
('TDF-3TC-EFV', 'TDF/3TC/EFV', 'First Line'),
('ABC-3TC-DTG', 'ABC/3TC/DTG', 'First Line'),
('AZT-3TC-EFV', 'AZT/3TC/EFV', 'First Line'),
('TDF-3TC-LPV/r', 'TDF/3TC/LPV/r', 'Second Line'),
('AZT-3TC-LPV/r', 'AZT/3TC/LPV/r', 'Second Line'),
('TDF-3TC-ATV/r', 'TDF/3TC/ATV/r', 'Second Line'),
('DRV-ETR-RAL', 'DRV/ETR/RAL', 'Third Line');

-- ============================================================================
-- Insert Sample Patients (Ugandan Names)
-- Sample HIV patients with Ugandan names and locations
-- ============================================================================

-- Insert Persons for Patients
INSERT INTO `person` (`nin`, `first_name`, `last_name`, `other_name`, `sex`, `date_of_birth`, `phone_contact`, `district`, `subcounty`, `parish`, `village`) VALUES
('CM23456-78901-1', 'Moses', 'Kigozi', 'Ssemakula', 'M', '1985-06-20', '+256712345678', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CF23456-78901-2', 'Esther', 'Nalubega', 'Nakiganda', 'F', '1990-09-15', '+256723456789', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('CM23456-78901-3', 'Joseph', 'Ssebunya', 'Mukasa', 'M', '1988-03-12', '+256734567890', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('CF23456-78901-4', 'Rebecca', 'Namukasa', 'Nabukeera', 'F', '1992-11-25', '+256745678901', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CM23456-78901-5', 'Daniel', 'Mugerwa', 'Kigozi', 'M', '1987-07-08', '+256756789012', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('CF23456-78901-6', 'Priscilla', 'Kawuma', 'Nakato', 'F', '1991-04-30', '+256767890123', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('CM23456-78901-7', 'Samuel', 'Nakato', 'Ssemwogerere', 'M', '1989-10-18', '+256778901234', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('CF23456-78901-8', 'Hannah', 'Kigozi', 'Nabukeera', 'F', '1993-02-14', '+256789012345', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('CM23456-78901-9', 'Isaac', 'Nalubega', 'Mukasa', 'M', '1986-08-22', '+256790123456', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('CF23456-78901-10', 'Ruth', 'Ssebunya', 'Nakiganda', 'F', '1990-12-05', '+256701234567', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya');

-- Insert Patients
INSERT INTO `patient` (`person_id`, `patient_code`, `enrollment_date`, `art_start_date`, `current_status`, `next_of_kin`, `nok_phone`, `support_group`, `treatment_partner`) VALUES
(9, 'MGH/ART/0001', '2023-01-15', '2023-01-20', 'Active', 'Sarah Kigozi', '+256712345679', 'Kigombya CAG', 'Sarah Kigozi'),
(10, 'MGH/ART/0002', '2023-02-10', '2023-02-15', 'Active', 'John Nalubega', '+256723456790', NULL, 'John Nalubega'),
(11, 'MGH/ART/0003', '2023-03-05', '2023-03-10', 'Active', 'Mary Ssebunya', '+256734567891', 'Ntinda CAG', 'Mary Ssebunya'),
(12, 'MGH/ART/0004', '2023-04-12', '2023-04-18', 'Active', 'David Namukasa', '+256745678902', NULL, 'David Namukasa'),
(13, 'MGH/ART/0005', '2023-05-20', '2023-05-25', 'Active', 'Grace Mugerwa', '+256756789013', 'Kasawo CAG', 'Grace Mugerwa'),
(14, 'MGH/ART/0006', '2023-06-08', '2023-06-12', 'Active', 'Peter Kawuma', '+256767890124', NULL, NULL),
(15, 'MGH/ART/0007', '2022-11-15', '2022-11-20', 'Active', 'Esther Nakato', '+256778901235', 'Kigombya CAG', 'Esther Nakato'),
(16, 'MGH/ART/0008', '2023-07-22', '2023-07-28', 'Active', 'Joseph Kigozi', '+256789012346', NULL, 'Joseph Kigozi'),
(17, 'MGH/ART/0009', '2022-09-10', '2022-09-15', 'Active', 'Rebecca Nalubega', '+256790123457', 'Ntinda CAG', 'Rebecca Nalubega'),
(18, 'MGH/ART/0010', '2023-08-30', '2023-09-05', 'Active', 'Daniel Ssebunya', '+256701234568', NULL, 'Daniel Ssebunya');

-- ============================================================================
-- Insert Sample Visits
-- Clinical visit records with vital signs and assessments
-- ============================================================================

INSERT INTO `visit` (`patient_id`, `staff_id`, `visit_date`, `who_stage`, `weight_kg`, `bp`, `tb_screening`, `symptoms`, `oi_diagnosis`, `next_appointment_date`) VALUES
(1, 1, '2024-01-15', 2, 68.5, '120/80', 'Negative', 'No complaints', 'Stable on treatment', '2024-02-15'),
(1, 1, '2024-02-15', 2, 69.0, '118/78', 'Negative', 'Good adherence reported', 'Stable', '2024-03-15'),
(2, 2, '2024-02-10', 1, 55.2, '115/75', 'Negative', 'Patient stable', 'Stable on treatment', '2024-03-10'),
(3, 1, '2024-03-05', 1, 72.3, '125/82', 'Negative', 'No complaints', 'Stable', '2024-04-05'),
(4, 2, '2024-04-12', 2, 58.5, '110/70', 'Negative', 'New patient enrollment', 'HIV positive, newly diagnosed', '2024-05-12'),
(4, 2, '2024-05-12', 2, 59.0, '112/72', 'Negative', 'Pregnant patient, monitoring closely', 'Stable, pregnancy progressing well', '2024-06-12'),
(5, 1, '2024-05-20', 2, 65.8, '122/79', 'Negative', 'Patient doing well', 'Stable on treatment', '2024-06-20');

-- ============================================================================
-- Insert Sample Lab Tests
-- Laboratory test results including viral load and CD4 counts
-- ============================================================================

INSERT INTO `lab_test` (`patient_id`, `visit_id`, `staff_id`, `test_type`, `test_date`, `result_numeric`, `result_text`, `units`, `cphl_sample_id`, `result_status`) VALUES
(1, 1, 3, 'Viral Load', '2024-01-20', 450.00, NULL, 'copies/mL', 'CPHL-VL-2024-001', 'Completed'),
(1, 1, 3, 'CD4', '2024-01-20', 420, NULL, 'cells/mm³', NULL, 'Completed'),
(1, 2, 3, 'Viral Load', '2024-03-15', 1200.00, NULL, 'copies/mL', 'CPHL-VL-2024-045', 'Completed'),
(2, 3, 3, 'Viral Load', '2024-02-15', 280.00, NULL, 'copies/mL', 'CPHL-VL-2024-020', 'Completed'),
(2, 3, 3, 'CD4', '2024-02-15', 350, NULL, 'cells/mm³', NULL, 'Completed'),
(3, 4, 3, 'Viral Load', '2024-03-10', 150.00, NULL, 'copies/mL', 'CPHL-VL-2024-035', 'Completed'),
(4, 5, 3, 'Viral Load', '2024-04-18', 38000.00, NULL, 'copies/mL', 'CPHL-VL-2024-050', 'Completed'),
(4, 5, 3, 'CD4', '2024-04-18', 310, NULL, 'cells/mm³', NULL, 'Completed'),
(5, 7, 3, 'Viral Load', '2024-05-25', 320.00, NULL, 'copies/mL', 'CPHL-VL-2024-065', 'Completed'),
(6, NULL, 3, 'Viral Load', '2024-06-12', 180.00, NULL, 'copies/mL', 'CPHL-VL-2024-080', 'Completed'),
(7, NULL, 3, 'Viral Load', '2024-01-10', 95.00, NULL, 'copies/mL', 'CPHL-VL-2024-005', 'Completed'),
(8, NULL, 3, 'Viral Load', '2024-07-28', 250.00, NULL, 'copies/mL', 'CPHL-VL-2024-095', 'Completed'),
(9, NULL, 3, 'Viral Load', '2024-02-05', 110.00, NULL, 'copies/mL', 'CPHL-VL-2024-015', 'Completed'),
(10, NULL, 3, 'Viral Load', '2024-09-05', 290.00, NULL, 'copies/mL', 'CPHL-VL-2024-110', 'Completed');

-- ============================================================================
-- Insert Sample Dispenses
-- Medication dispensing records with refill dates
-- ============================================================================

INSERT INTO `dispense` (`patient_id`, `staff_id`, `regimen_id`, `dispense_date`, `days_supply`, `quantity_dispensed`, `next_refill_date`, `notes`) VALUES
(1, 4, 1, '2024-01-20', 30, 30, '2024-02-19', 'Initial dispense'),
(1, 4, 1, '2024-02-19', 30, 30, '2024-03-20', 'Refill'),
(1, 4, 1, '2024-03-20', 30, 30, '2024-04-19', 'Refill'),
(2, 4, 1, '2024-02-15', 30, 30, '2024-03-16', 'Initial dispense'),
(2, 4, 1, '2024-03-16', 30, 30, '2024-04-15', 'Refill'),
(3, 4, 1, '2024-03-10', 30, 30, '2024-04-09', 'Initial dispense'),
(4, 4, 1, '2024-04-18', 30, 30, '2024-05-18', 'Initial dispense - Pregnant patient'),
(4, 4, 1, '2024-05-18', 30, 30, '2024-06-17', 'Refill'),
(5, 4, 1, '2024-05-25', 30, 30, '2024-06-24', 'Initial dispense'),
(6, 4, 1, '2024-06-12', 30, 30, '2024-07-12', 'Initial dispense'),
(7, 4, 1, '2024-01-10', 30, 30, '2024-02-09', 'Refill'),
(8, 4, 1, '2024-07-28', 30, 30, '2024-08-27', 'Initial dispense'),
(9, 4, 1, '2024-02-05', 30, 30, '2024-03-06', 'Refill'),
(10, 4, 1, '2024-09-05', 30, 30, '2024-10-05', 'Initial dispense');

-- ============================================================================
-- Insert Sample Appointments
-- Patient appointment scheduling records
-- ============================================================================

INSERT INTO `appointment` (`patient_id`, `staff_id`, `scheduled_date`, `status`, `reason`) VALUES
(1, 1, '2024-04-15', 'Scheduled', 'Routine follow-up'),
(2, 2, '2024-04-10', 'Scheduled', 'Routine follow-up'),
(3, 1, '2024-05-05', 'Scheduled', 'Routine follow-up'),
(4, 2, '2024-06-12', 'Scheduled', 'Pregnancy monitoring'),
(5, 1, '2024-06-20', 'Scheduled', 'Routine follow-up'),
(6, 2, '2024-07-12', 'Scheduled', 'Routine follow-up'),
(1, 1, '2024-01-10', 'Attended', 'Completed'),
(2, 2, '2024-02-05', 'Attended', 'Completed');

-- ============================================================================
-- Insert Sample Counseling Sessions
-- Adherence counseling session records
-- ============================================================================

INSERT INTO `counseling_session` (`patient_id`, `counselor_id`, `session_date`, `topic`, `adherence_barriers`, `notes`) VALUES
(1, 6, '2024-01-20', 'Adherence Support', 'None reported', 'Patient understands importance of adherence'),
(2, 6, '2024-02-15', 'Pre-ART', 'Fear of side effects', 'Patient ready to start ART'),
(4, 6, '2024-04-18', 'Adherence Support', 'Pregnancy concerns', 'Patient understands PMTCT protocols'),
(5, 6, '2024-05-25', 'Adherence Support', 'Work schedule', 'Patient committed to adherence');

-- ============================================================================
-- Insert Sample Adherence Logs
-- Medication adherence assessment records with percentages
-- ============================================================================

INSERT INTO `adherence_log` (`patient_id`, `log_date`, `adherence_percent`, `method_used`, `notes`) VALUES
(1, '2024-02-15', 96.67, 'Pill Count', 'Excellent adherence'),
(1, '2024-03-15', 93.33, 'Self Report', 'Good adherence'),
(2, '2024-03-10', 100.00, 'Pill Count', 'Perfect adherence'),
(3, '2024-04-05', 90.00, 'Self Report', 'Good adherence'),
(4, '2024-05-12', 98.33, 'Pill Count', 'Excellent adherence - pregnant patient'),
(5, '2024-06-20', 88.33, 'Self Report', 'Good adherence'),
(7, '2024-01-10', 100.00, 'Pill Count', 'Perfect adherence'),
(9, '2024-02-05', 95.00, 'Self Report', 'Excellent adherence');

SET FOREIGN_KEY_CHECKS = 1;
