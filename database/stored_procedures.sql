-- ============================================================================
-- STORED PROCEDURES
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

DELIMITER //

-- ============================================================================
-- SP: Compute Adherence for a Patient
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
    
    -- Get the most recent dispense record
    SELECT d.days_supply, d.quantity, d.dispense_date
    INTO v_days_in_period, v_pills_expected, v_daily_pills
    FROM dispense d
    WHERE d.patient_id = p_patient_id
      AND d.dispense_date <= COALESCE(p_end_date, CURDATE())
    ORDER BY d.dispense_date DESC
    LIMIT 1;
    
    -- If no dispense found, use default period
    IF v_days_in_period IS NULL THEN
        SET v_days_in_period = DATEDIFF(COALESCE(p_end_date, CURDATE()), COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 30 DAY)));
        SET v_pills_expected = v_days_in_period * v_daily_pills;
    END IF;
    
    -- Calculate pills missed (simplified - in real system, use pill count data)
    SET v_pills_missed = GREATEST(0, v_pills_expected - COALESCE((
        SELECT SUM(quantity) 
        FROM dispense 
        WHERE patient_id = p_patient_id 
          AND dispense_date BETWEEN COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 30 DAY)) 
          AND COALESCE(p_end_date, CURDATE())
    ), v_pills_expected));
    
    -- Calculate adherence percentage
    IF v_pills_expected > 0 THEN
        SET v_adherence_percentage = ((v_pills_expected - v_pills_missed) / v_pills_expected) * 100;
    ELSE
        SET v_adherence_percentage = 0;
    END IF;
    
    -- Insert or update adherence log
    INSERT INTO adherence_log (
        patient_id,
        assessment_date,
        assessment_method,
        adherence_percentage,
        pills_missed,
        pills_expected,
        days_missed
    ) VALUES (
        p_patient_id,
        COALESCE(p_end_date, CURDATE()),
        'Computed',
        v_adherence_percentage,
        v_pills_missed,
        v_pills_expected,
        CEIL(v_pills_missed / v_daily_pills)
    )
    ON DUPLICATE KEY UPDATE
        adherence_percentage = v_adherence_percentage,
        pills_missed = v_pills_missed,
        pills_expected = v_pills_expected,
        days_missed = CEIL(v_pills_missed / v_daily_pills),
        updated_at = CURRENT_TIMESTAMP;
    
    SELECT v_adherence_percentage AS adherence_percentage,
           v_pills_missed AS pills_missed,
           v_pills_expected AS pills_expected;
END//

