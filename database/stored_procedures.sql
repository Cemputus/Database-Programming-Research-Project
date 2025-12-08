-- ============================================================================
-- STORED PROCEDURES
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

USE hiv_patient_care;

DELIMITER //

-- ============================================================================
-- SP: Compute Adherence for a Patient
-- Calculates medication adherence percentage (0-100%)
-- Based on dispense records: (pills taken / pills expected) × 100
-- Saves result to adherence_log with method 'Computed'
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_compute_adherence`//
CREATE PROCEDURE `sp_compute_adherence`(
    IN p_patient_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_pills_expected INT UNSIGNED;
    DECLARE v_pills_missed INT UNSIGNED;
    DECLARE v_adherence_percentage DECIMAL(5,2);
    DECLARE v_days_in_period INT;
    DECLARE v_daily_pills INT UNSIGNED DEFAULT 1;
    
    -- Get most recent dispense to determine current prescription
    SELECT d.days_supply, d.quantity_dispensed, d.dispense_date
    INTO v_days_in_period, v_pills_expected, v_daily_pills
    FROM dispense d
    WHERE d.patient_id = p_patient_id
      AND d.dispense_date <= COALESCE(p_end_date, CURDATE())
    ORDER BY d.dispense_date DESC
    LIMIT 1;
    
    -- Default to 30 days if no dispense record found
    IF v_days_in_period IS NULL THEN
        SET v_days_in_period = DATEDIFF(COALESCE(p_end_date, CURDATE()), COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 30 DAY)));
        SET v_pills_expected = v_days_in_period * v_daily_pills;
    END IF;
    
    -- Calculate missed pills (simplified - uses dispense data only)
    SET v_pills_missed = GREATEST(0, v_pills_expected - COALESCE((
        SELECT SUM(quantity_dispensed) 
        FROM dispense 
        WHERE patient_id = p_patient_id 
          AND dispense_date BETWEEN COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 30 DAY)) 
          AND COALESCE(p_end_date, CURDATE())
    ), v_pills_expected));
    
    -- Calculate adherence percentage: (pills taken / pills expected) × 100
    IF v_pills_expected > 0 THEN
        SET v_adherence_percentage = ((v_pills_expected - v_pills_missed) / v_pills_expected) * 100;
    ELSE
        SET v_adherence_percentage = 0;
    END IF;
    
    -- Save to adherence log
    INSERT INTO adherence_log (
        patient_id,
        log_date,
        method_used,
        adherence_percent,
        notes
    ) VALUES (
        p_patient_id,
        COALESCE(p_end_date, CURDATE()),
        'Computed',
        v_adherence_percentage,
        CONCAT('Computed from dispense records. Pills expected: ', v_pills_expected, ', Pills missed: ', v_pills_missed)
    );
    
    SELECT v_adherence_percentage AS adherence_percentage,
           v_pills_missed AS pills_missed,
           v_pills_expected AS pills_expected;
END//

-- ============================================================================
-- SP: Check Overdue Viral Load Tests
-- Finds patients overdue for VL test (>180 days per Uganda guidelines)
-- Creates 'Overdue VL' alerts for patients needing tests
-- Runs daily via scheduled event
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_check_overdue_vl`//
CREATE PROCEDURE `sp_check_overdue_vl`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_last_vl_date DATE;
    DECLARE v_days_since_vl INT;
    DECLARE v_alert_exists INT;
    
    -- Process each active patient on ART
    DECLARE patient_cursor CURSOR FOR
        SELECT DISTINCT p.patient_id
        FROM patient p
        WHERE p.current_status = 'Active'
          AND p.art_start_date IS NOT NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN patient_cursor;
    
    patient_loop: LOOP
        FETCH patient_cursor INTO v_patient_id;
        IF done THEN
            LEAVE patient_loop;
        END IF;
        
        -- Find most recent completed VL test
        SELECT MAX(test_date)
        INTO v_last_vl_date
        FROM lab_test
        WHERE patient_id = v_patient_id
          AND test_type = 'Viral Load'
          AND result_status = 'Completed';
        
        -- Calculate days since last VL (or since ART start if no test)
        IF v_last_vl_date IS NULL THEN
            SET v_days_since_vl = DATEDIFF(CURDATE(), (
                SELECT art_start_date 
                FROM patient 
                WHERE patient_id = v_patient_id
            ));
        ELSE
            SET v_days_since_vl = DATEDIFF(CURDATE(), v_last_vl_date);
        END IF;
        
        -- Check if alert already exists
    SELECT COUNT(*) INTO v_alert_exists
    FROM alert
    WHERE patient_id = v_patient_id
      AND alert_type = 'Overdue VL'
      AND is_resolved = FALSE;
    
        -- Create alert if VL overdue (>180 days) and no active alert exists
    IF v_days_since_vl > 180 AND v_alert_exists = 0 THEN
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_level,
            alert_msg,
            is_resolved
        ) VALUES (
            v_patient_id,
            'Overdue VL',
            'Warning',
            CONCAT('Viral load test is overdue. Last test: ', 
                   COALESCE(DATE_FORMAT(v_last_vl_date, '%Y-%m-%d'), 'Never'),
                   ' (', v_days_since_vl, ' days ago)'),
            FALSE
        );
    END IF;
    END LOOP;
    
    CLOSE patient_cursor;
    
    SELECT COUNT(*) AS alerts_created
    FROM alert
    WHERE alert_type = 'Overdue VL'
      AND DATE(triggered_at) = CURDATE();
