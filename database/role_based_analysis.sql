-- ============================================================================
-- ROLE-BASED ANALYSIS QUERIES
-- HIV Patient Care & Treatment Monitoring System
-- Mukono General Hospital ART Clinic
-- ============================================================================
-- This file contains comprehensive analysis queries organized by user role
-- Each role has access to specific analyses relevant to their responsibilities
-- ============================================================================

USE hiv_patient_care;

-- ============================================================================
-- SECTION 1: ADMINISTRATOR (db_admin) - FULL SYSTEM ANALYSIS
-- ============================================================================

-- 1.1 System Overview Dashboard
SELECT '=== ADMIN: SYSTEM OVERVIEW ===' AS section;

SELECT 
    'Total Patients' AS metric,
    COUNT(*) AS value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient), 2), '%') AS percentage
FROM patient
WHERE current_status = 'Active'

UNION ALL

SELECT 
    'Patients on ART' AS metric,
    COUNT(*) AS value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient WHERE current_status = 'Active'), 2), '%') AS percentage
FROM patient
WHERE current_status = 'Active'
  AND art_start_date IS NOT NULL

UNION ALL

SELECT 
    'Total Staff' AS metric,
    COUNT(*) AS value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staff), 2), '%') AS percentage
FROM staff
WHERE active = TRUE

UNION ALL

SELECT 
    'Active CAGs' AS metric,
    COUNT(*) AS value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cag), 2), '%') AS percentage
FROM cag
WHERE status = 'Active';

-- 1.2 Patient Status Distribution
SELECT '=== ADMIN: PATIENT STATUS DISTRIBUTION ===' AS section;

SELECT 
    current_status AS status,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient), 2) AS percentage
FROM patient
GROUP BY current_status
ORDER BY patient_count DESC;

-- 1.3 Staff Distribution by Cadre
SELECT '=== ADMIN: STAFF BY CADRE ===' AS section;

SELECT 
    cadre,
    COUNT(*) AS staff_count,
    SUM(CASE WHEN active = TRUE THEN 1 ELSE 0 END) AS active_count,
    SUM(CASE WHEN active = FALSE THEN 1 ELSE 0 END) AS inactive_count
FROM staff
GROUP BY cadre
ORDER BY staff_count DESC;

-- 1.4 District-wise Patient Distribution
SELECT '=== ADMIN: PATIENTS BY DISTRICT ===' AS section;

SELECT 
    per.district,
    COUNT(DISTINCT p.patient_id) AS patient_count,
    SUM(CASE WHEN p.current_status = 'Active' THEN 1 ELSE 0 END) AS active_patients,
    SUM(CASE WHEN p.current_status = 'LTFU' THEN 1 ELSE 0 END) AS ltfu_patients,
    SUM(CASE WHEN p.current_status = 'Transferred-Out' THEN 1 ELSE 0 END) AS transferred_patients,
    SUM(CASE WHEN p.current_status = 'Dead' THEN 1 ELSE 0 END) AS deceased_patients
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
GROUP BY per.district
ORDER BY patient_count DESC;

-- 1.5 Monthly Enrollment Trends
SELECT '=== ADMIN: MONTHLY ENROLLMENT TRENDS ===' AS section;

SELECT 
    DATE_FORMAT(enrollment_date, '%Y-%m') AS enrollment_month,
    COUNT(*) AS new_patients
FROM patient
WHERE enrollment_date >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
GROUP BY DATE_FORMAT(enrollment_date, '%Y-%m')
ORDER BY enrollment_month DESC;

-- 1.6 System Activity Summary (Last 30 Days)
SELECT '=== ADMIN: SYSTEM ACTIVITY (LAST 30 DAYS) ===' AS section;

SELECT 
    'Visits' AS activity_type,
    COUNT(*) AS count
FROM visit
WHERE visit_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Lab Tests' AS activity_type,
    COUNT(*) AS count
FROM lab_test
WHERE test_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Dispenses' AS activity_type,
    COUNT(*) AS count
