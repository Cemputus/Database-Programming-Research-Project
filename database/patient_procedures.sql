-- ============================================================================
-- PATIENT SELF-SERVICE STORED PROCEDURES
-- Patients access their own data using patient_code (not patient_id)
-- All procedures validate patient_code and return patient-specific data only
-- ============================================================================

DELIMITER //

-- ============================================================================
-- SP: Get Patient Dashboard Data
-- Returns complete patient dashboard with next appointment, last VL, adherence, etc.
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_dashboard`//
CREATE PROCEDURE `sp_patient_dashboard`(
    IN p_patient_code VARCHAR(50)
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_dashboard
    WHERE patient_code = p_patient_code;
END//

-- ============================================================================
-- SP: Get Patient Visit History
-- Returns clinical visit history (most recent first, limited by p_limit)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_visits`//
CREATE PROCEDURE `sp_patient_visits`(
    IN p_patient_code VARCHAR(50),
    IN p_limit INT UNSIGNED DEFAULT 20
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_visit_history
    WHERE patient_id = v_patient_id
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Lab Test History
-- Returns lab test results (optionally filtered by test_type like 'Viral Load')
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_lab_tests`//
CREATE PROCEDURE `sp_patient_lab_tests`(
    IN p_patient_code VARCHAR(50),
    IN p_test_type VARCHAR(50) DEFAULT NULL,
    IN p_limit INT UNSIGNED DEFAULT 50
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_lab_history
    WHERE patient_id = v_patient_id
      AND (p_test_type IS NULL OR test_type = p_test_type)
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Medication History
-- Returns medication dispensing records with refill status
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_medications`//
CREATE PROCEDURE `sp_patient_medications`(
    IN p_patient_code VARCHAR(50),
    IN p_limit INT UNSIGNED DEFAULT 20
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_medication_history
    WHERE patient_id = v_patient_id
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Appointments
-- Returns appointments (optionally filtered by status like 'Scheduled')
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_appointments`//
CREATE PROCEDURE `sp_patient_appointments`(
    IN p_patient_code VARCHAR(50),
    IN p_status VARCHAR(50) DEFAULT NULL,
    IN p_limit INT UNSIGNED DEFAULT 20
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_appointments
    WHERE patient_id = v_patient_id
      AND (p_status IS NULL OR status = p_status)
    ORDER BY scheduled_date DESC
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Adherence History
-- Returns adherence assessment records with percentages and methods
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_adherence`//
CREATE PROCEDURE `sp_patient_adherence`(
    IN p_patient_code VARCHAR(50),
    IN p_limit INT UNSIGNED DEFAULT 12
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_adherence_history
    WHERE patient_id = v_patient_id
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Alerts
-- Returns alerts (p_resolved_only=FALSE for active, TRUE for resolved)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_alerts`//
CREATE PROCEDURE `sp_patient_alerts`(
    IN p_patient_code VARCHAR(50),
    IN p_resolved_only BOOLEAN DEFAULT FALSE,
    IN p_limit INT UNSIGNED DEFAULT 20
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_alerts
    WHERE patient_id = v_patient_id
      AND (p_resolved_only = FALSE OR is_resolved = TRUE)
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Progress Timeline
-- Returns chronological timeline of all care events (enrollment, visits, tests, etc.)
-- Can filter by date range (p_start_date, p_end_date)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_progress_timeline`//
CREATE PROCEDURE `sp_patient_progress_timeline`(
    IN p_patient_code VARCHAR(50),
    IN p_start_date DATE DEFAULT NULL,
    IN p_end_date DATE DEFAULT NULL,
    IN p_limit INT UNSIGNED DEFAULT 50
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_progress_timeline
    WHERE patient_id = v_patient_id
      AND (p_start_date IS NULL OR event_date >= p_start_date)
      AND (p_end_date IS NULL OR event_date <= p_end_date)
    LIMIT p_limit;
END//

-- ============================================================================
-- SP: Get Patient Next Appointment
-- Returns next upcoming scheduled appointment (if any)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_next_appointment`//
CREATE PROCEDURE `sp_patient_next_appointment`(
    IN p_patient_code VARCHAR(50)
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    -- Get patient_id from patient_code
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    -- Return next appointment
    SELECT 
        a.appointment_id,
        a.scheduled_date,
        a.status,
        a.reason,
        DATEDIFF(a.scheduled_date, CURDATE()) AS days_until_appointment,
        CONCAT(per.first_name, ' ', per.last_name) AS scheduled_by_name,
        s.cadre AS scheduled_by_cadre
    FROM appointment a
    LEFT JOIN staff s ON a.staff_id = s.staff_id
    LEFT JOIN person per ON s.person_id = per.person_id
    WHERE a.patient_id = v_patient_id
      AND a.status = 'Scheduled'
      AND a.scheduled_date >= CURDATE()
    ORDER BY a.scheduled_date ASC
    LIMIT 1;
END//

-- ============================================================================
-- SP: Get Patient Summary Stats
-- Returns summary statistics: total visits, tests, dispenses, average adherence, etc.
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_summary_stats`//
CREATE PROCEDURE `sp_patient_summary_stats`(
    IN p_patient_code VARCHAR(50)
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    
    -- Get patient_id from patient_code
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    -- Return summary statistics
    SELECT 
        (SELECT COUNT(*) FROM visit WHERE patient_id = v_patient_id) AS total_visits,
        (SELECT COUNT(*) FROM lab_test WHERE patient_id = v_patient_id AND result_status = 'Completed') AS total_lab_tests,
        (SELECT COUNT(*) FROM dispense WHERE patient_id = v_patient_id) AS total_dispenses,
        (SELECT COUNT(*) FROM appointment WHERE patient_id = v_patient_id AND status = 'Attended') AS total_appointments_attended,
        (SELECT COUNT(*) FROM appointment WHERE patient_id = v_patient_id AND status = 'Missed') AS total_appointments_missed,
        (SELECT COUNT(*) FROM adherence_log WHERE patient_id = v_patient_id) AS total_adherence_assessments,
        (SELECT AVG(adherence_percent) FROM adherence_log WHERE patient_id = v_patient_id) AS average_adherence,
        (SELECT COUNT(*) FROM alert WHERE patient_id = v_patient_id AND is_resolved = FALSE) AS active_alerts,
        (SELECT MAX(visit_date) FROM visit WHERE patient_id = v_patient_id) AS last_visit_date,
        (SELECT MAX(dispense_date) FROM dispense WHERE patient_id = v_patient_id) AS last_dispense_date,
        (SELECT MAX(test_date) FROM lab_test WHERE patient_id = v_patient_id AND test_type = 'Viral Load' AND result_status = 'Completed') AS last_vl_date;
END//

DELIMITER ;