END//

-- ============================================================================
-- SP: Mark Missed Appointments
-- Updates appointments to 'Missed' status if past due by grace_days (default 14)
-- Creates alerts for missed appointments
-- Runs daily via scheduled event
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_mark_missed_appointments`//
CREATE PROCEDURE `sp_mark_missed_appointments`(
    IN p_grace_days INT UNSIGNED
)
BEGIN
    DECLARE v_grace_days INT UNSIGNED DEFAULT COALESCE(p_grace_days, 14);
    
    -- Update appointments past due
    UPDATE appointment
    SET status = 'Missed'
    WHERE status = 'Scheduled'
      AND scheduled_date < DATE_SUB(CURDATE(), INTERVAL v_grace_days DAY);
    
    -- Create alerts for missed appointments
    INSERT INTO alert (patient_id, alert_type, alert_level, alert_msg, is_resolved)
    SELECT 
        a.patient_id,
        'Missed Appointment',
        'Warning',
        CONCAT('Patient missed appointment scheduled for ', DATE_FORMAT(a.scheduled_date, '%Y-%m-%d')),
        FALSE
    FROM appointment a
    WHERE a.status = 'Missed'
      AND a.scheduled_date < DATE_SUB(CURDATE(), INTERVAL v_grace_days DAY)
      AND NOT EXISTS (
          SELECT 1 FROM alert al
          WHERE al.patient_id = a.patient_id
            AND al.alert_type = 'Missed Appointment'
            AND al.is_resolved = FALSE
            AND DATE(al.triggered_at) = CURDATE()
      );
    
    SELECT COUNT(*) AS missed_appointments_marked
    FROM appointment
    WHERE status = 'Missed'
      AND scheduled_date < DATE_SUB(CURDATE(), INTERVAL v_grace_days DAY);
END//

-- ============================================================================
-- SP: Update Patient Status to LTFU (Lost to Follow-Up)
-- Marks patients as LTFU if no visit or dispense for >90 days (Uganda standard)
-- Creates LTFU alerts
-- Runs daily via scheduled event
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_update_patient_status_ltfu`//
CREATE PROCEDURE `sp_update_patient_status_ltfu`()
BEGIN
    DECLARE v_ltfu_days INT UNSIGNED DEFAULT 90;
    
    -- Update patients who haven't had a visit or dispense in 90+ days
    UPDATE patient p
    SET p.current_status = 'LTFU'
    WHERE p.current_status = 'Active'
      AND NOT EXISTS (
          SELECT 1 FROM visit v
          WHERE v.patient_id = p.patient_id
            AND v.visit_date >= DATE_SUB(CURDATE(), INTERVAL v_ltfu_days DAY)
      )
      AND NOT EXISTS (
          SELECT 1 FROM dispense d
          WHERE d.patient_id = p.patient_id
            AND d.dispense_date >= DATE_SUB(CURDATE(), INTERVAL v_ltfu_days DAY)
      )
      AND DATEDIFF(CURDATE(), COALESCE((
          SELECT GREATEST(
              MAX(v.visit_date),
              MAX(d.dispense_date)
          )
          FROM (
              SELECT MAX(visit_date) AS visit_date, NULL AS dispense_date
              FROM visit WHERE patient_id = p.patient_id
              UNION ALL
              SELECT NULL, MAX(dispense_date)
              FROM dispense WHERE patient_id = p.patient_id
          ) AS combined
      ), p.enrollment_date)) >= v_ltfu_days;
    
    -- Create LTFU alerts (Note: LTFU Risk alert type not in enum, using 'Severe OI' as placeholder)
    INSERT INTO alert (patient_id, alert_type, alert_level, alert_msg, is_resolved)
    SELECT 
        p.patient_id,
        'Severe OI',
        'Critical',
        CONCAT('Patient marked as LTFU. Last contact: ', 
               COALESCE(DATE_FORMAT(GREATEST(
                   (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id),
                   (SELECT MAX(dispense_date) FROM dispense WHERE patient_id = p.patient_id)
               ), '%Y-%m-%d'), 'Unknown')),
        FALSE
    FROM patient p
    WHERE p.current_status = 'LTFU'
      AND NOT EXISTS (
          SELECT 1 FROM alert al
          WHERE al.patient_id = p.patient_id
            AND al.alert_type = 'Severe OI'
            AND al.is_resolved = FALSE
            AND DATE(al.triggered_at) = CURDATE()
      );
    
    SELECT COUNT(*) AS patients_marked_ltfu
    FROM patient
    WHERE current_status = 'LTFU';