FROM dispense
WHERE dispense_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Appointments' AS activity_type,
    COUNT(*) AS count
FROM appointment
WHERE scheduled_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Counseling Sessions' AS activity_type,
    COUNT(*) AS count
FROM counseling_session
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- SECTION 2: CLINICIAN (db_clinician) - CLINICAL ANALYSIS
-- ============================================================================

-- 2.1 Active Patients Requiring Attention
SELECT '=== CLINICIAN: PATIENTS REQUIRING ATTENTION ===' AS section;

SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    p.current_status,
    (SELECT COUNT(*) FROM alert WHERE patient_id = p.patient_id AND is_resolved = FALSE) AS active_alerts,
    (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id) AS last_visit_date,
    DATEDIFF(CURDATE(), (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id)) AS days_since_last_visit
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
WHERE p.current_status = 'Active'
  AND (
    (SELECT COUNT(*) FROM alert WHERE patient_id = p.patient_id AND is_resolved = FALSE) > 0
    OR DATEDIFF(CURDATE(), (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id)) > 90
  )
ORDER BY active_alerts DESC, days_since_last_visit DESC
LIMIT 50;

-- 2.2 Viral Load Suppression Rate
SELECT '=== CLINICIAN: VIRAL LOAD SUPPRESSION RATE ===' AS section;

SELECT 
    'Overall Suppression Rate' AS metric,
    CONCAT(
        ROUND(
            SUM(CASE WHEN lt.result_numeric < 1000 THEN 1 ELSE 0 END) * 100.0 / 
            COUNT(*), 
            2
        ), 
        '%'
    ) AS suppression_rate,
    SUM(CASE WHEN lt.result_numeric < 1000 THEN 1 ELSE 0 END) AS suppressed_count,
    COUNT(*) AS total_tests
FROM lab_test lt
WHERE lt.test_type = 'Viral Load'
  AND lt.result_status = 'Completed'
  AND lt.result_numeric IS NOT NULL
  AND lt.test_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

-- 2.3 Viral Load Suppression by District
SELECT '=== CLINICIAN: VL SUPPRESSION BY DISTRICT ===' AS section;

