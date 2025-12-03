-- ============================================================================
-- SEED DATA
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- Insert Roles
-- ============================================================================

INSERT INTO `role` (`role_name`, `role_description`) VALUES
('doctor', 'Medical Doctor'),
('clinical officer', 'Clinical Officer'),
('nurse', 'Nurse'),
('midwife', 'Midwife'),
('lab technician', 'Laboratory Technician'),
('pharmacist', 'Pharmacist'),
('counselor', 'Counselor'),
('records officer', 'Records Officer');

-- ============================================================================
-- Insert Staff (Ugandan Names)
-- ============================================================================

-- Insert Persons for Staff
INSERT INTO `person` (`nin`, `first_name`, `middle_name`, `last_name`, `date_of_birth`, `gender`, `phone_number`, `email`, `district`, `subcounty`, `parish`, `village`) VALUES
('NIN001001', 'James', 'Mukasa', 'Nakato', '1980-05-15', 'Male', '+256701234567', 'james.nakato@mukonohospital.go.ug', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN001002', 'Sarah', 'Nakiganda', 'Kigozi', '1985-08-22', 'Female', '+256702345678', 'sarah.kigozi@mukonohospital.go.ug', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('NIN001003', 'David', 'Ssemwogerere', 'Mugerwa', '1990-03-10', 'Male', '+256703456789', 'david.mugerwa@mukonohospital.go.ug', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('NIN001004', 'Grace', 'Nabukeera', 'Nalubega', '1988-11-30', 'Female', '+256704567890', 'grace.nalubega@mukonohospital.go.ug', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN001005', 'Peter', 'Kigozi', 'Ssebunya', '1992-07-18', 'Male', '+256705678901', 'peter.ssebunya@mukonohospital.go.ug', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('NIN001006', 'Mary', 'Nakato', 'Namukasa', '1987-04-25', 'Female', '+256706789012', 'mary.namukasa@mukonohospital.go.ug', 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('NIN001007', 'John', 'Mukasa', 'Kawuma', '1983-09-12', 'Male', '+256707890123', 'john.kawuma@mukonohospital.go.ug', 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN001008', 'Ruth', 'Nabukeera', 'Nakiganda', '1991-12-05', 'Female', '+256708901234', 'ruth.nakiganda@mukonohospital.go.ug', 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo');

-- Insert Staff
INSERT INTO `staff` (`person_id`, `staff_number`, `employment_date`, `employment_status`, `qualification`, `specialization`) VALUES
(1, 'STF001', '2015-01-15', 'Active', 'MBChB', 'Internal Medicine'),
(2, 'STF002', '2016-03-20', 'Active', 'Diploma in Clinical Medicine', 'HIV/AIDS Care'),
(3, 'STF003', '2017-06-10', 'Active', 'BSc Medical Laboratory Science', 'Laboratory Diagnostics'),
(4, 'STF004', '2018-02-14', 'Active', 'BPharm', 'Pharmacy'),
(5, 'STF005', '2019-05-08', 'Active', 'Diploma in Nursing', 'HIV/AIDS Nursing'),
(6, 'STF006', '2020-08-22', 'Active', 'Certificate in Counseling', 'HIV Counseling'),
(7, 'STF007', '2021-01-10', 'Active', 'Diploma in Records Management', 'Health Records'),
(8, 'STF008', '2018-09-15', 'Active', 'Diploma in Midwifery', 'Maternal Health');

-- Assign Staff Roles (Overlapping Specialization)
INSERT INTO `staff_role` (`staff_id`, `role_id`, `assigned_date`, `is_active`) VALUES
(1, 1, '2015-01-15', TRUE), -- Doctor
(2, 2, '2016-03-20', TRUE), -- Clinical Officer
(2, 3, '2016-03-20', TRUE), -- Also Nurse
(3, 5, '2017-06-10', TRUE), -- Lab Technician
(4, 6, '2018-02-14', TRUE), -- Pharmacist
(5, 3, '2019-05-08', TRUE), -- Nurse
(5, 4, '2019-05-08', TRUE), -- Also Midwife
(6, 7, '2020-08-22', TRUE), -- Counselor
(7, 8, '2021-01-10', TRUE), -- Records Officer
(8, 4, '2018-09-15', TRUE); -- Midwife

-- ============================================================================
-- Insert ART Regimens (Uganda MOH Standard)
-- ============================================================================

INSERT INTO `regimen` (`regimen_code`, `regimen_name`, `regimen_line`, `is_pediatric`, `is_active`, `description`) VALUES
('TDF-3TC-DTG', 'TDF/3TC/DTG', 'First Line', FALSE, TRUE, 'Tenofovir/Lamivudine/Dolutegravir - First line for adults'),
('TDF-3TC-EFV', 'TDF/3TC/EFV', 'First Line', FALSE, TRUE, 'Tenofovir/Lamivudine/Efavirenz - First line alternative'),
('ABC-3TC-DTG', 'ABC/3TC/DTG', 'First Line', FALSE, TRUE, 'Abacavir/Lamivudine/Dolutegravir - First line for TDF intolerant'),
('AZT-3TC-EFV', 'AZT/3TC/EFV', 'First Line', FALSE, TRUE, 'Zidovudine/Lamivudine/Efavirenz - First line alternative'),
('TDF-3TC-DTG-PED', 'TDF/3TC/DTG', 'First Line', TRUE, TRUE, 'Pediatric formulation - TDF/3TC/DTG'),
('ABC-3TC-DTG-PED', 'ABC/3TC/DTG', 'First Line', TRUE, TRUE, 'Pediatric formulation - ABC/3TC/DTG'),
('TDF-3TC-LPV/r', 'TDF/3TC/LPV/r', 'Second Line', FALSE, TRUE, 'Second line regimen - Lopinavir/Ritonavir'),
('AZT-3TC-LPV/r', 'AZT/3TC/LPV/r', 'Second Line', FALSE, TRUE, 'Second line alternative'),
('TDF-3TC-ATV/r', 'TDF/3TC/ATV/r', 'Second Line', FALSE, TRUE, 'Second line - Atazanavir/Ritonavir'),
('DRV-ETR-RAL', 'DRV/ETR/RAL', 'Third Line', FALSE, TRUE, 'Third line salvage regimen');

-- ============================================================================
-- Insert Sample Patients (Ugandan Names)
-- ============================================================================

-- Insert Persons for Patients
INSERT INTO `person` (`nin`, `first_name`, `middle_name`, `last_name`, `date_of_birth`, `gender`, `phone_number`, `email`, `district`, `subcounty`, `parish`, `village`) VALUES
('NIN002001', 'Moses', 'Ssemakula', 'Kigozi', '1985-06-20', 'Male', '+256712345678', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN002002', 'Esther', 'Nakiganda', 'Nalubega', '1990-09-15', 'Female', '+256723456789', NULL, 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('NIN002003', 'Joseph', 'Mukasa', 'Ssebunya', '1988-03-12', 'Male', '+256734567890', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('NIN002004', 'Rebecca', 'Nabukeera', 'Namukasa', '1992-11-25', 'Female', '+256745678901', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN002005', 'Daniel', 'Kigozi', 'Mugerwa', '1987-07-08', 'Male', '+256756789012', NULL, 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('NIN002006', 'Priscilla', 'Nakato', 'Kawuma', '1991-04-30', 'Female', '+256767890123', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('NIN002007', 'Samuel', 'Ssemwogerere', 'Nakato', '1989-10-18', 'Male', '+256778901234', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya'),
('NIN002008', 'Hannah', 'Nabukeera', 'Kigozi', '1993-02-14', 'Female', '+256789012345', NULL, 'Mukono', 'Nakifuma', 'Nakifuma', 'Kasawo'),
('NIN002009', 'Isaac', 'Mukasa', 'Nalubega', '1986-08-22', 'Male', '+256790123456', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Ntinda'),
('NIN002010', 'Ruth', 'Nakiganda', 'Ssebunya', '1990-12-05', 'Female', '+256701234567', NULL, 'Mukono', 'Mukono Central', 'Mukono Town', 'Kigombya');

-- Insert Patients
INSERT INTO `patient` (`person_id`, `patient_number`, `enrollment_date`, `art_start_date`, `current_status`, `baseline_cd4`, `baseline_vl`, `who_stage`, `tb_status`, `pregnancy_status`, `next_of_kin_name`, `next_of_kin_phone`, `next_of_kin_relationship`) VALUES
(9, 'PAT001', '2023-01-15', '2023-01-20', 'Active', 350, 45000.00, 'Stage 2', 'No TB', 'Not Applicable', 'Sarah Kigozi', '+256712345679', 'Wife'),
(10, 'PAT002', '2023-02-10', '2023-02-15', 'Active', 280, 32000.00, 'Stage 1', 'No TB', 'Not Pregnant', 'John Nalubega', '+256723456790', 'Brother'),
(11, 'PAT003', '2023-03-05', '2023-03-10', 'Active', 420, 28000.00, 'Stage 1', 'No TB', 'Not Applicable', 'Mary Ssebunya', '+256734567891', 'Sister'),
(12, 'PAT004', '2023-04-12', '2023-04-18', 'Active', 310, 38000.00, 'Stage 2', 'No TB', 'Pregnant', 'David Namukasa', '+256745678902', 'Husband'),
(13, 'PAT005', '2023-05-20', '2023-05-25', 'Active', 290, 41000.00, 'Stage 2', 'No TB', 'Not Applicable', 'Grace Mugerwa', '+256756789013', 'Wife'),
(14, 'PAT006', '2023-06-08', '2023-06-12', 'Active', 380, 25000.00, 'Stage 1', 'No TB', 'Not Pregnant', 'Peter Kawuma', '+256767890124', 'Father'),
(15, 'PAT007', '2022-11-15', '2022-11-20', 'Active', 450, 18000.00, 'Stage 1', 'No TB', 'Not Applicable', 'Esther Nakato', '+256778901235', 'Mother'),
(16, 'PAT008', '2023-07-22', '2023-07-28', 'Active', 320, 36000.00, 'Stage 2', 'No TB', 'Not Pregnant', 'Joseph Kigozi', '+256789012346', 'Brother'),
(17, 'PAT009', '2022-09-10', '2022-09-15', 'Active', 410, 22000.00, 'Stage 1', 'No TB', 'Not Applicable', 'Rebecca Nalubega', '+256790123457', 'Sister'),
(18, 'PAT010', '2023-08-30', '2023-09-05', 'Active', 340, 33000.00, 'Stage 2', 'No TB', 'Breastfeeding', 'Daniel Ssebunya', '+256701234568', 'Husband');

-- ============================================================================
-- Insert Sample Visits
-- ============================================================================

INSERT INTO `visit` (`patient_id`, `visit_date`, `visit_type`, `staff_id`, `weight`, `height`, `bp_systolic`, `bp_diastolic`, `temperature`, `pulse`, `respiratory_rate`, `clinical_notes`, `diagnosis`, `who_stage`, `tb_screening_result`, `pregnancy_test_result`, `next_appointment_date`) VALUES
(1, '2024-01-15', 'Follow-up', 1, 68.5, 175, 120, 80, 36.5, 72, 18, 'Patient doing well on ART', 'Stable on treatment', 'Stage 2', 'Negative', 'Not Applicable', '2024-02-15'),
(1, '2024-02-15', 'Follow-up', 1, 69.0, 175, 118, 78, 36.6, 70, 18, 'Good adherence reported', 'Stable', 'Stage 2', 'Negative', 'Not Applicable', '2024-03-15'),
(2, '2024-02-10', 'Follow-up', 2, 55.2, 162, 115, 75, 36.4, 68, 16, 'Patient stable', 'Stable on treatment', 'Stage 1', 'Negative', 'Negative', '2024-03-10'),
(3, '2024-03-05', 'Follow-up', 1, 72.3, 180, 125, 82, 36.7, 74, 19, 'No complaints', 'Stable', 'Stage 1', 'Negative', 'Not Applicable', '2024-04-05'),
(4, '2024-04-12', 'Initial', 2, 58.5, 165, 110, 70, 36.3, 66, 17, 'New patient enrollment', 'HIV positive, newly diagnosed', 'Stage 2', 'Negative', 'Positive', '2024-05-12'),
(4, '2024-05-12', 'Follow-up', 2, 59.0, 165, 112, 72, 36.4, 67, 17, 'Pregnant patient, monitoring closely', 'Stable, pregnancy progressing well', 'Stage 2', 'Negative', 'Positive', '2024-06-12'),
(5, '2024-05-20', 'Follow-up', 1, 65.8, 170, 122, 79, 36.6, 71, 18, 'Patient doing well', 'Stable on treatment', 'Stage 2', 'Negative', 'Not Applicable', '2024-06-20');

-- ============================================================================
-- Insert Sample Lab Tests
-- ============================================================================

INSERT INTO `lab_test` (`patient_id`, `test_type`, `test_date`, `ordered_by`, `performed_by`, `sample_id`, `sample_collection_date`, `result_value`, `result_numeric`, `result_text`, `result_unit`, `reference_range`, `is_abnormal`, `status`) VALUES
(1, 'Viral Load', '2024-01-20', 1, 3, 'CPHL-VL-2024-001', '2024-01-20', '450', 450.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(1, 'CD4', '2024-01-20', 1, 3, NULL, '2024-01-20', '420', 420, NULL, 'cells/mm³', '500-1200', TRUE, 'Completed'),
(1, 'Viral Load', '2024-03-15', 1, 3, 'CPHL-VL-2024-045', '2024-03-15', '1200', 1200.00, NULL, 'copies/mL', '<1000', TRUE, 'Completed'),
(2, 'Viral Load', '2024-02-15', 2, 3, 'CPHL-VL-2024-020', '2024-02-15', '280', 280.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(2, 'CD4', '2024-02-15', 2, 3, NULL, '2024-02-15', '350', 350, NULL, 'cells/mm³', '500-1200', TRUE, 'Completed'),
(3, 'Viral Load', '2024-03-10', 1, 3, 'CPHL-VL-2024-035', '2024-03-10', '150', 150.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(4, 'Viral Load', '2024-04-18', 2, 3, 'CPHL-VL-2024-050', '2024-04-18', '38000', 38000.00, NULL, 'copies/mL', '<1000', TRUE, 'Completed'),
(4, 'CD4', '2024-04-18', 2, 3, NULL, '2024-04-18', '310', 310, NULL, 'cells/mm³', '500-1200', TRUE, 'Completed'),
(5, 'Viral Load', '2024-05-25', 1, 3, 'CPHL-VL-2024-065', '2024-05-25', '320', 320.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(6, 'Viral Load', '2024-06-12', 2, 3, 'CPHL-VL-2024-080', '2024-06-12', '180', 180.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(7, 'Viral Load', '2024-01-10', 1, 3, 'CPHL-VL-2024-005', '2024-01-10', '95', 95.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(8, 'Viral Load', '2024-07-28', 2, 3, 'CPHL-VL-2024-095', '2024-07-28', '250', 250.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(9, 'Viral Load', '2024-02-05', 1, 3, 'CPHL-VL-2024-015', '2024-02-05', '110', 110.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed'),
(10, 'Viral Load', '2024-09-05', 2, 3, 'CPHL-VL-2024-110', '2024-09-05', '290', 290.00, NULL, 'copies/mL', '<1000', FALSE, 'Completed');

-- ============================================================================
-- Insert Sample Dispenses
-- ============================================================================

INSERT INTO `dispense` (`patient_id`, `regimen_id`, `dispense_date`, `dispensed_by`, `days_supply`, `quantity`, `next_refill_date`, `batch_number`, `expiry_date`, `notes`) VALUES
(1, 1, '2024-01-20', 4, 30, 30, '2024-02-19', 'BATCH-2024-001', '2025-12-31', 'Initial dispense'),
(1, 1, '2024-02-19', 4, 30, 30, '2024-03-20', 'BATCH-2024-015', '2025-12-31', 'Refill'),
(1, 1, '2024-03-20', 4, 30, 30, '2024-04-19', 'BATCH-2024-030', '2025-12-31', 'Refill'),
(2, 1, '2024-02-15', 4, 30, 30, '2024-03-16', 'BATCH-2024-020', '2025-12-31', 'Initial dispense'),
(2, 1, '2024-03-16', 4, 30, 30, '2024-04-15', 'BATCH-2024-035', '2025-12-31', 'Refill'),
(3, 1, '2024-03-10', 4, 30, 30, '2024-04-09', 'BATCH-2024-025', '2025-12-31', 'Initial dispense'),
(4, 1, '2024-04-18', 4, 30, 30, '2024-05-18', 'BATCH-2024-040', '2025-12-31', 'Initial dispense - Pregnant patient'),
(4, 1, '2024-05-18', 4, 30, 30, '2024-06-17', 'BATCH-2024-055', '2025-12-31', 'Refill'),
(5, 1, '2024-05-25', 4, 30, 30, '2024-06-24', 'BATCH-2024-050', '2025-12-31', 'Initial dispense'),
(6, 1, '2024-06-12', 4, 30, 30, '2024-07-12', 'BATCH-2024-065', '2025-12-31', 'Initial dispense'),
(7, 1, '2024-01-10', 4, 30, 30, '2024-02-09', 'BATCH-2024-005', '2025-12-31', 'Refill'),
(8, 1, '2024-07-28', 4, 30, 30, '2024-08-27', 'BATCH-2024-075', '2025-12-31', 'Initial dispense'),
(9, 1, '2024-02-05', 4, 30, 30, '2024-03-06', 'BATCH-2024-010', '2025-12-31', 'Refill'),
(10, 1, '2024-09-05', 4, 30, 30, '2024-10-05', 'BATCH-2024-085', '2025-12-31', 'Initial dispense');

-- ============================================================================
-- Insert Sample Appointments
-- ============================================================================

INSERT INTO `appointment` (`patient_id`, `appointment_date`, `appointment_time`, `appointment_type`, `scheduled_by`, `status`, `notes`) VALUES
(1, '2024-04-15', '09:00:00', 'Routine', 1, 'Scheduled', 'Routine follow-up'),
(2, '2024-04-10', '10:00:00', 'Routine', 2, 'Scheduled', 'Routine follow-up'),
(3, '2024-05-05', '11:00:00', 'Routine', 1, 'Scheduled', 'Routine follow-up'),
(4, '2024-06-12', '09:30:00', 'Routine', 2, 'Scheduled', 'Pregnancy monitoring'),
(5, '2024-06-20', '10:30:00', 'Routine', 1, 'Scheduled', 'Routine follow-up'),
(6, '2024-07-12', '11:30:00', 'Routine', 2, 'Scheduled', 'Routine follow-up'),
(1, '2024-01-10', '09:00:00', 'Routine', 1, 'Attended', 'Completed'),
(2, '2024-02-05', '10:00:00', 'Routine', 2, 'Attended', 'Completed');

-- ============================================================================
-- Insert Sample Counseling Sessions
-- ============================================================================

INSERT INTO `counseling_session` (`patient_id`, `session_date`, `counselor_id`, `session_type`, `session_duration`, `topics_discussed`, `outcomes`, `follow_up_required`, `next_session_date`) VALUES
(1, '2024-01-20', 6, 'Adherence Support', 30, 'ART adherence, side effects management', 'Patient understands importance of adherence', FALSE, NULL),
(2, '2024-02-15', 6, 'Pre-ART', 45, 'HIV education, treatment preparation', 'Patient ready to start ART', FALSE, NULL),
(4, '2024-04-18', 6, 'Adherence Support', 40, 'ART during pregnancy, PMTCT', 'Patient understands PMTCT protocols', TRUE, '2024-05-18'),
(5, '2024-05-25', 6, 'Adherence Support', 35, 'ART adherence, lifestyle', 'Patient committed to adherence', FALSE, NULL);

-- ============================================================================
-- Insert Sample Adherence Logs
-- ============================================================================

INSERT INTO `adherence_log` (`patient_id`, `assessment_date`, `assessment_method`, `assessed_by`, `adherence_percentage`, `pills_missed`, `pills_expected`, `days_missed`, `notes`) VALUES
(1, '2024-02-15', 'Pill Count', 5, 96.67, 1, 30, 1, 'Excellent adherence'),
(1, '2024-03-15', 'Self-Report', 5, 93.33, 2, 30, 2, 'Good adherence'),
(2, '2024-03-10', 'Pill Count', 5, 100.00, 0, 30, 0, 'Perfect adherence'),
(3, '2024-04-05', 'Self-Report', 5, 90.00, 3, 30, 3, 'Good adherence'),
(4, '2024-05-12', 'Pill Count', 5, 98.33, 0.5, 30, 1, 'Excellent adherence - pregnant patient'),
(5, '2024-06-20', 'Self-Report', 5, 88.33, 3.5, 30, 4, 'Good adherence'),
(7, '2024-01-10', 'Pill Count', 5, 100.00, 0, 30, 0, 'Perfect adherence'),
(9, '2024-02-05', 'Self-Report', 5, 95.00, 1.5, 30, 2, 'Excellent adherence');

SET FOREIGN_KEY_CHECKS = 1;

