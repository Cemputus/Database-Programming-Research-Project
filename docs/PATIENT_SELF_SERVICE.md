# Patient Self-Service Guide
## HIV Patient Care & Treatment Monitoring System

This guide explains how patients can access and view their own health data through the database system.

---

## Overview

Patients can access their own data using their **patient_code** (e.g., `MGH/ART/0001`) through:
- **Views**: Pre-defined queries showing patient-specific information
- **Stored Procedures**: Functions that return patient data based on patient_code

---

## Patient Views

### 1. v_patient_dashboard
**Main dashboard view** - Shows comprehensive patient overview

**Columns:**
- Patient information (name, age, status)
- Next appointment date and days until appointment
- Last visit date
- Last viral load result and status
- Last CD4 result
- Current regimen
- Next refill date
- Last adherence percentage and category
- Active alerts count

**Usage:**
```sql
SELECT * FROM v_patient_dashboard 
WHERE patient_code = 'MGH/ART/0001';
```

### 2. v_patient_visit_history
**Visit history** - All clinical visits

**Columns:**
- Visit date
- WHO stage
- Weight, blood pressure
- TB screening result
- Symptoms and OI diagnosis
- Next appointment date
- Clinician name and cadre

**Usage:**
```sql
SELECT * FROM v_patient_visit_history 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY visit_date DESC
LIMIT 20;
```

### 3. v_patient_lab_history
**Lab test history** - All laboratory test results

**Columns:**
- Test type (Viral Load, CD4, HB, etc.)
- Test date
- Result (numeric and text)
- Units
- CPHL sample ID (for VL)
- Result status
- Result status description (High/Suppressed/Undetectable for VL)

**Usage:**
```sql
SELECT * FROM v_patient_lab_history 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY test_date DESC;
```

### 4. v_patient_medication_history
**Medication dispensing history** - All medication dispenses

**Columns:**
- Dispense date
- Regimen name and line
- Days supply
- Quantity dispensed
- Next refill date
- Days until refill
- Refill status (Overdue/Due Soon/On Track)

**Usage:**
```sql
SELECT * FROM v_patient_medication_history 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY dispense_date DESC;
```

### 5. v_patient_appointments
**Appointment schedule** - All appointments

**Columns:**
- Scheduled date
- Status (Scheduled/Attended/Missed/Rescheduled/Cancelled)
- Reason
- Days until appointment
- Appointment status description
- Scheduled by name

**Usage:**
```sql
SELECT * FROM v_patient_appointments 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY scheduled_date DESC;
```

### 6. v_patient_adherence_history
**Adherence assessment history** - All adherence logs

**Columns:**
- Assessment date
- Adherence percentage
- Method used (Pill Count/Pharmacy Refill/Self Report/CAG Report/Computed)
- Adherence category (Excellent/Good/Fair/Needs Improvement)
- Days since assessment
- Notes

**Usage:**
```sql
SELECT * FROM v_patient_adherence_history 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY log_date DESC;
```

### 7. v_patient_alerts
**Alerts and notifications** - All patient alerts

**Columns:**
- Alert type (High Viral Load/Overdue VL/Missed Appointment/Missed Refill/Low Adherence/Severe OI)
- Alert level (Info/Warning/Critical)
- Alert message
- Triggered date
- Resolved status
- Days since alert

**Usage:**
```sql
SELECT * FROM v_patient_alerts 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
AND is_resolved = FALSE
ORDER BY priority_order, triggered_at DESC;
```

### 8. v_patient_progress_timeline
**Progress timeline** - Chronological view of all patient events

**Columns:**
- Event type (Enrollment/ART Start/Visit/Lab Test/Medication/Adherence)
- Event date
- Event description
- Event value and unit

**Usage:**
```sql
SELECT * FROM v_patient_progress_timeline 
WHERE patient_id = (SELECT patient_id FROM patient WHERE patient_code = 'MGH/ART/0001')
ORDER BY event_date DESC;
```

---

## Stored Procedures

All stored procedures use **patient_code** as the input parameter for security.

### 1. sp_patient_dashboard(patient_code)
**Get complete dashboard data**

```sql
CALL sp_patient_dashboard('MGH/ART/0001');
```

Returns: Complete dashboard view with all patient information

### 2. sp_patient_visits(patient_code, limit)
**Get visit history**

```sql
CALL sp_patient_visits('MGH/ART/0001', 20);
```

Parameters:
- `patient_code`: Patient's unique code
- `limit`: Number of visits to return (default: 20)