SELECT 
    per.district,
    COUNT(*) AS total_vl_tests,
    SUM(CASE WHEN lt.result_numeric < 1000 THEN 1 ELSE 0 END) AS suppressed,
    SUM(CASE WHEN lt.result_numeric >= 1000 THEN 1 ELSE 0 END) AS unsuppressed,
    ROUND(
        SUM(CASE WHEN lt.result_numeric < 1000 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS suppression_rate
FROM lab_test lt
INNER JOIN patient p ON lt.patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
WHERE lt.test_type = 'Viral Load'
  AND lt.result_status = 'Completed'
  AND lt.result_numeric IS NOT NULL
  AND lt.test_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY per.district
ORDER BY suppression_rate DESC;

-- 2.4 High Viral Load Patients (Requiring Action)
SELECT '=== CLINICIAN: HIGH VIRAL LOAD PATIENTS ===' AS section;

SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    lt.test_date AS last_vl_date,
    lt.result_numeric AS viral_load,
    DATEDIFF(CURDATE(), lt.test_date) AS days_since_test,
    (SELECT COUNT(*) FROM alert WHERE patient_id = p.patient_id AND alert_type = 'High Viral Load' AND is_resolved = FALSE) AS active_alerts
FROM lab_test lt
INNER JOIN patient p ON lt.patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
WHERE lt.test_type = 'Viral Load'
  AND lt.result_status = 'Completed'
  AND lt.result_numeric > 1000
  AND lt.test_date = (
    SELECT MAX(lt2.test_date)
    FROM lab_test lt2
    WHERE lt2.patient_id = p.patient_id
      AND lt2.test_type = 'Viral Load'
      AND lt2.result_status = 'Completed'
  )
  AND p.current_status = 'Active'
ORDER BY lt.result_numeric DESC, lt.test_date DESC
LIMIT 50;

-- 2.5 Patient Visit Frequency Analysis
SELECT '=== CLINICIAN: VISIT FREQUENCY ANALYSIS ===' AS section;

SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    COUNT(v.visit_id) AS total_visits,
    MIN(v.visit_date) AS first_visit,
    MAX(v.visit_date) AS last_visit,
    DATEDIFF(MAX(v.visit_date), MIN(v.visit_date)) AS days_between_first_last,
    CASE 
        WHEN DATEDIFF(MAX(v.visit_date), MIN(v.visit_date)) > 0 
        THEN ROUND(COUNT(v.visit_id) * 365.0 / DATEDIFF(MAX(v.visit_date), MIN(v.visit_date)), 2)
        ELSE NULL
    END AS visits_per_year
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
LEFT JOIN visit v ON p.patient_id = v.patient_id
WHERE p.current_status = 'Active'
GROUP BY p.patient_id, p.patient_code, per.first_name, per.last_name
HAVING total_visits > 0
ORDER BY visits_per_year DESC
LIMIT 30;

-- 2.6 Missed Appointments Analysis
SELECT '=== CLINICIAN: MISSED APPOINTMENTS ANALYSIS ===' AS section;

SELECT 
    DATE_FORMAT(scheduled_date, '%Y-%m') AS month,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN status = 'Attended' THEN 1 ELSE 0 END) AS attended,
    SUM(CASE WHEN status = 'Missed' THEN 1 ELSE 0 END) AS missed,
    SUM(CASE WHEN status = 'Scheduled' THEN 1 ELSE 0 END) AS scheduled,
    ROUND(
        SUM(CASE WHEN status = 'Attended' THEN 1 ELSE 0 END) * 100.0 / 
        SUM(CASE WHEN status IN ('Attended', 'Missed') THEN 1 ELSE 0 END), 
        2
    ) AS attendance_rate
FROM appointment
WHERE scheduled_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(scheduled_date, '%Y-%m')
ORDER BY month DESC;

-- 2.7 Patient Outcomes by Enrollment Year
SELECT '=== CLINICIAN: PATIENT OUTCOMES BY ENROLLMENT YEAR ===' AS section;

SELECT 
    YEAR(enrollment_date) AS enrollment_year,
    COUNT(*) AS total_enrolled,
    SUM(CASE WHEN current_status = 'Active' THEN 1 ELSE 0 END) AS currently_active,
    SUM(CASE WHEN current_status = 'LTFU' THEN 1 ELSE 0 END) AS ltfu,
    SUM(CASE WHEN current_status = 'Transferred-Out' THEN 1 ELSE 0 END) AS transferred,
    SUM(CASE WHEN current_status = 'Dead' THEN 1 ELSE 0 END) AS deceased,
    ROUND(
        SUM(CASE WHEN current_status = 'Active' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS retention_rate
FROM patient
WHERE enrollment_date >= '2020-01-01'
GROUP BY YEAR(enrollment_date)
ORDER BY enrollment_year DESC;

-- ============================================================================
-- SECTION 3: LAB TECHNICIAN (db_lab) - LABORATORY ANALYSIS
-- ============================================================================

-- 3.1 Lab Test Volume by Type
SELECT '=== LAB: TEST VOLUME BY TYPE ===' AS section;

SELECT 
    test_type,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN result_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN result_status = 'Pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN result_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected,
    ROUND(
        SUM(CASE WHEN result_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS completion_rate
FROM lab_test
WHERE test_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY test_type
ORDER BY total_tests DESC;

-- 3.2 Viral Load Test Statistics
SELECT '=== LAB: VIRAL LOAD TEST STATISTICS ===' AS section;

SELECT 
    DATE_FORMAT(test_date, '%Y-%m') AS test_month,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN result_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    AVG(CASE WHEN result_status = 'Completed' AND result_numeric IS NOT NULL THEN result_numeric ELSE NULL END) AS avg_viral_load,
    MIN(CASE WHEN result_status = 'Completed' AND result_numeric IS NOT NULL THEN result_numeric ELSE NULL END) AS min_viral_load,
    MAX(CASE WHEN result_status = 'Completed' AND result_numeric IS NOT NULL THEN result_numeric ELSE NULL END) AS max_viral_load,
    SUM(CASE WHEN result_status = 'Completed' AND result_numeric < 1000 THEN 1 ELSE 0 END) AS suppressed_count
FROM lab_test
WHERE test_type = 'Viral Load'
  AND test_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(test_date, '%Y-%m')
ORDER BY test_month DESC;

-- 3.3 Pending Lab Tests
SELECT '=== LAB: PENDING LAB TESTS ===' AS section;

SELECT 
    lt.lab_test_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    lt.test_type,
    lt.test_date,
    DATEDIFF(CURDATE(), lt.test_date) AS days_pending,
    lt.result_status,
    s.staff_code AS ordered_by
FROM lab_test lt
INNER JOIN patient p ON lt.patient_id = p.patient_id
INNER JOIN person per ON p.person_id = per.person_id
INNER JOIN staff s ON lt.staff_id = s.staff_id
WHERE lt.result_status = 'Pending'
ORDER BY days_pending DESC, lt.test_date DESC
LIMIT 50;

-- 3.4 Rejected Lab Tests Analysis
SELECT '=== LAB: REJECTED LAB TESTS ANALYSIS ===' AS section;

SELECT 
    test_type,
    COUNT(*) AS rejected_count,
    DATE_FORMAT(test_date, '%Y-%m') AS test_month
FROM lab_test
WHERE result_status = 'Rejected'
  AND test_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY test_type, DATE_FORMAT(test_date, '%Y-%m')
ORDER BY test_month DESC, rejected_count DESC;

-- 3.5 CPHL Sample ID Tracking
SELECT '=== LAB: CPHL SAMPLE ID TRACKING ===' AS section;

SELECT 
    COUNT(*) AS total_vl_tests_with_cphl_id,
    COUNT(DISTINCT cphl_sample_id) AS unique_cphl_ids,
    SUM(CASE WHEN result_status = 'Completed' THEN 1 ELSE 0 END) AS completed_with_id,
    SUM(CASE WHEN cphl_sample_id IS NULL THEN 1 ELSE 0 END) AS missing_cphl_id
FROM lab_test
WHERE test_type = 'Viral Load'
  AND test_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

-- ============================================================================
-- SECTION 4: PHARMACY (db_pharmacy) - DISPENSING ANALYSIS
-- ============================================================================

-- 4.1 Dispensing Volume Trends
SELECT '=== PHARMACY: DISPENSING VOLUME TRENDS ===' AS section;

SELECT 
    DATE_FORMAT(dispense_date, '%Y-%m') AS dispense_month,
    COUNT(*) AS total_dispenses,
    SUM(quantity_dispensed) AS total_quantity,
    AVG(days_supply) AS avg_days_supply,
    COUNT(DISTINCT patient_id) AS unique_patients
FROM dispense
WHERE dispense_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(dispense_date, '%Y-%m')
ORDER BY dispense_month DESC;

-- 4.2 Regimen Distribution
SELECT '=== PHARMACY: REGIMEN DISTRIBUTION ===' AS section;

SELECT 
    r.regimen_name,
    r.line,
    COUNT(d.dispense_id) AS dispense_count,
    COUNT(DISTINCT d.patient_id) AS unique_patients,
    ROUND(COUNT(d.dispense_id) * 100.0 / (SELECT COUNT(*) FROM dispense), 2) AS percentage
FROM dispense d
INNER JOIN regimen r ON d.regimen_id = r.regimen_id
WHERE d.dispense_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY r.regimen_id, r.regimen_name, r.line
ORDER BY dispense_count DESC;

-- 4.3 Overdue Refills
SELECT '=== PHARMACY: OVERDUE REFILLS ===' AS section;

SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    MAX(d.next_refill_date) AS last_refill_date,
    DATEDIFF(CURDATE(), MAX(d.next_refill_date)) AS days_overdue,
    MAX(d.regimen_id) AS last_regimen_id,
    (SELECT regimen_name FROM regimen WHERE regimen_id = MAX(d.regimen_id)) AS last_regimen
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
INNER JOIN dispense d ON p.patient_id = d.patient_id
WHERE p.current_status = 'Active'
  AND d.next_refill_date < CURDATE()
GROUP BY p.patient_id, p.patient_code, per.first_name, per.last_name
HAVING days_overdue > 0
ORDER BY days_overdue DESC
LIMIT 50;

-- 4.4 Days Supply Analysis
SELECT '=== PHARMACY: DAYS SUPPLY ANALYSIS ===' AS section;

SELECT 
    CASE 
        WHEN days_supply <= 30 THEN '1-30 days'
        WHEN days_supply <= 60 THEN '31-60 days'
        WHEN days_supply <= 90 THEN '61-90 days'
        WHEN days_supply <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END AS supply_range,
    COUNT(*) AS dispense_count,
    COUNT(DISTINCT patient_id) AS unique_patients,
    AVG(days_supply) AS avg_days_supply
FROM dispense
WHERE dispense_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY 
    CASE 
        WHEN days_supply <= 30 THEN '1-30 days'
        WHEN days_supply <= 60 THEN '31-60 days'
        WHEN days_supply <= 90 THEN '61-90 days'
        WHEN days_supply <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END
ORDER BY MIN(days_supply);

-- 4.5 CAG Rotation Analysis
SELECT '=== PHARMACY: CAG ROTATION ANALYSIS ===' AS section;

SELECT 
    c.cag_name,
    c.district,
    c.village,
    COUNT(cr.rotation_id) AS total_rotations,
    COUNT(DISTINCT cr.pickup_patient_id) AS unique_pickup_patients,
    AVG(cr.patients_served) AS avg_patients_served,
    MAX(cr.rotation_date) AS last_rotation_date,
    DATEDIFF(CURDATE(), MAX(cr.rotation_date)) AS days_since_last_rotation
FROM cag c
LEFT JOIN cag_rotation cr ON c.cag_id = cr.cag_id
WHERE c.status = 'Active'
GROUP BY c.cag_id, c.cag_name, c.district, c.village
ORDER BY days_since_last_rotation DESC, total_rotations DESC;

-- ============================================================================
-- SECTION 5: COUNSELOR (db_counselor) - ADHERENCE & COUNSELING ANALYSIS
-- ============================================================================

-- 5.1 Overall Adherence Statistics
SELECT '=== COUNSELOR: OVERALL ADHERENCE STATISTICS ===' AS section;

SELECT 
    'Overall Average Adherence' AS metric,
    ROUND(AVG(adherence_percent), 2) AS value,
    COUNT(*) AS total_assessments
FROM adherence_log
WHERE log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)

UNION ALL

SELECT 
    'Patients with Adherence < 85%' AS metric,
    COUNT(DISTINCT patient_id) AS value,
    NULL AS total_assessments
FROM adherence_log
WHERE adherence_percent < 85
  AND log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)

UNION ALL

SELECT 
    'Patients with Adherence < 70%' AS metric,
    COUNT(DISTINCT patient_id) AS value,
    NULL AS total_assessments
FROM adherence_log
WHERE adherence_percent < 70
  AND log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

-- 5.2 Adherence by Method
SELECT '=== COUNSELOR: ADHERENCE BY METHOD ===' AS section;

SELECT 
    method_used,
    COUNT(*) AS assessment_count,
    ROUND(AVG(adherence_percent), 2) AS avg_adherence,
    ROUND(MIN(adherence_percent), 2) AS min_adherence,
    ROUND(MAX(adherence_percent), 2) AS max_adherence,
    SUM(CASE WHEN adherence_percent < 85 THEN 1 ELSE 0 END) AS low_adherence_count
FROM adherence_log
WHERE log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY method_used
ORDER BY avg_adherence DESC;

-- 5.3 Patients Requiring Adherence Support
SELECT '=== COUNSELOR: PATIENTS REQUIRING ADHERENCE SUPPORT ===' AS section;

SELECT 
    p.patient_id,
    p.patient_code,
    CONCAT(per.first_name, ' ', per.last_name) AS patient_name,
    ROUND(AVG(al.adherence_percent), 2) AS avg_adherence,
    COUNT(al.adherence_id) AS assessment_count,
    MAX(al.log_date) AS last_assessment_date,
    (SELECT COUNT(*) FROM alert WHERE patient_id = p.patient_id AND alert_type = 'Low Adherence' AND is_resolved = FALSE) AS active_low_adherence_alerts
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
INNER JOIN adherence_log al ON p.patient_id = al.patient_id
WHERE p.current_status = 'Active'
  AND al.log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY p.patient_id, p.patient_code, per.first_name, per.last_name
HAVING avg_adherence < 85
ORDER BY avg_adherence ASC, assessment_count DESC
LIMIT 50;

-- 5.4 Counseling Session Statistics
SELECT '=== COUNSELOR: COUNSELING SESSION STATISTICS ===' AS section;

SELECT 
    DATE_FORMAT(session_date, '%Y-%m') AS session_month,
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT patient_id) AS unique_patients,
    COUNT(DISTINCT counselor_id) AS active_counselors,
    COUNT(DISTINCT topic) AS unique_topics
FROM counseling_session
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(session_date, '%Y-%m')
ORDER BY session_month DESC;

-- 5.5 Counseling Topics Distribution
SELECT '=== COUNSELOR: COUNSELING TOPICS DISTRIBUTION ===' AS section;

SELECT 
    topic,
    COUNT(*) AS session_count,
    COUNT(DISTINCT patient_id) AS unique_patients,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM counseling_session WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)), 2) AS percentage