-- ============================================================================
-- SP: Check Overdue Viral Load Tests
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_check_overdue_vl`//
CREATE PROCEDURE `sp_check_overdue_vl`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_patient_id INT UNSIGNED;
    DECLARE v_last_vl_date DATE;
    DECLARE v_days_since_vl INT;
    DECLARE v_alert_exists INT;
    
    -- Cursor for patients who need VL monitoring
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
        
        -- Get last viral load test date
        SELECT MAX(test_date)
        INTO v_last_vl_date
        FROM lab_test
        WHERE patient_id = v_patient_id
          AND test_type = 'Viral Load'
          AND status = 'Completed';
        
        -- If no VL test or VL is older than 6 months (180 days), create alert
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
          AND status = 'Active';
        
        -- Create alert if VL is overdue (>180 days) and no active alert exists
        IF v_days_since_vl > 180 AND v_alert_exists = 0 THEN
            INSERT INTO alert (
                patient_id,
                alert_type,
                alert_message,
                severity,
                status
            ) VALUES (
                v_patient_id,
                'Overdue VL',
                CONCAT('Viral load test is overdue. Last test: ', 
                       COALESCE(DATE_FORMAT(v_last_vl_date, '%Y-%m-%d'), 'Never'),
                       ' (', v_days_since_vl, ' days ago)'),
                'High',
                'Active'
            );
        END IF;
    END LOOP;
    
    CLOSE patient_cursor;
    
    SELECT COUNT(*) AS alerts_created
    FROM alert
    WHERE alert_type = 'Overdue VL'
      AND DATE(created_at) = CURDATE();
END//

-- ============================================================================
-- SP: Mark Missed Appointments
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_mark_missed_appointments`//
CREATE PROCEDURE `sp_mark_missed_appointments`(
    IN p_grace_days INT UNSIGNED
)
BEGIN
    DECLARE v_grace_days INT UNSIGNED DEFAULT COALESCE(p_grace_days, 14);
    
    -- Update appointments that are past due (more than grace_days)
    UPDATE appointment
    SET status = 'Missed',
        updated_at = CURRENT_TIMESTAMP
    WHERE status = 'Scheduled'
      AND appointment_date < DATE_SUB(CURDATE(), INTERVAL v_grace_days DAY);
    
    -- Create alerts for missed appointments
    INSERT INTO alert (patient_id, alert_type, alert_message, severity, status, related_entity_type, related_entity_id)
    SELECT 
        a.patient_id,
        'Missed Appointment',
        CONCAT('Patient missed appointment scheduled for ', DATE_FORMAT(a.appointment_date, '%Y-%m-%d')),
        'Medium',
        'Active',
        'appointment',
        a.appointment_id
    FROM appointment a
    WHERE a.status = 'Missed'
      AND a.appointment_date < DATE_SUB(CURDATE(), INTERVAL v_grace_days DAY)
      AND NOT EXISTS (
          SELECT 1 FROM alert al
          WHERE al.patient_id = a.patient_id
            AND al.alert_type = 'Missed Appointment'
            AND al.related_entity_id = a.appointment_id
            AND al.status = 'Active'
      );
    
    SELECT COUNT(*) AS missed_appointments_marked
    FROM appointment
    WHERE status = 'Missed'
      AND DATE(updated_at) = CURDATE();
END//

-- ============================================================================
-- SP: Update Patient Status to LTFU (Lost to Follow-Up)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_update_patient_status_ltfu`()
BEGIN
    DECLARE v_ltfu_days INT UNSIGNED DEFAULT 90;
    
    -- Update patients who haven't had a visit or dispense in 90+ days
    UPDATE patient p
    SET p.current_status = 'LTFU',
        p.updated_at = CURRENT_TIMESTAMP
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
    
    -- Create LTFU alerts
    INSERT INTO alert (patient_id, alert_type, alert_message, severity, status)
    SELECT 
        p.patient_id,
        'LTFU Risk',
        CONCAT('Patient marked as LTFU. Last contact: ', 
               COALESCE(DATE_FORMAT(GREATEST(
                   (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id),
                   (SELECT MAX(dispense_date) FROM dispense WHERE patient_id = p.patient_id)
               ), '%Y-%m-%d'), 'Unknown')),
        'Critical',
        'Active'
    FROM patient p
    WHERE p.current_status = 'LTFU'
      AND DATE(p.updated_at) = CURDATE()
      AND NOT EXISTS (
          SELECT 1 FROM alert al
          WHERE al.patient_id = p.patient_id
            AND al.alert_type = 'LTFU Risk'
            AND al.status = 'Active'
      );
    
    SELECT COUNT(*) AS patients_marked_ltfu
    FROM patient
    WHERE current_status = 'LTFU'
      AND DATE(updated_at) = CURDATE();
END//

-- ============================================================================
-- SP: Check Missed Refills
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_check_missed_refills`()
BEGIN
    -- Create alerts for patients with missed refills
    INSERT INTO alert (patient_id, alert_type, alert_message, severity, status, related_entity_type, related_entity_id)
    SELECT 
        d.patient_id,
        'Missed Refill',
        CONCAT('Patient missed refill. Expected refill date: ', 
               DATE_FORMAT(d.next_refill_date, '%Y-%m-%d'),
               ' (', DATEDIFF(CURDATE(), d.next_refill_date), ' days overdue)'),
        'High',
        'Active',
        'dispense',
        d.dispense_id
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
            AND al.related_entity_id = d.dispense_id
            AND al.status = 'Active'
      );
    
    SELECT COUNT(*) AS missed_refill_alerts_created
    FROM alert
    WHERE alert_type = 'Missed Refill'
      AND DATE(created_at) = CURDATE();
END//

DELIMITER ;

