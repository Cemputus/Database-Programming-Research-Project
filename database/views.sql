-- ============================================================================
-- VIEWS
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

-- ============================================================================
-- VIEW: Active Patients Summary
-- Summary of active patients: last visit, last VL, last adherence, etc.
-- ============================================================================

CREATE OR REPLACE VIEW `v_active_patients_summary` AS
SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS full_name,
    per.date_of_birth,
    TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) AS age,
    per.sex,
    p.enrollment_date,
    p.art_start_date,
    DATEDIFF(CURDATE(), p.art_start_date) AS days_on_art,
    p.current_status,
    p.support_group,
    p.treatment_partner,
    (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id) AS last_visit_date,
    (SELECT MAX(dispense_date) FROM dispense WHERE patient_id = p.patient_id) AS last_dispense_date,
    (SELECT MAX(test_date) FROM lab_test WHERE patient_id = p.patient_id AND test_type = 'Viral Load' AND result_status = 'Completed') AS last_vl_date,
    (SELECT result_numeric FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed'
     ORDER BY test_date DESC LIMIT 1) AS last_vl_result,
    (SELECT adherence_percent FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS last_adherence
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
WHERE p.current_status = 'Active';

-- ============================================================================
-- VIEW: Patient Care Timeline
-- Chronological timeline of all patient events (enrollment, visits, tests, dispenses)
-- ============================================================================

CREATE OR REPLACE VIEW `v_patient_care_timeline` AS
SELECT 
    p.patient_id,
    p.patient_code,
    'Enrollment' AS event_type,
    p.enrollment_date AS event_date,
    CONCAT('Patient enrolled') AS event_description,
    NULL AS staff_name
FROM patient p
UNION ALL
SELECT 
    p.patient_id,
    p.patient_code,
    'ART Start' AS event_type,
    p.art_start_date AS event_date,
    CONCAT('ART initiated') AS event_description,
    NULL AS staff_name
FROM patient p
WHERE p.art_start_date IS NOT NULL
UNION ALL
SELECT 
    v.patient_id,
    p.patient_code,
    'Visit' AS event_type,
    v.visit_date AS event_date,
    CONCAT('Clinical visit') AS event_description,
    CONCAT(per.first_name, ' ', per.last_name) AS staff_name
FROM visit v
INNER JOIN patient p ON v.patient_id = p.patient_id
INNER JOIN staff s ON v.staff_id = s.staff_id
INNER JOIN person per ON s.person_id = per.person_id
UNION ALL
SELECT 
    lt.patient_id,
    p.patient_code,
    'Lab Test' AS event_type,
    lt.test_date AS event_date,
    CONCAT(lt.test_type, ' - ', COALESCE(lt.result_text, CAST(lt.result_numeric AS CHAR), 'Pending')) AS event_description,
    NULL AS staff_name
FROM lab_test lt
INNER JOIN patient p ON lt.patient_id = p.patient_id
UNION ALL
SELECT 
    d.patient_id,
    p.patient_code,
    'Dispense' AS event_type,
    d.dispense_date AS event_date,
    CONCAT('Medication dispensed - ', r.regimen_name, ' (', d.days_supply, ' days)') AS event_description,
    CONCAT(per.first_name, ' ', per.last_name) AS staff_name
FROM dispense d
INNER JOIN patient p ON d.patient_id = p.patient_id
INNER JOIN regimen r ON d.regimen_id = r.regimen_id
INNER JOIN staff s ON d.staff_id = s.staff_id
INNER JOIN person per ON s.person_id = per.person_id
ORDER BY patient_id, event_date DESC;

-- ============================================================================
-- VIEW: Active Alerts Summary
-- All unresolved alerts sorted by severity (Critical > Warning > Info)
-- ============================================================================

CREATE OR REPLACE VIEW `v_active_alerts_summary` AS
SELECT 
    a.alert_id,
    a.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    a.alert_type,
    a.alert_msg,
    a.alert_level,
    a.is_resolved,
    a.triggered_at,
    DATEDIFF(CURDATE(), DATE(a.triggered_at)) AS days_since_alert,
    a.resolved_at
FROM alert a
INNER JOIN patient p ON a.patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
WHERE a.is_resolved = FALSE
ORDER BY 
    CASE a.alert_level
        WHEN 'Critical' THEN 1
        WHEN 'Warning' THEN 2
        WHEN 'Info' THEN 3
    END,
    a.triggered_at DESC;

-- ============================================================================
-- VIEW: Viral Load Monitoring
-- VL status for active patients: last test date, result, status (High/Suppressed/Unknown)
-- Test status: Overdue (>180 days), Due Soon (>120 days), Current
-- ============================================================================

CREATE OR REPLACE VIEW `v_viral_load_monitoring` AS
SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    p.art_start_date,
    (SELECT MAX(test_date) 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed') AS last_vl_date,
    DATEDIFF(CURDATE(), (SELECT MAX(test_date) 
                         FROM lab_test 
                         WHERE patient_id = p.patient_id 
                           AND test_type = 'Viral Load' 
                           AND result_status = 'Completed')) AS days_since_last_vl,
    (SELECT result_numeric 
     FROM lab_test 
     WHERE patient_id = p.patient_id 
       AND test_type = 'Viral Load' 
       AND result_status = 'Completed'
     ORDER BY test_date DESC LIMIT 1) AS last_vl_result,
    CASE 
        WHEN (SELECT result_numeric 
              FROM lab_test 
              WHERE patient_id = p.patient_id 
                AND test_type = 'Viral Load' 
                AND result_status = 'Completed'
              ORDER BY test_date DESC LIMIT 1) > 1000 THEN 'High'
        WHEN (SELECT result_numeric 
              FROM lab_test 
              WHERE patient_id = p.patient_id 
                AND test_type = 'Viral Load' 
                AND result_status = 'Completed'
              ORDER BY test_date DESC LIMIT 1) <= 1000 
             AND (SELECT result_numeric 
                  FROM lab_test 
                  WHERE patient_id = p.patient_id 
                    AND test_type = 'Viral Load' 
                    AND result_status = 'Completed'
                  ORDER BY test_date DESC LIMIT 1) > 0 THEN 'Suppressed'
        ELSE 'Unknown'
    END AS vl_status,
    CASE 
        WHEN DATEDIFF(CURDATE(), (SELECT MAX(test_date) 
                                   FROM lab_test 
                                   WHERE patient_id = p.patient_id 
                                     AND test_type = 'Viral Load' 
                                     AND result_status = 'Completed')) > 180 THEN 'Overdue'
        WHEN DATEDIFF(CURDATE(), (SELECT MAX(test_date) 
                                   FROM lab_test 
                                   WHERE patient_id = p.patient_id 
                                     AND test_type = 'Viral Load' 
                                     AND result_status = 'Completed')) > 120 THEN 'Due Soon'
        ELSE 'Current'
    END AS vl_test_status
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
WHERE p.current_status = 'Active'
  AND p.art_start_date IS NOT NULL;

-- ============================================================================
-- VIEW: Adherence Summary
-- Latest adherence assessment for each active patient with category
-- Categories: Excellent (≥95%), Good (≥85%), Fair (≥70%), Poor (<70%)
-- ============================================================================

CREATE OR REPLACE VIEW `v_adherence_summary` AS
SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    al.log_date AS last_assessment_date,
    al.adherence_percent,
    al.method_used,
    CASE 
        WHEN al.adherence_percent >= 95 THEN 'Excellent'
        WHEN al.adherence_percent >= 85 THEN 'Good'
        WHEN al.adherence_percent >= 70 THEN 'Fair'
        ELSE 'Poor'
    END AS adherence_category,
    DATEDIFF(CURDATE(), al.log_date) AS days_since_assessment
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
LEFT JOIN (
    SELECT 
        patient_id,
        log_date,
        adherence_percent,
        method_used,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY log_date DESC) AS rn
    FROM adherence_log
) al ON p.patient_id = al.patient_id AND al.rn = 1
WHERE p.current_status = 'Active';

-- ============================================================================
-- VIEW: Staff with Roles
-- Staff information with all assigned system roles (overlapping specialization)
-- ============================================================================

CREATE OR REPLACE VIEW `v_staff_with_roles` AS
SELECT 
    s.staff_id,
    s.staff_code,
    CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS full_name,
    per.phone_contact,
    s.cadre,
    s.moH_registration_no,
    s.hire_date,
    s.active,
    GROUP_CONCAT(r.role_name ORDER BY r.role_name SEPARATOR ', ') AS roles
FROM staff s
INNER JOIN person per ON s.person_id = per.person_id
LEFT JOIN staff_role sr ON s.staff_id = sr.staff_id
LEFT JOIN role r ON sr.role_id = r.role_id
GROUP BY s.staff_id, s.staff_code, per.first_name, per.other_name, per.last_name, 
         per.phone_contact, s.cadre, s.moH_registration_no, s.hire_date, s.active;