FROM counseling_session
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY topic
ORDER BY session_count DESC;

-- 5.6 Adherence Trends Over Time
SELECT '=== COUNSELOR: ADHERENCE TRENDS OVER TIME ===' AS section;

SELECT 
    DATE_FORMAT(log_date, '%Y-%m') AS assessment_month,
    COUNT(*) AS total_assessments,
    ROUND(AVG(adherence_percent), 2) AS avg_adherence,
    SUM(CASE WHEN adherence_percent >= 95 THEN 1 ELSE 0 END) AS excellent_adherence,
    SUM(CASE WHEN adherence_percent >= 85 AND adherence_percent < 95 THEN 1 ELSE 0 END) AS good_adherence,
    SUM(CASE WHEN adherence_percent >= 70 AND adherence_percent < 85 THEN 1 ELSE 0 END) AS fair_adherence,
    SUM(CASE WHEN adherence_percent < 70 THEN 1 ELSE 0 END) AS poor_adherence
FROM adherence_log
WHERE log_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(log_date, '%Y-%m')
ORDER BY assessment_month DESC;

-- ============================================================================
-- SECTION 6: READ-ONLY (db_readonly) - REPORTING QUERIES
-- ============================================================================

-- 6.1 Monthly Activity Summary Report
SELECT '=== READONLY: MONTHLY ACTIVITY SUMMARY ===' AS section;

