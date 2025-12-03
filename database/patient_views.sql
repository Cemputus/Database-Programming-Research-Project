-- ============================================================================
-- PATIENT SELF-SERVICE VIEWS
-- Patients can query these views to see their own data
-- ============================================================================

-- ============================================================================
-- VIEW: Patient Dashboard
-- Complete patient overview: next appointment, last VL/CD4, current regimen, adherence
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_dashboard` AS
SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS patient_name,
    per.sex,
    TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) AS age,
    p.enrollment_date,
    p.art_start_date,
    DATEDIFF(CURDATE(), p.art_start_date) AS days_on_art,
    p.current_status,
    p.support_group,
    p.treatment_partner,
    p.next_of_kin,
    p.nok_phone,
    (SELECT scheduled_date 
     FROM appointment 
     WHERE patient_id = p.patient_id 
       AND status = 'Scheduled' 
       AND scheduled_date >= CURDATE()
     ORDER BY scheduled_date ASC 
     LIMIT 1) AS next_appointment_date,
    (SELECT DATEDIFF(
        (SELECT scheduled_date 
         FROM appointment 
         WHERE patient_id = p.patient_id 
           AND status = 'Scheduled' 
           AND scheduled_date >= CURDATE()
         ORDER BY scheduled_date ASC 
         LIMIT 1), 
        CURDATE()
     )) AS days_until_next_appointment,
    (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id) AS last_visit_date,
    (SELECT DATEDIFF(CURDATE(), MAX(visit_date)) FROM visit WHERE patient_id = p.patient_id) AS days_since_last_visit,
    (SELECT MAX(test_date) 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed') AS last_vl_date,
    (SELECT result_numeric 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed'
     ORDER BY test_date DESC LIMIT 1) AS last_vl_result,
    (SELECT CASE 
        WHEN result_numeric > 1000 THEN 'High - Action Required'
        WHEN result_numeric > 0 AND result_numeric <= 1000 THEN 'Suppressed - Good'
        WHEN result_numeric = 0 THEN 'Undetectable - Excellent'
        ELSE 'No Result'
     END
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed'
     ORDER BY test_date DESC LIMIT 1) AS vl_status,
    (SELECT MAX(test_date) 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'CD4' 
       AND result_status = 'Completed') AS last_cd4_date,
    (SELECT result_numeric 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'CD4' 
       AND result_status = 'Completed'
     ORDER BY test_date DESC LIMIT 1) AS last_cd4_result,
    (SELECT r.regimen_name 
     FROM dispense d
     INNER JOIN regimen r ON d.regimen_id = r.regimen_id
     WHERE d.patient_id = p.patient_id
     ORDER BY d.dispense_date DESC
     LIMIT 1) AS current_regimen,
    (SELECT MAX(next_refill_date) 
     FROM dispense 
     WHERE patient_id = p.patient_id) AS next_refill_date,
    (SELECT DATEDIFF(MAX(next_refill_date), CURDATE()) 
     FROM dispense 
     WHERE patient_id = p.patient_id) AS days_until_refill,
    (SELECT adherence_percent 
     FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS last_adherence_percent,
    (SELECT method_used 
     FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS last_adherence_method,
    (SELECT log_date 
     FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS last_adherence_date,
    (SELECT CASE 
        WHEN adherence_percent >= 95 THEN 'Excellent'
        WHEN adherence_percent >= 85 THEN 'Good'
        WHEN adherence_percent >= 70 THEN 'Fair'
        ELSE 'Needs Improvement'
     END
     FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS adherence_category,
    (SELECT COUNT(*) 
     FROM alert 
     WHERE patient_id = p.patient_id 
       AND is_resolved = FALSE) AS active_alerts_count
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
WHERE p.current_status = 'Active';

-- ============================================================================
-- VIEW: Patient Visit History
-- All clinical visits with vital signs, symptoms, and clinician information
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_visit_history` AS
SELECT 
    v.visit_id,
    v.patient_id,
    v.visit_date,
    v.who_stage,
    v.weight_kg,
    v.bp,
    v.tb_screening,
    v.symptoms,
    v.oi_diagnosis,
    v.next_appointment_date,
    CONCAT(per.first_name, ' ', per.last_name) AS clinician_name,
    s.cadre AS clinician_cadre
