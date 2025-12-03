-- ============================================================================
-- SCHEDULED EVENTS
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

-- Enable Event Scheduler
SET GLOBAL event_scheduler = ON;

DELIMITER //

-- ============================================================================
-- EVENT: Daily Check Overdue Viral Load
-- ============================================================================

DROP EVENT IF EXISTS `evt_daily_check_overdue_vl`//

CREATE EVENT `evt_daily_check_overdue_vl`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 8 HOUR
DO
BEGIN
    CALL sp_check_overdue_vl();
END//

-- ============================================================================
-- EVENT: Daily Check Missed Appointments
-- ============================================================================

DROP EVENT IF EXISTS `evt_daily_check_missed_appointments`//

CREATE EVENT `evt_daily_check_missed_appointments`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 8 HOUR
DO
BEGIN
    CALL sp_mark_missed_appointments(14); -- 14 days grace period
END//

-- ============================================================================
-- EVENT: Daily Check Missed Refills
-- ============================================================================

DROP EVENT IF EXISTS `evt_daily_check_missed_refills`//

CREATE EVENT `evt_daily_check_missed_refills`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 8 HOUR
DO
BEGIN
    CALL sp_check_missed_refills();
END//

-- ============================================================================
-- EVENT: Weekly Adherence Computation
-- ============================================================================

DROP EVENT IF EXISTS `evt_weekly_compute_adherence`//

CREATE EVENT `evt_weekly_compute_adherence`
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 9 HOUR
DO
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_patient_id INT UNSIGNED;
    
    DECLARE patient_cursor CURSOR FOR
        SELECT patient_id
        FROM patient
        WHERE current_status = 'Active';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN patient_cursor;
    
    patient_loop: LOOP
        FETCH patient_cursor INTO v_patient_id;
        IF done THEN
            LEAVE patient_loop;
        END IF;
        
        CALL sp_compute_adherence(v_patient_id, NULL, NULL);
    END LOOP;
    
    CLOSE patient_cursor;
END//

-- ============================================================================
-- EVENT: Daily Update LTFU Status
-- ============================================================================

DROP EVENT IF EXISTS `evt_daily_update_ltfu`//

CREATE EVENT `evt_daily_update_ltfu`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 7 HOUR
DO
BEGIN
    CALL sp_update_patient_status_ltfu();
END//

DELIMITER ;

