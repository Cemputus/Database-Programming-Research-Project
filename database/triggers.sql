-- ============================================================================
-- TRIGGERS
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================
--
-- Triggers are like automatic actions that happen when something changes in the database.
-- Think of them like motion-activated lights - when someone walks in (data changes),
-- the light turns on automatically (trigger fires).
--
-- We use triggers to:
-- - Automatically create alerts when something important happens
-- - Keep an audit trail of who changed what and when
-- - Make sure data stays consistent
--
-- The beauty of triggers: They happen automatically, so we don't forget to do these things!
-- ============================================================================

DELIMITER //  -- Need to change delimiter for multi-line trigger code

-- ============================================================================
-- TRIGGER: High Viral Load Alert on Lab Test Insert
-- ============================================================================
--
-- What this does:
-- When a new lab test result is saved, this trigger automatically checks if the
-- viral load is too high. If it is, it immediately creates an alert so staff
-- know to take action.
--
-- Why this matters:
-- A high viral load (over 1000 copies/mL) means the medication isn't working well.
-- This could mean:
-- - The patient isn't taking their medication regularly (poor adherence)
-- - The virus has become resistant to the current medication
-- - The medication needs to be changed
--
-- By creating an alert automatically, we make sure nothing falls through the cracks.
-- Staff will see the alert and can take action right away.
--
-- When it fires:
-- Right after a new lab test record is inserted into the database
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_lab_test_high_vl_alert`//  -- Remove old version if exists
CREATE TRIGGER `trg_lab_test_high_vl_alert`
AFTER INSERT ON `lab_test`  -- This runs AFTER we save a new lab test
FOR EACH ROW  -- Check every new record
BEGIN
    -- Check if this is a viral load test that's been completed
    -- AND if the result is over 1000 copies/mL (that's considered high)
    IF NEW.test_type = 'Viral Load' 
       AND NEW.result_status = 'Completed' 
       AND NEW.result_numeric IS NOT NULL 
       AND NEW.result_numeric > 1000 THEN
        
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_level,
            alert_msg,
            is_resolved
        ) VALUES (
            NEW.patient_id,
            'High Viral Load',
            'Critical',
            CONCAT('High viral load detected: ', NEW.result_numeric, ' copies/mL. Action required.'),
            FALSE
        );
    END IF;
END//

-- ============================================================================
-- TRIGGER: High Viral Load Alert on Lab Test Update
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_lab_test_high_vl_alert_update`//
CREATE TRIGGER `trg_lab_test_high_vl_alert_update`
AFTER UPDATE ON `lab_test`
FOR EACH ROW
BEGIN
    IF NEW.test_type = 'Viral Load' 
       AND NEW.result_status = 'Completed' 
       AND NEW.result_numeric IS NOT NULL 
       AND NEW.result_numeric > 1000 
       AND (OLD.result_numeric IS NULL OR OLD.result_numeric <= 1000) THEN
        
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_level,
            alert_msg,
            is_resolved
        ) VALUES (
            NEW.patient_id,
            'High Viral Load',
            'Critical',
            CONCAT('High viral load detected: ', NEW.result_numeric, ' copies/mL. Action required.'),
            FALSE
        );
    END IF;
END//

-- ============================================================================
-- TRIGGER: Missed Appointment Alert
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_appointment_missed_alert`//
CREATE TRIGGER `trg_appointment_missed_alert`
AFTER UPDATE ON `appointment`
FOR EACH ROW
BEGIN
    IF NEW.status = 'Missed' AND OLD.status != 'Missed' THEN
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_level,
            alert_msg,
            is_resolved
        ) VALUES (
            NEW.patient_id,
            'Missed Appointment',
            'Warning',
            CONCAT('Patient missed appointment scheduled for ', 
                   DATE_FORMAT(NEW.scheduled_date, '%Y-%m-%d')),
            FALSE
        );
    END IF;
END//

-- ============================================================================
-- TRIGGER: Audit Log for Patient Table
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_patient_audit_insert`//
CREATE TRIGGER `trg_patient_audit_insert`
AFTER INSERT ON `patient`
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        details
    ) VALUES (
        'patient',
        CAST(NEW.patient_id AS CHAR),
        'INSERT',
        CONCAT('Patient created: ', NEW.patient_code, ', Status: ', NEW.current_status)
    );