END//

-- ============================================================================
-- SP: Check Missed Refills
-- Finds patients with missed refills (next_refill_date < today)
-- Creates 'Missed Refill' alerts
-- Runs daily via scheduled event
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_check_missed_refills`//
CREATE PROCEDURE `sp_check_missed_refills`()
BEGIN
    -- Create alerts for patients with missed refills
    INSERT INTO alert (patient_id, alert_type, alert_level, alert_msg, is_resolved)
    SELECT 
        d.patient_id,
        'Missed Refill',
        'Warning',
        CONCAT('Patient missed refill. Expected refill date: ', 
               DATE_FORMAT(d.next_refill_date, '%Y-%m-%d'),
               ' (', DATEDIFF(CURDATE(), d.next_refill_date), ' days overdue)'),
        FALSE
    FROM dispense d
    INNER JOIN patient p ON d.patient_id = p.patient_id
    WHERE p.current_status = 'Active'
      AND d.next_refill_date < CURDATE()
      AND NOT EXISTS (
          SELECT 1 FROM dispense d2
          WHERE d2.patient_id = d.patient_id
            AND d2.dispense_date > d.dispense_date
      )
      AND NOT EXISTS (
          SELECT 1 FROM alert al
          WHERE al.patient_id = d.patient_id
            AND al.alert_type = 'Missed Refill'
            AND al.is_resolved = FALSE
            AND DATE(al.triggered_at) = CURDATE()
      );
    
    SELECT COUNT(*) AS missed_refill_alerts_created
    FROM alert
    WHERE alert_type = 'Missed Refill'
      AND DATE(triggered_at) = CURDATE();
END//

-- ============================================================================
-- PATIENT SELF-SERVICE STORED PROCEDURES
-- Patients access their own data using patient_code (not patient_id)
-- All procedures validate patient_code and return patient-specific data only
-- ============================================================================

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
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 20;
    
    SET v_limit = COALESCE(p_limit, 20);
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_visit_history
    WHERE patient_id = v_patient_id
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Lab Test History
-- Returns lab test results (optionally filtered by test_type like 'Viral Load')
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_lab_tests`//
CREATE PROCEDURE `sp_patient_lab_tests`(
    IN p_patient_code VARCHAR(50),
    IN p_test_type VARCHAR(50),
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 50;
    
    SET v_limit = COALESCE(p_limit, 50);
    
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
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Medication History
-- Returns medication dispensing records with refill status
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_medications`//
CREATE PROCEDURE `sp_patient_medications`(
    IN p_patient_code VARCHAR(50),
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 20;
    
    SET v_limit = COALESCE(p_limit, 20);
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_medication_history
    WHERE patient_id = v_patient_id
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Appointments
-- Returns appointments (optionally filtered by status like 'Scheduled')
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_appointments`//
CREATE PROCEDURE `sp_patient_appointments`(
    IN p_patient_code VARCHAR(50),
    IN p_status VARCHAR(50),
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 20;
    
    SET v_limit = COALESCE(p_limit, 20);
    
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
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Adherence History
-- Returns adherence assessment records with percentages and methods
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_adherence`//
CREATE PROCEDURE `sp_patient_adherence`(
    IN p_patient_code VARCHAR(50),
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 12;
    
    SET v_limit = COALESCE(p_limit, 12);
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_adherence_history
    WHERE patient_id = v_patient_id
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Alerts
-- Returns alerts (p_resolved_only=FALSE for active, TRUE for resolved)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_alerts`//
CREATE PROCEDURE `sp_patient_alerts`(
    IN p_patient_code VARCHAR(50),
    IN p_resolved_only BOOLEAN,
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 20;
    DECLARE v_resolved_only BOOLEAN DEFAULT FALSE;
    
    SET v_limit = COALESCE(p_limit, 20);
    SET v_resolved_only = COALESCE(p_resolved_only, FALSE);
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    SELECT * FROM v_patient_alerts
    WHERE patient_id = v_patient_id
      AND (v_resolved_only = FALSE OR is_resolved = TRUE)
    LIMIT v_limit;
END//

-- ============================================================================
-- SP: Get Patient Progress Timeline
-- Returns chronological timeline of all care events (enrollment, visits, tests, etc.)
-- Can filter by date range (p_start_date, p_end_date)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_patient_progress_timeline`//
CREATE PROCEDURE `sp_patient_progress_timeline`(
    IN p_patient_code VARCHAR(50),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_limit INT UNSIGNED
)
BEGIN
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_limit INT UNSIGNED DEFAULT 50;
    
    SET v_limit = COALESCE(p_limit, 50);
    
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
    LIMIT v_limit;
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
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
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
    
    SELECT patient_id INTO v_patient_id
    FROM patient
    WHERE patient_code = p_patient_code;
    
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
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

-- ============================================================================
-- CAG MANAGEMENT STORED PROCEDURES
-- Community ART Group (CAG) operations
-- ============================================================================

-- ============================================================================
-- SP: Add Patient to CAG
-- Adds a patient to a Community ART Group
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_add_patient`//
CREATE PROCEDURE `sp_cag_add_patient`(
    IN p_patient_id INT UNSIGNED,
    IN p_cag_id INT UNSIGNED,
    IN p_role_in_cag ENUM('Member', 'Coordinator', 'Deputy Coordinator')
)
BEGIN
    DECLARE v_cag_status VARCHAR(20);
    DECLARE v_current_members INT;
    DECLARE v_max_members INT;
    DECLARE v_patient_status VARCHAR(20);
    DECLARE v_error_msg VARCHAR(255);
    
    SELECT status, max_members INTO v_cag_status, v_max_members
    FROM cag
    WHERE cag_id = p_cag_id;
    
    IF v_cag_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG not found';
    END IF;
    
    IF v_cag_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG is not active';
    END IF;
    
    SELECT current_status INTO v_patient_status
    FROM patient
    WHERE patient_id = p_patient_id;
    
    IF v_patient_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    IF v_patient_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only active patients can join CAG';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM patient_cag 
        WHERE patient_id = p_patient_id 
          AND cag_id = p_cag_id 
          AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already an active member of this CAG';
    END IF;
    
    SELECT COUNT(*) INTO v_current_members
    FROM patient_cag
    WHERE cag_id = p_cag_id AND is_active = TRUE;
    
    IF v_current_members >= v_max_members THEN
        SET v_error_msg = CONCAT('CAG has reached maximum members (', v_max_members, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    UPDATE patient_cag
    SET is_active = FALSE,
        exit_date = CURDATE(),
        exit_reason = 'Joined another CAG'
    WHERE patient_id = p_patient_id 
      AND is_active = TRUE
      AND cag_id != p_cag_id;
    
    INSERT INTO patient_cag (
        patient_id,
        cag_id,
        join_date,
        role_in_cag,
        is_active
    ) VALUES (
        p_patient_id,
        p_cag_id,
        CURDATE(),
        p_role_in_cag,
        TRUE
    );
    
    IF p_role_in_cag = 'Coordinator' THEN
        UPDATE cag
        SET coordinator_patient_id = p_patient_id
        WHERE cag_id = p_cag_id;
    END IF;
    
    SELECT 'Patient added to CAG successfully' AS result;
END//

-- ============================================================================
-- SP: Remove Patient from CAG
-- Removes a patient from a CAG (marks as inactive)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_remove_patient`//
CREATE PROCEDURE `sp_cag_remove_patient`(
    IN p_patient_id INT UNSIGNED,
    IN p_cag_id INT UNSIGNED,
    IN p_exit_reason VARCHAR(200)
)
BEGIN
    DECLARE v_is_coordinator BOOLEAN DEFAULT FALSE;
    
    SELECT COUNT(*) > 0 INTO v_is_coordinator
    FROM patient_cag
    WHERE patient_id = p_patient_id
      AND cag_id = p_cag_id
      AND role_in_cag = 'Coordinator'
      AND is_active = TRUE;
    
    UPDATE patient_cag
    SET is_active = FALSE,
        exit_date = CURDATE(),
        exit_reason = p_exit_reason
    WHERE patient_id = p_patient_id
      AND cag_id = p_cag_id
      AND is_active = TRUE;
    
    IF v_is_coordinator THEN
        UPDATE cag
        SET coordinator_patient_id = NULL
        WHERE cag_id = p_cag_id;
    END IF;
    
    SELECT 'Patient removed from CAG successfully' AS result;
END//

-- ============================================================================
-- SP: Record CAG Rotation
-- Records when a CAG member picks up medications for the group
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_record_rotation`//
CREATE PROCEDURE `sp_cag_record_rotation`(
    IN p_cag_id INT UNSIGNED,
    IN p_pickup_patient_id INT UNSIGNED,
    IN p_rotation_date DATE,
    IN p_dispense_id BIGINT UNSIGNED,
    IN p_patients_served TINYINT UNSIGNED,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_cag_status VARCHAR(20);
    DECLARE v_is_member BOOLEAN DEFAULT FALSE;
    
    SELECT status INTO v_cag_status
    FROM cag
    WHERE cag_id = p_cag_id;
    
    IF v_cag_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG not found';
    END IF;
    
    IF v_cag_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG is not active';
    END IF;
    
    SELECT COUNT(*) > 0 INTO v_is_member
    FROM patient_cag
    WHERE patient_id = p_pickup_patient_id
      AND cag_id = p_cag_id
      AND is_active = TRUE;
    
    IF NOT v_is_member THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pickup patient is not an active member of this CAG';
    END IF;
    
    INSERT INTO cag_rotation (
        cag_id,
        pickup_patient_id,
        rotation_date,
        dispense_id,
        patients_served,
        notes
    ) VALUES (
        p_cag_id,
        p_pickup_patient_id,
        p_rotation_date,
        p_dispense_id,
        p_patients_served,
        p_notes
    );
    
    SELECT LAST_INSERT_ID() AS rotation_id, 'Rotation recorded successfully' AS result;
END//

-- ============================================================================
-- SP: Get CAG Members
-- Returns all active members of a specific CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_members`//
CREATE PROCEDURE `sp_cag_get_members`(
    IN p_cag_id INT UNSIGNED
)
BEGIN
    SELECT 
        pc.patient_cag_id,
        pc.patient_id,
        p.patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS patient_name,
        per.sex,
        TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) AS age,
        pc.join_date,
        pc.role_in_cag,
        p.current_status,
        p.art_start_date,
        (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id) AS last_visit_date,
        (SELECT MAX(test_date) FROM lab_test 
         WHERE patient_id = p.patient_id 
           AND test_type = 'Viral Load' 
           AND result_status = 'Completed') AS last_vl_date,
        (SELECT result_numeric FROM lab_test 
         WHERE patient_id = p.patient_id 
           AND test_type = 'Viral Load' 
           AND result_status = 'Completed'
         ORDER BY test_date DESC LIMIT 1) AS last_vl_result,
        (SELECT adherence_percent FROM adherence_log 
         WHERE patient_id = p.patient_id 
         ORDER BY log_date DESC LIMIT 1) AS last_adherence
    FROM patient_cag pc
    INNER JOIN patient p ON pc.patient_id = p.patient_id
    INNER JOIN person per ON p.person_id = per.person_id
    WHERE pc.cag_id = p_cag_id
      AND pc.is_active = TRUE
    ORDER BY pc.role_in_cag DESC, pc.join_date;
END//

-- ============================================================================
-- SP: Get CAG Rotation History
-- Returns rotation history for a specific CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_rotations`//
CREATE PROCEDURE `sp_cag_get_rotations`(
    IN p_cag_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        cr.rotation_id,
        cr.rotation_date,
        cr.pickup_patient_id,
        p.patient_code AS pickup_patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS pickup_patient_name,
        cr.patients_served,
        cr.dispense_id,
        d.dispense_date,
        r.regimen_name,
        cr.notes
    FROM cag_rotation cr
    INNER JOIN patient p ON cr.pickup_patient_id = p.patient_id
    INNER JOIN person per ON p.person_id = per.person_id
    LEFT JOIN dispense d ON cr.dispense_id = d.dispense_id
    LEFT JOIN regimen r ON d.regimen_id = r.regimen_id
    WHERE cr.cag_id = p_cag_id
      AND (p_start_date IS NULL OR cr.rotation_date >= p_start_date)
      AND (p_end_date IS NULL OR cr.rotation_date <= p_end_date)
    ORDER BY cr.rotation_date DESC;
END//

-- ============================================================================
-- SP: Get CAG Statistics
-- Returns comprehensive statistics for a CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_statistics`//
CREATE PROCEDURE `sp_cag_get_statistics`(
    IN p_cag_id INT UNSIGNED
)
BEGIN
    SELECT 
        c.cag_id,
        c.cag_name,
        c.district,
        c.subcounty,
        c.parish,
        c.village,
        c.formation_date,
        c.status,
        c.max_members,
        COUNT(DISTINCT pc.patient_id) AS active_members,
        AVG(ad.adherence_percent) AS avg_adherence,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 95 THEN pc.patient_id END) AS excellent_adherence_count,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 85 AND ad.adherence_percent < 95 THEN pc.patient_id END) AS good_adherence_count,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent < 85 THEN pc.patient_id END) AS poor_adherence_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric < 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS suppressed_vl_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric >= 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS unsuppressed_vl_count,
        COUNT(DISTINCT cr.rotation_id) AS total_rotations,
        MAX(cr.rotation_date) AS last_rotation_date,
        MIN(cr.rotation_date) AS first_rotation_date,
        DATEDIFF(CURDATE(), MIN(cr.rotation_date)) AS days_since_first_rotation
    FROM cag c
    LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
    LEFT JOIN adherence_log ad ON pc.patient_id = ad.patient_id
    LEFT JOIN lab_test lt ON pc.patient_id = lt.patient_id 
        AND lt.test_type = 'Viral Load' 
        AND lt.result_status = 'Completed'
        AND lt.test_date = (
            SELECT MAX(test_date) 
            FROM lab_test 
            WHERE patient_id = pc.patient_id 
              AND test_type = 'Viral Load' 
              AND result_status = 'Completed'
        )
    LEFT JOIN cag_rotation cr ON c.cag_id = cr.cag_id
    WHERE c.cag_id = p_cag_id
    GROUP BY c.cag_id, c.cag_name, c.district, c.subcounty, c.parish, c.village, 
             c.formation_date, c.status, c.max_members;
END//

DELIMITER ;