SELECT 
    DATE_FORMAT(activity_date, '%Y-%m') AS report_month,
    SUM(visits) AS total_visits,
    SUM(lab_tests) AS total_lab_tests,
    SUM(dispenses) AS total_dispenses,
    SUM(appointments) AS total_appointments,
    SUM(counseling_sessions) AS total_counseling
FROM (
    SELECT visit_date AS activity_date, 1 AS visits, 0 AS lab_tests, 0 AS dispenses, 0 AS appointments, 0 AS counseling_sessions FROM visit
    UNION ALL
    SELECT test_date AS activity_date, 0, 1, 0, 0, 0 FROM lab_test
    UNION ALL
    SELECT dispense_date AS activity_date, 0, 0, 1, 0, 0 FROM dispense
    UNION ALL
    SELECT scheduled_date AS activity_date, 0, 0, 0, 1, 0 FROM appointment
    UNION ALL
    SELECT session_date AS activity_date, 0, 0, 0, 0, 1 FROM counseling_session
) AS activity_data
WHERE activity_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(activity_date, '%Y-%m')
ORDER BY report_month DESC;

-- 6.2 Patient Demographics Summary
SELECT '=== READONLY: PATIENT DEMOGRAPHICS SUMMARY ===' AS section;

SELECT 
    per.sex,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 15 THEN '0-14'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 25 THEN '15-24'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 35 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 45 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS patient_count,
    SUM(CASE WHEN p.current_status = 'Active' THEN 1 ELSE 0 END) AS active_count
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
GROUP BY per.sex, 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 15 THEN '0-14'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 25 THEN '15-24'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 35 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 45 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) < 55 THEN '45-54'
        ELSE '55+'
    END