FROM visit v
INNER JOIN staff s ON v.staff_id = s.staff_id
INNER JOIN person per ON s.person_id = per.person_id
ORDER BY v.visit_date DESC;

-- ============================================================================
-- VIEW: Patient Lab Test History
-- All lab test results with status descriptions (High/Suppressed for VL, Low/Normal for CD4)
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_lab_history` AS
SELECT 
    lt.lab_test_id,
    lt.patient_id,
    lt.test_type,
    lt.test_date,
    lt.result_numeric,
    lt.result_text,
    lt.units,
    lt.cphl_sample_id,
    lt.result_status,
    CASE 
        WHEN lt.test_type = 'Viral Load' AND lt.result_numeric > 1000 THEN 'High'
        WHEN lt.test_type = 'Viral Load' AND lt.result_numeric > 0 AND lt.result_numeric <= 1000 THEN 'Suppressed'
        WHEN lt.test_type = 'Viral Load' AND lt.result_numeric = 0 THEN 'Undetectable'
        WHEN lt.test_type = 'CD4' AND lt.result_numeric < 200 THEN 'Low'
        WHEN lt.test_type = 'CD4' AND lt.result_numeric >= 200 AND lt.result_numeric < 500 THEN 'Moderate'
        WHEN lt.test_type = 'CD4' AND lt.result_numeric >= 500 THEN 'Normal'
        ELSE 'Normal'
    END AS result_status_description
FROM lab_test lt
ORDER BY lt.test_date DESC, lt.test_type;

-- ============================================================================
-- VIEW: Patient Medication History
-- All medication dispenses with refill status (Overdue/Due Soon/On Track)
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_medication_history` AS
SELECT 
    d.dispense_id,
    d.patient_id,
    d.dispense_date,
    r.regimen_name,
    r.line AS regimen_line,
    d.days_supply,
    d.quantity_dispensed,
    d.next_refill_date,
    DATEDIFF(d.next_refill_date, CURDATE()) AS days_until_refill,
    CASE 
        WHEN d.next_refill_date < CURDATE() THEN 'Overdue'
        WHEN DATEDIFF(d.next_refill_date, CURDATE()) <= 7 THEN 'Due Soon'
        ELSE 'On Track'
    END AS refill_status,
    d.notes
FROM dispense d
INNER JOIN regimen r ON d.regimen_id = r.regimen_id
ORDER BY d.dispense_date DESC;

-- ============================================================================
-- VIEW: Patient Appointment Schedule
-- All appointments with status descriptions and days until appointment
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_appointments` AS
SELECT 
    a.appointment_id,
    a.patient_id,
    a.scheduled_date,
    a.status,
    a.reason,
    DATEDIFF(a.scheduled_date, CURDATE()) AS days_until_appointment,
    CASE 
        WHEN a.status = 'Scheduled' AND a.scheduled_date < CURDATE() THEN 'Overdue'
        WHEN a.status = 'Scheduled' AND DATEDIFF(a.scheduled_date, CURDATE()) <= 3 THEN 'Upcoming'
        WHEN a.status = 'Scheduled' THEN 'Scheduled'
        WHEN a.status = 'Attended' THEN 'Completed'
        WHEN a.status = 'Missed' THEN 'Missed'
        ELSE a.status
    END AS appointment_status,
    CONCAT(per.first_name, ' ', per.last_name) AS scheduled_by_name
FROM appointment a
LEFT JOIN staff s ON a.staff_id = s.staff_id
LEFT JOIN person per ON s.person_id = per.person_id
ORDER BY a.scheduled_date DESC;

-- ============================================================================
-- VIEW: Patient Adherence History
-- All adherence assessments with categories (Excellent/Good/Fair/Needs Improvement)
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_adherence_history` AS
SELECT 
    al.adherence_id,
    al.patient_id,
    al.log_date,
    al.adherence_percent,
    al.method_used,
    CASE 
        WHEN al.adherence_percent >= 95 THEN 'Excellent'
        WHEN al.adherence_percent >= 85 THEN 'Good'
        WHEN al.adherence_percent >= 70 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS adherence_category,
    DATEDIFF(CURDATE(), al.log_date) AS days_since_assessment,
    al.notes
