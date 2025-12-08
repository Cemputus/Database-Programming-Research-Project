-- ============================================================================
-- VIEWS
-- HIV Patient Care & Treatment Monitoring System
-- ============================================================================

-- ============================================================================
-- VIEW: Active Patients Summary
-- Summary of active patients: last visit, last VL, last adherence, etc.
-- ============================================================================
USE hiv_patient_care; 


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
-- VIEW: CAG Summary
-- Summary of all CAGs with member counts and status
-- ============================================================================

CREATE OR REPLACE VIEW `v_cag_summary` AS
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
    COUNT(DISTINCT pc.patient_id) AS current_member_count,
    CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS coordinator_name,
    CONCAT(sper.first_name, ' ', COALESCE(sper.other_name, ''), ' ', sper.last_name) AS facility_staff_name,
    (SELECT COUNT(*) FROM cag_rotation cr WHERE cr.cag_id = c.cag_id) AS total_rotations,
    (SELECT MAX(rotation_date) FROM cag_rotation cr WHERE cr.cag_id = c.cag_id) AS last_rotation_date
FROM cag c
LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
LEFT JOIN patient p_coord ON c.coordinator_patient_id = p_coord.patient_id
LEFT JOIN person per ON p_coord.person_id = per.person_id
LEFT JOIN staff s ON c.facility_staff_id = s.staff_id
LEFT JOIN person sper ON s.person_id = sper.person_id
GROUP BY c.cag_id, c.cag_name, c.district, c.subcounty, c.parish, c.village, 
         c.formation_date, c.status, c.max_members, per.first_name, per.other_name, 
         per.last_name, sper.first_name, sper.other_name, sper.last_name;

-- ============================================================================
-- VIEW: CAG Members
-- All active CAG members with their details
-- ============================================================================

CREATE OR REPLACE VIEW `v_cag_members` AS
SELECT 
    pc.patient_cag_id,
    pc.cag_id,
    c.cag_name,
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
    (SELECT adherence_percent FROM adherence_log 
     WHERE patient_id = p.patient_id 
     ORDER BY log_date DESC LIMIT 1) AS last_adherence
FROM patient_cag pc
INNER JOIN cag c ON pc.cag_id = c.cag_id
INNER JOIN patient p ON pc.patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
WHERE pc.is_active = TRUE
ORDER BY c.cag_name, pc.role_in_cag DESC, pc.join_date;

-- ============================================================================
-- VIEW: CAG Rotation History
-- History of CAG rotations with pickup details
-- ============================================================================

CREATE OR REPLACE VIEW `v_cag_rotation_history` AS
SELECT 
    cr.rotation_id,
    cr.cag_id,
    c.cag_name,
    cr.rotation_date,
    cr.pickup_patient_id,
    p.patient_code AS pickup_patient_code,
    CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS pickup_patient_name,
    cr.patients_served,
    cr.dispense_id,
    d.dispense_date,
    d.regimen_id,
    r.regimen_name,
    cr.notes
FROM cag_rotation cr
INNER JOIN cag c ON cr.cag_id = c.cag_id
INNER JOIN patient p ON cr.pickup_patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
LEFT JOIN dispense d ON cr.dispense_id = d.dispense_id
LEFT JOIN regimen r ON d.regimen_id = r.regimen_id
ORDER BY cr.rotation_date DESC, c.cag_name;

-- ============================================================================
-- VIEW: CAG Performance
-- CAG performance metrics including adherence and viral load suppression
-- ============================================================================

CREATE OR REPLACE VIEW `v_cag_performance` AS
SELECT 
    c.cag_id,
    c.cag_name,
    c.district,
    c.subcounty,
    c.parish,
    c.village,
    c.formation_date,
    COUNT(DISTINCT pc.patient_id) AS active_members,
    AVG(ad.adherence_percent) AS avg_adherence,
    COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 95 THEN pc.patient_id END) AS excellent_adherence_count,
    COUNT(DISTINCT CASE WHEN lt.result_numeric < 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS suppressed_vl_count,
    COUNT(DISTINCT CASE WHEN lt.result_numeric >= 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS unsuppressed_vl_count,
    COUNT(DISTINCT cr.rotation_id) AS total_rotations,
    MAX(cr.rotation_date) AS last_rotation_date,
    MIN(cr.rotation_date) AS first_rotation_date
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
WHERE c.status = 'Active'
GROUP BY c.cag_id, c.cag_name, c.district, c.subcounty, c.parish, c.village, c.formation_date;

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