ORDER BY per.sex, age_group;

-- 6.3 Alert Summary by Type
SELECT '=== READONLY: ALERT SUMMARY BY TYPE ===' AS section;

SELECT 
    alert_type,
    alert_level,
    COUNT(*) AS total_alerts,
    SUM(CASE WHEN is_resolved = FALSE THEN 1 ELSE 0 END) AS active_alerts,
    SUM(CASE WHEN is_resolved = TRUE THEN 1 ELSE 0 END) AS resolved_alerts,
    ROUND(
        SUM(CASE WHEN is_resolved = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS resolution_rate
FROM alert
GROUP BY alert_type, alert_level
ORDER BY alert_type, alert_level;

-- ============================================================================
-- SECTION 7: CROSS-ROLE ANALYSIS - ADVANCED METRICS
-- ============================================================================

-- 7.1 Patient Retention Analysis
SELECT '=== CROSS-ROLE: PATIENT RETENTION ANALYSIS ===' AS section;

SELECT 
    YEAR(enrollment_date) AS cohort_year,
    COUNT(*) AS enrolled,
    SUM(CASE WHEN current_status = 'Active' THEN 1 ELSE 0 END) AS still_active,
    SUM(CASE WHEN current_status = 'LTFU' THEN 1 ELSE 0 END) AS ltfu,
    ROUND(
        SUM(CASE WHEN current_status = 'Active' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS retention_rate,
    AVG(DATEDIFF(CURDATE(), enrollment_date)) AS avg_days_in_care
FROM patient
WHERE enrollment_date >= '2020-01-01'
GROUP BY YEAR(enrollment_date)
ORDER BY cohort_year DESC;

-- 7.2 CAG Performance Metrics
SELECT '=== CROSS-ROLE: CAG PERFORMANCE METRICS ===' AS section;

SELECT 
    c.cag_id,
    c.cag_name,
    c.district,
    c.village,
    COUNT(DISTINCT pc.patient_id) AS total_members,
    SUM(CASE WHEN pc.is_active = TRUE THEN 1 ELSE 0 END) AS active_members,
    COUNT(cr.rotation_id) AS total_rotations,
    AVG(cr.patients_served) AS avg_patients_per_rotation,
    MAX(cr.rotation_date) AS last_rotation_date,
    (SELECT AVG(al.adherence_percent) 
     FROM adherence_log al
     INNER JOIN patient_cag pc2 ON al.patient_id = pc2.patient_id
     WHERE pc2.cag_id = c.cag_id
       AND pc2.is_active = TRUE
       AND al.log_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    ) AS avg_cag_adherence
FROM cag c
LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id
LEFT JOIN cag_rotation cr ON c.cag_id = cr.cag_id
WHERE c.status = 'Active'
GROUP BY c.cag_id, c.cag_name, c.district, c.village
ORDER BY active_members DESC, total_rotations DESC;

-- 7.3 Staff Productivity Analysis
SELECT '=== CROSS-ROLE: STAFF PRODUCTIVITY ANALYSIS ===' AS section;

SELECT 
    s.staff_id,
    s.staff_code,
    CONCAT(per.first_name, ' ', per.last_name) AS staff_name,
    s.cadre,
    (SELECT COUNT(*) FROM visit WHERE staff_id = s.staff_id AND visit_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) AS visits_last_3_months,
    (SELECT COUNT(*) FROM lab_test WHERE staff_id = s.staff_id AND test_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) AS lab_tests_last_3_months,
    (SELECT COUNT(*) FROM dispense WHERE staff_id = s.staff_id AND dispense_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) AS dispenses_last_3_months,
    (SELECT COUNT(*) FROM counseling_session WHERE counselor_id = s.staff_id AND session_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) AS counseling_sessions_last_3_months
FROM staff s
INNER JOIN person per ON s.person_id = per.person_id
WHERE s.active = TRUE
ORDER BY (visits_last_3_months + lab_tests_last_3_months + dispenses_last_3_months + counseling_sessions_last_3_months) DESC;

-- 7.4 Time to ART Initiation Analysis
SELECT '=== CROSS-ROLE: TIME TO ART INITIATION ===' AS section;

SELECT 
    CASE 
        WHEN DATEDIFF(art_start_date, enrollment_date) = 0 THEN 'Same day'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 7 THEN '1-7 days'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 30 THEN '8-30 days'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 90 THEN '31-90 days'
        ELSE '90+ days'
    END AS time_to_art,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient WHERE art_start_date IS NOT NULL), 2) AS percentage
FROM patient
WHERE art_start_date IS NOT NULL
  AND current_status = 'Active'
GROUP BY 
    CASE 
        WHEN DATEDIFF(art_start_date, enrollment_date) = 0 THEN 'Same day'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 7 THEN '1-7 days'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 30 THEN '8-30 days'
        WHEN DATEDIFF(art_start_date, enrollment_date) <= 90 THEN '31-90 days'
        ELSE '90+ days'
    END
ORDER BY MIN(DATEDIFF(art_start_date, enrollment_date));

-- 7.5 Comprehensive Patient Care Metrics
SELECT '=== CROSS-ROLE: COMPREHENSIVE PATIENT CARE METRICS ===' AS section;

SELECT 
    per.district,
    COUNT(DISTINCT p.patient_id) AS total_patients,
    ROUND(AVG(DATEDIFF(CURDATE(), p.enrollment_date)), 0) AS avg_days_in_care,
    COUNT(DISTINCT v.visit_id) / COUNT(DISTINCT p.patient_id) AS avg_visits_per_patient,
    COUNT(DISTINCT lt.lab_test_id) / COUNT(DISTINCT p.patient_id) AS avg_lab_tests_per_patient,
    COUNT(DISTINCT d.dispense_id) / COUNT(DISTINCT p.patient_id) AS avg_dispenses_per_patient,
    ROUND(AVG(al.adherence_percent), 2) AS avg_adherence,
    SUM(CASE WHEN a.is_resolved = FALSE THEN 1 ELSE 0 END) AS active_alerts
FROM patient p
INNER JOIN person per ON p.person_id = per.person_id
LEFT JOIN visit v ON p.patient_id = v.patient_id
LEFT JOIN lab_test lt ON p.patient_id = lt.patient_id
LEFT JOIN dispense d ON p.patient_id = d.patient_id
LEFT JOIN adherence_log al ON p.patient_id = al.patient_id
LEFT JOIN alert a ON p.patient_id = a.patient_id
WHERE p.current_status = 'Active'
GROUP BY per.district
ORDER BY total_patients DESC;

-- ============================================================================
-- END OF ROLE-BASED ANALYSIS QUERIES
-- ============================================================================

SELECT '=== ANALYSIS COMPLETE ===' AS status,
       'All role-based analyses have been executed. Review results above.' AS note;