END//

DROP TRIGGER IF EXISTS `trg_patient_audit_update`//
CREATE TRIGGER `trg_patient_audit_update`
AFTER UPDATE ON `patient`
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        details
    ) VALUES (
        'patient',
        CAST(NEW.patient_id AS CHAR),
        'UPDATE',
        CONCAT('Status changed from ', OLD.current_status, ' to ', NEW.current_status)
    );
END//

-- ============================================================================
-- TRIGGER: Audit Log for Visit Table
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_visit_audit_insert`//
CREATE TRIGGER `trg_visit_audit_insert`
AFTER INSERT ON `visit`
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        details
    ) VALUES (
        'visit',
        CAST(NEW.visit_id AS CHAR),
        'INSERT',
        CONCAT('Visit created for patient ', NEW.patient_id, ' on ', NEW.visit_date)
    );
END//

-- ============================================================================
-- TRIGGER: Audit Log for Lab Test Table
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_lab_test_audit_insert`//
CREATE TRIGGER `trg_lab_test_audit_insert`
AFTER INSERT ON `lab_test`
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        new_values,
        changed_at
    ) VALUES (
        'lab_test',
        NEW.lab_test_id,
        'INSERT',
        JSON_OBJECT(
            'lab_test_id', NEW.lab_test_id,
            'patient_id', NEW.patient_id,
            'test_type', NEW.test_type,
            'test_date', NEW.test_date,
            'result_numeric', NEW.result_numeric,
            'status', NEW.status
        ),
        CURRENT_TIMESTAMP
    );
END//

DROP TRIGGER IF EXISTS `trg_lab_test_audit_update`//
CREATE TRIGGER `trg_lab_test_audit_update`
AFTER UPDATE ON `lab_test`
FOR EACH ROW
BEGIN
    IF OLD.result_status != NEW.result_status OR OLD.result_numeric != NEW.result_numeric THEN
        INSERT INTO audit_log (
            table_name,
            record_id,
            action,
            details
        ) VALUES (
            'lab_test',
            CAST(NEW.lab_test_id AS CHAR),
            'UPDATE',
            CONCAT('Lab test updated: Status ', OLD.result_status, ' -> ', NEW.result_status, ', Result: ', COALESCE(NEW.result_numeric, 'N/A'))
        );
    END IF;
END//

-- ============================================================================
-- TRIGGER: Audit Log for Dispense Table
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_dispense_audit_insert`//
CREATE TRIGGER `trg_dispense_audit_insert`
AFTER INSERT ON `dispense`
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        details
    ) VALUES (
        'dispense',
        CAST(NEW.dispense_id AS CHAR),
        'INSERT',
        CONCAT('Dispense created: Patient ', NEW.patient_id, ', Days supply: ', NEW.days_supply)
    );
END//

-- ============================================================================
-- TRIGGER: Low Adherence Alert
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_adherence_low_alert`//
CREATE TRIGGER `trg_adherence_low_alert`
AFTER INSERT ON `adherence_log`
FOR EACH ROW
BEGIN
    IF NEW.adherence_percent < 85 AND NEW.method_used != 'Computed' THEN
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_level,
            alert_msg,
            is_resolved
        ) VALUES (
            NEW.patient_id,
            'Low Adherence',
            CASE 
                WHEN NEW.adherence_percent < 70 THEN 'Critical'
                WHEN NEW.adherence_percent < 80 THEN 'Warning'
                ELSE 'Info'
            END,
            CONCAT('Low adherence detected: ', NEW.adherence_percent, '%. Patient requires counseling.'),
            FALSE
        );
    END IF;
END//

DELIMITER ;