### 3. sp_patient_lab_tests(patient_code, test_type, limit)
**Get lab test history**

```sql
CALL sp_patient_lab_tests('MGH/ART/0001', 'Viral Load', 50);
CALL sp_patient_lab_tests('MGH/ART/0001', NULL, 50); -- All tests
```

Parameters:
- `patient_code`: Patient's unique code
- `test_type`: Filter by test type (NULL for all)
- `limit`: Number of tests to return (default: 50)

### 4. sp_patient_medications(patient_code, limit)
**Get medication history**

```sql
CALL sp_patient_medications('MGH/ART/0001', 20);
```

### 5. sp_patient_appointments(patient_code, status, limit)
**Get appointments**

```sql
CALL sp_patient_appointments('MGH/ART/0001', 'Scheduled', 20);
CALL sp_patient_appointments('MGH/ART/0001', NULL, 20); -- All appointments
```

Parameters:
- `patient_code`: Patient's unique code
- `status`: Filter by status (NULL for all)
- `limit`: Number of appointments to return (default: 20)

### 6. sp_patient_adherence(patient_code, limit)
**Get adherence history**

```sql
CALL sp_patient_adherence('MGH/ART/0001', 12);
```

### 7. sp_patient_alerts(patient_code, resolved_only, limit)
**Get alerts**

```sql
CALL sp_patient_alerts('MGH/ART/0001', FALSE, 20); -- Active alerts only
CALL sp_patient_alerts('MGH/ART/0001', TRUE, 20);  -- Resolved alerts
```

### 8. sp_patient_progress_timeline(patient_code, start_date, end_date, limit)
**Get progress timeline**

```sql
CALL sp_patient_progress_timeline('MGH/ART/0001', '2024-01-01', '2024-12-31', 50);
CALL sp_patient_progress_timeline('MGH/ART/0001', NULL, NULL, 50); -- All events
```

### 9. sp_patient_next_appointment(patient_code)
**Get next scheduled appointment**

```sql
CALL sp_patient_next_appointment('MGH/ART/0001');
```

Returns: Next upcoming appointment details

### 10. sp_patient_summary_stats(patient_code)
**Get summary statistics**

```sql
CALL sp_patient_summary_stats('MGH/ART/0001');
```

Returns: Summary statistics including:
- Total visits
- Total lab tests
- Total dispenses
- Total appointments (attended/missed)
- Total adherence assessments
- Average adherence
- Active alerts count
- Last visit/dispense/VL dates

---

## Security

### Patient Role: `db_patient`

Patients are assigned the `db_patient` role which:
- **Can access**: Patient self-service views and stored procedures
- **Cannot access**: Direct table queries (except own patient record for verification)
- **Cannot modify**: Any data (read-only access)

### Authentication

In production, each patient should have:
- A database user account (e.g., `patient_MGH_ART_0001`)
- Password authentication
- Assigned `db_patient` role
- Access limited to their own data via patient_code

### Example User Creation

```sql
-- Create patient user
CREATE USER 'patient_MGH_ART_0001'@'localhost' 
IDENTIFIED BY 'secure_password';

-- Assign patient role
GRANT 'db_patient' TO 'patient_MGH_ART_0001'@'localhost';

-- Set default role
SET DEFAULT ROLE 'db_patient' FOR 'patient_MGH_ART_0001'@'localhost';
```

---

## Common Queries for Patients

### Get Dashboard
```sql
CALL sp_patient_dashboard('MGH/ART/0001');
```

### Get Next Appointment
```sql
CALL sp_patient_next_appointment('MGH/ART/0001');
```

### Get Latest Viral Load
```sql
CALL sp_patient_lab_tests('MGH/ART/0001', 'Viral Load', 1);
```

### Get Current Medication
```sql
CALL sp_patient_medications('MGH/ART/0001', 1);
```

### Get Active Alerts
```sql
CALL sp_patient_alerts('MGH/ART/0001', FALSE, 10);
```

### Get Progress Timeline (Last 6 Months)
```sql
CALL sp_patient_progress_timeline(
    'MGH/ART/0001', 
    DATE_SUB(CURDATE(), INTERVAL 6 MONTH), 
    CURDATE(), 
    100
);
```

---

## Data Privacy

- Patients can **only** view their own data
- All queries are filtered by `patient_code`
- No access to other patients' information
- No ability to modify any data
- All access is logged via audit_log

---

## Support

For questions or issues accessing patient data, contact:
- **Hospital**: Mukono General Hospital ART Clinic
- **Location**: Mukono, Uganda

---

**End of Patient Self-Service Guide**