FROM adherence_log al
ORDER BY al.log_date DESC;

-- ============================================================================
-- VIEW: Patient Alerts & Notifications
-- All patient alerts sorted by priority (Critical > Warning > Info)
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_alerts` AS
SELECT 
    a.alert_id,
    a.patient_id,
    a.alert_type,
    a.alert_level,
    a.alert_msg,
    a.triggered_at,
    a.is_resolved,
    a.resolved_at,
    DATEDIFF(CURDATE(), DATE(a.triggered_at)) AS days_since_alert,
    CASE 
        WHEN a.alert_level = 'Critical' THEN 1
        WHEN a.alert_level = 'Warning' THEN 2
        WHEN a.alert_level = 'Info' THEN 3
        ELSE 4
    END AS priority_order
FROM alert a
ORDER BY 
    CASE 
        WHEN a.alert_level = 'Critical' THEN 1
        WHEN a.alert_level = 'Warning' THEN 2
        WHEN a.alert_level = 'Info' THEN 3
        ELSE 4
    END,
    a.triggered_at DESC;

-- ============================================================================
-- VIEW: Patient Progress Summary (Timeline View)
-- Chronological timeline: enrollment, ART start, visits, lab tests, medications, adherence
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_progress_timeline` AS
SELECT 
    p.patient_id,
    'Enrollment' AS event_type,
    p.enrollment_date AS event_date,
    CONCAT('Enrolled in ART program') AS event_description,
    NULL AS event_value,
    NULL AS event_unit
FROM patient p
UNION ALL
SELECT 
    p.patient_id,
    'ART Start' AS event_type,
    p.art_start_date AS event_date,
    CONCAT('Started ART treatment') AS event_description,
    NULL AS event_value,
    NULL AS event_unit
FROM patient p
WHERE p.art_start_date IS NOT NULL
UNION ALL
SELECT 
    v.patient_id,
    'Visit' AS event_type,
    v.visit_date AS event_date,
    CONCAT('Clinical visit - WHO Stage ', v.who_stage) AS event_description,
    v.weight_kg AS event_value,
    'kg' AS event_unit
FROM visit v
UNION ALL
SELECT 
    lt.patient_id,
    CONCAT('Lab Test - ', lt.test_type) AS event_type,
    lt.test_date AS event_date,
    CONCAT(lt.test_type, ' test completed') AS event_description,
    lt.result_numeric AS event_value,
    lt.units AS event_unit
FROM lab_test lt
WHERE lt.result_status = 'Completed'
UNION ALL
SELECT 
    d.patient_id,
    'Medication' AS event_type,
    d.dispense_date AS event_date,
    CONCAT('Medication dispensed: ', r.regimen_name) AS event_description,
    d.days_supply AS event_value,
    'days' AS event_unit
FROM dispense d
INNER JOIN regimen r ON d.regimen_id = r.regimen_id
UNION ALL
SELECT 
    al.patient_id,
    'Adherence' AS event_type,
    al.log_date AS event_date,
    CONCAT('Adherence assessment: ', al.method_used) AS event_description,
    al.adherence_percent AS event_value,
    '%' AS event_unit
FROM adherence_log al
ORDER BY patient_id, event_date DESC;

