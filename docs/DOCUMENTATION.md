# HIV Patient Care & Treatment Monitoring System
## Mukono General Hospital ART Clinic

**Complete Database System Documentation**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Database Design](#database-design)
3. [EER Model Features](#eer-model-features)
4. [Table Dictionary](#table-dictionary)
5. [Constraints & Business Rules](#constraints--business-rules)
6. [Stored Procedures](#stored-procedures)
7. [Triggers](#triggers)
8. [Views](#views)
9. [Security & RBAC](#security--rbac)
10. [API Endpoints](#api-endpoints)
11. [Installation & Setup](#installation--setup)

---

## Project Overview

This system is designed for **Mukono General Hospital ART Clinic** in Uganda and complies with:
- Ugandan Ministry of Health standards (HMIS)
- Uganda Viral Load Monitoring Guidelines
- Ugandan patient tracing workflows
- Strategic Development Goal 4 (Quality Healthcare)

### Key Features

- **Patient Demographics** tracking with Uganda NIN
- **ART Enrollment & Treatment History**
- **Clinical Visits** (HMIS 031 compliant)
- **Laboratory Test Results** (Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis)
- **Pharmacy Dispensing** (ART regimens, refill dates)
- **Counseling Sessions** (adherence support, psychosocial)
- **Appointment Scheduling** and missed visit tracking
- **Adherence Tracking** (pill count/self-report/CAG/computed)
- **Automated Alerts** (high viral load, overdue VL, missed refill, missed appointment)
- **Audit Logging**
- **Staff Roles and Access Control**

---

## Database Design

### Architecture

The database uses an **Enhanced Entity Relationship (EER) Model** with:

1. **Generalization (Supertype/Subtype)**
   - `person` is the supertype
   - `patient` and `staff` are subtypes that inherit from `person`

2. **Overlapping Specialization**
   - `staff` can have multiple `roles` simultaneously via `staff_role` junction table

3. **Disjoint Categorization**
   - `patient.current_status` must be exactly one of: Active, Transferred-Out, LTFU, Dead

4. **Categorization**
   - `lab_test.test_type` categorizes tests into multiple types

### Uganda-Specific Context

- **NIN (National Identification Number)**: VARCHAR(20), unique identifier
- **Location Hierarchy**: District → Subcounty → Parish → Village
- **ART Regimens**: Follow Uganda MOH naming (TDF/3TC/DTG, etc.)
- **CPHL Sample ID**: For viral load tests
- **LTFU Guidelines**: 90 days for Lost to Follow-Up
- **Appointment Tracking**: 14 days grace period for missed appointments

---

## EER Model Features

### 1. Generalization (Supertype/Subtype)

**person** (Supertype)
- Contains common attributes: NIN, name, DOB, gender, location, contact
- Inherited by: `patient` and `staff`

**patient** (Subtype)
- Inherits all `person` attributes
- Adds: patient_code, enrollment_date, art_start_date, current_status, next_of_kin, support_group, treatment_partner

**staff** (Subtype)
- Inherits all `person` attributes
- Adds: staff_code, cadre, moH_registration_no, hire_date, active

### 2. Overlapping Specialization

**staff_role** junction table allows:
- One staff member to have multiple roles
- Example: A nurse can also be a midwife
- Roles represent system privileges, not job cadres

### 3. Disjoint Categorization

**patient.current_status**
- Must be exactly one value: Active, Transferred-Out, LTFU, Dead
- Mutually exclusive

### 4. Categorization

**lab_test.test_type**
- Multiple test types can exist for same patient
- Types: Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis

---

## Table Dictionary

### Core Tables

#### 1. person (Supertype)
| Column | Type | Description |
|--------|------|-------------|
| person_id | INT UNSIGNED PK | Unique internal ID |
| nin | VARCHAR(20) UNIQUE | National Identification Number (NIRA-issued) |
| first_name | VARCHAR(100) | Person's first name |
| last_name | VARCHAR(100) | Person's surname |
| other_name | VARCHAR(100) | Optional local/tribal name |
| sex | ENUM('M','F') | Gender - Male or Female only |
| date_of_birth | DATE | Date of birth |
| phone_contact | VARCHAR(20) | MTN/Airtel phone |
| district | VARCHAR(100) | District of residence |
| subcounty | VARCHAR(100) | Subcounty |
| parish | VARCHAR(100) | Parish |
| village | VARCHAR(100) | Village/zone |
| created_at | TIMESTAMP | When added |

#### 2. patient (Subtype)
| Column | Type | Description |
|--------|------|-------------|
| patient_id | INT UNSIGNED PK | Inherits from person |
| person_id | INT UNSIGNED FK | Reference to person |
| patient_code | VARCHAR(50) UNIQUE | Hospital-specific ART ID (e.g., MGH/ART/0001) |
| enrollment_date | DATE | First registration at HIV clinic |
| art_start_date | DATE | When ART started |
| current_status | ENUM | Active, Transferred-Out, LTFU, Dead |
| next_of_kin | VARCHAR(150) | NOK name |
| nok_phone | VARCHAR(20) | NOK phone |
| support_group | VARCHAR(150) | e.g., Community ART group (CAG) |
| treatment_partner | VARCHAR(150) | Person helping with adherence |

#### 3. staff (Subtype)
| Column | Type | Description |
|--------|------|-------------|
| staff_id | INT UNSIGNED PK | Inherits from person |
| person_id | INT UNSIGNED FK | Reference to person |
| staff_code | VARCHAR(30) UNIQUE | Hospital staff ID |
| cadre | ENUM | Doctor, Clinical Officer, Nurse, Midwife, Lab Technician, Pharmacist, Counselor, Records Officer |
| moH_registration_no | VARCHAR(50) | Professional registration number |
| hire_date | DATE | When staff joined hospital |
| active | BOOLEAN | Whether active |

#### 4. role
| Column | Type | Description |
|--------|------|-------------|
| role_id | INT UNSIGNED PK | System privilege role ID |
| role_name | VARCHAR(50) UNIQUE | Role name (db_admin, db_clinician, etc.) |

#### 5. staff_role
| Column | Type | Description |
|--------|------|-------------|
| staff_id | INT UNSIGNED FK | Reference to staff |
| role_id | INT UNSIGNED FK | Reference to role |
| PRIMARY KEY (staff_id, role_id) | | Composite key |

#### 6. visit (HMIS 031 compliant)
| Column | Type | Description |
|--------|------|-------------|
| visit_id | BIGINT UNSIGNED PK | Visit identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| staff_id | INT UNSIGNED FK | Clinician |
| visit_date | DATE | Visit date |
| who_stage | TINYINT | WHO Stage 1-4 |
| weight_kg | DECIMAL(5,2) | Weight in kg |
| bp | VARCHAR(20) | Blood pressure (e.g., "120/80") |
| tb_screening | ENUM | Negative, Presumptive, Positive |
| symptoms | TEXT | Patient symptoms |
| oi_diagnosis | TEXT | Opportunistic infection diagnosis |
| next_appointment_date | DATE | Next appointment |

#### 7. lab_test
| Column | Type | Description |
|--------|------|-------------|
| lab_test_id | BIGINT UNSIGNED PK | Lab test identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| visit_id | BIGINT UNSIGNED FK | Reference to visit (optional) |
| staff_id | INT UNSIGNED FK | Staff who ordered/performed |
| test_type | ENUM | Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis |
| result_numeric | DECIMAL(18,4) | Numeric result |
| result_text | VARCHAR(150) | Text result |
| test_date | DATE | Test date |
| units | VARCHAR(50) | Unit of measurement |
| cphl_sample_id | VARCHAR(50) | CPHL Sample ID for VL |
| result_status | ENUM | Pending, Completed, Rejected |

#### 8. regimen
| Column | Type | Description |
|--------|------|-------------|
| regimen_id | INT UNSIGNED PK | Regimen identifier |
| regimen_code | VARCHAR(50) UNIQUE | MOH Regimen Code |
| regimen_name | VARCHAR(150) | e.g., TDF/3TC/DTG |
| line | ENUM | First Line, Second Line, Third Line |

#### 9. dispense
| Column | Type | Description |
|--------|------|-------------|
| dispense_id | BIGINT UNSIGNED PK | Dispense identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| staff_id | INT UNSIGNED FK | Pharmacist |
| regimen_id | INT UNSIGNED FK | Reference to regimen |
| dispense_date | DATE | Dispense date |
| days_supply | INT UNSIGNED | Days of medication supplied (1-365) |
| quantity_dispensed | INT UNSIGNED | Quantity dispensed |
| next_refill_date | DATE | Calculated: dispense_date + days_supply |
| notes | TEXT | Additional notes |

#### 10. appointment
| Column | Type | Description |
|--------|------|-------------|
| appointment_id | BIGINT UNSIGNED PK | Appointment identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| staff_id | INT UNSIGNED FK | Staff who scheduled |
| scheduled_date | DATE | Appointment date |
| status | ENUM | Scheduled, Attended, Missed, Rescheduled, Cancelled |
| reason | VARCHAR(150) | Appointment reason |

#### 11. counseling_session
| Column | Type | Description |
|--------|------|-------------|
| counseling_id | BIGINT UNSIGNED PK | Counseling session identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| counselor_id | INT UNSIGNED FK | Reference to staff (counselor) |
| session_date | DATE | Session date |
| topic | VARCHAR(150) | Session topic |
| adherence_barriers | TEXT | Adherence barriers discussed |
| notes | TEXT | Session notes |

#### 12. adherence_log
| Column | Type | Description |
|--------|------|-------------|
| adherence_id | BIGINT UNSIGNED PK | Adherence log identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| log_date | DATE | Assessment date |
| adherence_percent | DECIMAL(5,2) | Adherence percentage (0-100%) |
| method_used | ENUM | Pill Count, Pharmacy Refill, Self Report, CAG Report, Computed |
| notes | TEXT | Additional notes |

#### 13. alert
| Column | Type | Description |
|--------|------|-------------|
| alert_id | BIGINT UNSIGNED PK | Alert identifier |
| patient_id | INT UNSIGNED FK | Reference to patient |
| alert_type | ENUM | High Viral Load, Overdue VL, Missed Appointment, Missed Refill, Low Adherence, Severe OI |
| alert_level | ENUM | Info, Warning, Critical |
| alert_msg | TEXT | Alert message |
| triggered_at | TIMESTAMP | When alert was triggered |
| is_resolved | BOOLEAN | Whether alert is resolved |
| resolved_at | TIMESTAMP | When alert was resolved |

#### 14. audit_log
| Column | Type | Description |
|--------|------|-------------|
| audit_id | BIGINT UNSIGNED PK | Audit log identifier |
| staff_id | INT UNSIGNED FK | Staff who made the change |
| action | VARCHAR(100) | INSERT, UPDATE, DELETE |
| table_name | VARCHAR(100) | Table name |
| record_id | VARCHAR(100) | Record ID |
| details | TEXT | Change details |
| action_time | TIMESTAMP | When action occurred |

---

## Constraints & Business Rules

### Data Validation

1. **NIN**: Must be unique across all persons
2. **Age**: Calculated from date_of_birth, must be reasonable (0-120 years)
3. **Days Supply**: Must be > 0 and ≤ 365
4. **Adherence**: Must be 0-100%
5. **Viral Load**: Numeric results must be ≥ 0
6. **Dates**: test_date, dispense_date, visit_date must not be in the future
7. **ART Start**: art_start_date must be ≥ enrollment_date
8. **WHO Stage**: Must be 1-4 if provided
9. **Next Refill**: Must equal dispense_date + days_supply

### Referential Integrity

- All foreign keys enforce CASCADE or RESTRICT rules
- Prevents orphaned records
- Maintains data consistency

### Business Rules

1. **LTFU Definition**: Patient inactive for >90 days (no visit or dispense)
2. **Missed Appointment**: Appointment past due by >14 days
3. **High Viral Load**: VL > 1000 copies/mL triggers alert
4. **Overdue VL**: VL test overdue if >180 days since last test
5. **Low Adherence**: Adherence <85% triggers alert

---

## Stored Procedures

### 1. sp_compute_adherence(patient_id, start_date, end_date)
- Computes adherence percentage based on dispense records
- Calculates pills expected vs. pills missed
- Inserts result into adherence_log with method 'Computed'

### 2. sp_check_overdue_vl()
- Checks all active patients for overdue viral load tests
- Creates alerts for patients with VL >180 days old
- Runs daily via scheduled event

### 3. sp_mark_missed_appointments(grace_days)
- Marks appointments as 'Missed' if past due by grace_days (default 14)
- Creates alerts for missed appointments
- Runs daily via scheduled event

### 4. sp_update_patient_status_ltfu()
- Updates patient status to 'LTFU' if inactive for >90 days
- Creates LTFU alerts
- Runs daily via scheduled event

### 5. sp_check_missed_refills()
- Checks for patients with missed refills
- Creates alerts for overdue refills
- Runs daily via scheduled event

---

## Triggers

### 1. trg_lab_test_high_vl_alert
- **When**: AFTER INSERT on lab_test
- **Action**: Creates 'High Viral Load' alert if VL > 1000 copies/mL

### 2. trg_lab_test_high_vl_alert_update
- **When**: AFTER UPDATE on lab_test
- **Action**: Creates 'High Viral Load' alert if VL result updated to > 1000

### 3. trg_appointment_missed_alert
- **When**: AFTER UPDATE on appointment
- **Action**: Creates 'Missed Appointment' alert when status changes to 'Missed'

### 4. trg_adherence_low_alert
- **When**: AFTER INSERT on adherence_log
- **Action**: Creates 'Low Adherence' alert if adherence < 85%

### 5. Audit Triggers
- **trg_patient_audit_insert**: Logs patient creation
- **trg_patient_audit_update**: Logs patient status changes
- **trg_visit_audit_insert**: Logs visit creation
- **trg_lab_test_audit_insert/update**: Logs lab test changes
- **trg_dispense_audit_insert**: Logs dispense creation

---

## Views

### 1. v_active_patients_summary
- Summary of all active patients
- Includes last visit, last dispense, last VL, last adherence

### 2. v_patient_care_timeline
- Chronological timeline of patient care events
- Includes enrollment, ART start, visits, lab tests, dispenses, appointments

### 3. v_active_alerts_summary
- All active (unresolved) alerts
- Sorted by severity and date

### 4. v_viral_load_monitoring
- Viral load monitoring status for all active patients
- Shows last VL date, result, status (High/Suppressed/Unknown), test status (Overdue/Due Soon/Current)

### 5. v_adherence_summary
- Adherence summary for all active patients
- Includes last assessment date, percentage, method, category (Excellent/Good/Fair/Poor)

### 6. v_staff_with_roles
- Staff information with assigned roles
- Useful for access control management

---

## Security & RBAC

### Database Roles

1. **db_admin**: Full access to all tables and procedures
2. **db_clinician**: Read/write access to clinical tables (visit, appointment, patient, lab_test, adherence_log, alert)
3. **db_lab**: Read access to patient/staff, write access to lab_test
4. **db_pharmacy**: Read access to patient/regimen, write access to dispense
5. **db_counselor**: Read access to patient, write access to counseling_session, adherence_log, appointment
6. **db_readonly**: Read-only access to all tables and views

### Access Control

- Roles are assigned via `staff_role` table
- Each staff member can have multiple roles (overlapping specialization)
- GRANT statements in `database/security.sql`

---

## API Endpoints

### Base URL: `/api`

### Patients
- `GET /patients` - Get all patients (with pagination, filtering)
- `GET /patients/:id` - Get patient by ID (with related data)
- `POST /patients` - Create new patient
- `PUT /patients/:id` - Update patient
- `GET /patients/:id/timeline` - Get patient care timeline

### Visits
- `GET /visits` - Get all visits (with filtering)
- `GET /visits/:id` - Get visit by ID
- `POST /visits` - Create new visit
- `PUT /visits/:id` - Update visit

### Lab Tests
- `GET /lab-tests` - Get all lab tests (with filtering)
- `GET /lab-tests/:id` - Get lab test by ID
- `POST /lab-tests` - Create new lab test
- `PUT /lab-tests/:id` - Update lab test results
- `GET /lab-tests/patient/:patientId/viral-load` - Get viral load history

---

## Installation & Setup

### Prerequisites
- MySQL 8.0+
- Node.js 18+
- npm or yarn

### Database Setup

1. Create database:
```sql
CREATE DATABASE hiv_care_monitoring;
```

2. Run schema:
```bash
mysql -u root -p hiv_care_monitoring < database/schema.sql
```

3. Run stored procedures:
```bash
mysql -u root -p hiv_care_monitoring < database/stored_procedures.sql
```

4. Run triggers:
```bash
mysql -u root -p hiv_care_monitoring < database/triggers.sql
```

5. Run views:
```bash
mysql -u root -p hiv_care_monitoring < database/views.sql
```

6. Run security:
```bash
mysql -u root -p hiv_care_monitoring < database/security.sql
```

7. Run events:
```bash
mysql -u root -p hiv_care_monitoring < database/events.sql
```

8. Seed data (optional):
```bash
mysql -u root -p hiv_care_monitoring < database/seed_data.sql
```

### Backend Setup

1. Install dependencies:
```bash
cd backend
npm install
```

2. Set up environment variables:
```bash
DATABASE_URL="mysql://user:password@localhost:3306/hiv_care_monitoring"
```

3. Generate Prisma client:
```bash
npm run prisma:generate
```

4. Run migrations:
```bash
npm run prisma:migrate
```

5. Start server:
```bash
npm run dev
```

### Testing

- Test stored procedures manually in MySQL
- Test API endpoints using Postman or curl
- Verify triggers by inserting test data
- Check scheduled events are running

---

## Milestone Summary

### Milestone 1: Requirements Specification ✅
- Functional requirements documented
- Uganda-specific context identified
- HMIS compliance requirements defined

### Milestone 2: Design ✅
- EER diagram created (Mermaid format)
- All EER features implemented (generalization, specialization, categorization, disjoint)
- Referential integrity and business rules defined

### Milestone 3: Database Development ✅
- Complete schema with all 14 tables
- Data validation constraints implemented
- Business rules enforced via CHECK constraints

### Milestone 4: Security and Automation ✅
- Database roles and RBAC implemented
- Stored procedures for automation
- Triggers for alerts and audit logging
- Scheduled events for daily/weekly tasks

### Milestone 5: Documentation and Dissemination ✅
- Comprehensive documentation (this file)
- EER diagram
- API documentation
- Installation guide

---

## Contact & Support

**Project**: HIV Patient Care & Treatment Monitoring System  
**Institution**: Mukono General Hospital  
**Location**: Mukono, Uganda  
**SDG Alignment**: SDG 4 - Quality Healthcare

---

**End of Documentation**

