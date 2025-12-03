-- ============================================================================
-- TRIGGERS
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

DELIMITER //

-- ============================================================================
-- TRIGGER: High Viral Load Alert on Lab Test Insert
-- ============================================================================

DROP TRIGGER IF EXISTS `trg_lab_test_high_vl_alert`//
CREATE TRIGGER `trg_lab_test_high_vl_alert`
AFTER INSERT ON `lab_test`
FOR EACH ROW
BEGIN
    IF NEW.test_type = 'Viral Load' 
       AND NEW.status = 'Completed' 
       AND NEW.result_numeric IS NOT NULL 
       AND NEW.result_numeric > 1000 THEN
        
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_message,
            severity,
            status,
            related_entity_type,
            related_entity_id
        ) VALUES (
            NEW.patient_id,
            'High Viral Load',
            CONCAT('High viral load detected: ', NEW.result_numeric, ' copies/mL. Action required.'),
            'Critical',
            'Active',
            'lab_test',
            NEW.lab_test_id
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
       AND NEW.status = 'Completed' 
       AND NEW.result_numeric IS NOT NULL 
       AND NEW.result_numeric > 1000 
       AND (OLD.result_numeric IS NULL OR OLD.result_numeric <= 1000) THEN
        
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_message,
            severity,
            status,
            related_entity_type,
            related_entity_id
        ) VALUES (
            NEW.patient_id,
            'High Viral Load',
            CONCAT('High viral load detected: ', NEW.result_numeric, ' copies/mL. Action required.'),
            'Critical',
            'Active',
            'lab_test',
            NEW.lab_test_id
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
            alert_message,
            severity,
            status,
            related_entity_type,
            related_entity_id
        ) VALUES (
            NEW.patient_id,
            'Missed Appointment',
            CONCAT('Patient missed appointment scheduled for ', 
                   DATE_FORMAT(NEW.appointment_date, '%Y-%m-%d')),
            'Medium',
            'Active',
            'appointment',
            NEW.appointment_id
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
        new_values,
        changed_at
    ) VALUES (
        'patient',
        NEW.patient_id,
        'INSERT',
        JSON_OBJECT(
            'patient_id', NEW.patient_id,
            'person_id', NEW.person_id,
            'patient_number', NEW.patient_number,
            'enrollment_date', NEW.enrollment_date,
            'art_start_date', NEW.art_start_date,
            'current_status', NEW.current_status
        ),
        CURRENT_TIMESTAMP
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
        old_values,
        new_values,
        changed_at
    ) VALUES (
        'patient',
        NEW.patient_id,
        'UPDATE',
        JSON_OBJECT(
            'patient_id', OLD.patient_id,
            'current_status', OLD.current_status,
            'art_start_date', OLD.art_start_date
        ),
        JSON_OBJECT(
            'patient_id', NEW.patient_id,
            'current_status', NEW.current_status,
            'art_start_date', NEW.art_start_date
        ),
        CURRENT_TIMESTAMP
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
        new_values,
        changed_at
    ) VALUES (
        'visit',
        NEW.visit_id,
        'INSERT',
        JSON_OBJECT(
            'visit_id', NEW.visit_id,
            'patient_id', NEW.patient_id,
            'visit_date', NEW.visit_date,
            'visit_type', NEW.visit_type,
            'staff_id', NEW.staff_id
        ),
        CURRENT_TIMESTAMP
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
    IF OLD.status != NEW.status OR OLD.result_numeric != NEW.result_numeric THEN
        INSERT INTO audit_log (
            table_name,
            record_id,
            action,
            old_values,
            new_values,
            changed_at
        ) VALUES (
            'lab_test',
            NEW.lab_test_id,
            'UPDATE',
            JSON_OBJECT(
                'status', OLD.status,
                'result_numeric', OLD.result_numeric
            ),
            JSON_OBJECT(
                'status', NEW.status,
                'result_numeric', NEW.result_numeric
            ),
            CURRENT_TIMESTAMP
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
        new_values,
        changed_at
    ) VALUES (
        'dispense',
        NEW.dispense_id,
        'INSERT',
        JSON_OBJECT(
            'dispense_id', NEW.dispense_id,
            'patient_id', NEW.patient_id,
            'regimen_id', NEW.regimen_id,
            'dispense_date', NEW.dispense_date,
            'days_supply', NEW.days_supply,
            'next_refill_date', NEW.next_refill_date
        ),
        CURRENT_TIMESTAMP
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
    IF NEW.adherence_percentage < 85 AND NEW.assessment_method != 'Computed' THEN
        INSERT INTO alert (
            patient_id,
            alert_type,
            alert_message,
            severity,
            status,
            related_entity_type,
            related_entity_id
        ) VALUES (
            NEW.patient_id,
            'Low Adherence',
            CONCAT('Low adherence detected: ', NEW.adherence_percentage, '%. Patient requires counseling.'),
            CASE 
                WHEN NEW.adherence_percentage < 70 THEN 'Critical'
                WHEN NEW.adherence_percentage < 80 THEN 'High'
                ELSE 'Medium'
            END,
            'Active',
            'adherence_log',
            NEW.adherence_id
        );
    END IF;
END//

DELIMITER ;

