# Enhanced Entity Relationship (EER) Diagram
## HIV Patient Care & Treatment Monitoring System

```mermaid
erDiagram
    %% ============================================================================
    %% SUPER TYPE: person (Generalization)
    %% ============================================================================
    person {
        int person_id PK
        string nin UK "National Identification Number"
        string first_name
        string middle_name
        string last_name
        date date_of_birth
        enum gender "Male, Female, Other"
        string phone_number
        string email
        string district "Uganda District"
        string subcounty
        string parish
        string village
        string address_line
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% SUB TYPES: patient and staff (Specialization from person)
    %% ============================================================================
    patient {
        int patient_id PK
        int person_id FK
        string patient_number UK
        date enrollment_date
        date art_start_date
        enum current_status "Active, Transferred-Out, LTFU, Dead" "Disjoint Categorization"
        int baseline_cd4
        decimal baseline_vl
        enum who_stage "Stage 1-4"
        enum tb_status
        enum pregnancy_status
        string next_of_kin_name
        string next_of_kin_phone
        string next_of_kin_relationship
        timestamp created_at
        timestamp updated_at
    }

    staff {
        int staff_id PK
        int person_id FK
        string staff_number UK
        date employment_date
        enum employment_status "Active, Inactive, Terminated"
        string qualification
        string specialization
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% ROLE AND STAFF_ROLE (Overlapping Specialization)
    %% ============================================================================
    role {
        int role_id PK
        string role_name UK "doctor, clinical officer, nurse, etc."
        string role_description
        timestamp created_at
    }

    staff_role {
        int staff_role_id PK
        int staff_id FK
        int role_id FK
        date assigned_date
        boolean is_active
        timestamp created_at
    }

    %% ============================================================================
    %% CLINICAL ENTITIES
    %% ============================================================================
    visit {
        int visit_id PK
        int patient_id FK
        date visit_date
        enum visit_type "Initial, Follow-up, Emergency, Refill"
        int staff_id FK "Attending clinician"
        decimal weight
        decimal height
        int bp_systolic
        int bp_diastolic
        decimal temperature
        int pulse
        int respiratory_rate
        text clinical_notes
        text diagnosis
        enum who_stage
        enum tb_screening_result
        enum pregnancy_test_result
        date next_appointment_date
        timestamp created_at
        timestamp updated_at
    }

    lab_test {
        int lab_test_id PK
        int patient_id FK
        enum test_type "Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis" "Categorization"
        date test_date
        int ordered_by FK "Staff who ordered"
        int performed_by FK "Lab technician"
        string sample_id "CPHL Sample ID for VL"
        date sample_collection_date
        string result_value
        decimal result_numeric
        text result_text
        string result_unit
        string reference_range
        boolean is_abnormal
        enum status "Pending, Completed, Cancelled"
        text notes
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% PHARMACY ENTITIES
    %% ============================================================================
    regimen {
        int regimen_id PK
        string regimen_code UK "MOH Regimen Code"
        string regimen_name "e.g., TDF/3TC/DTG"
        enum regimen_line "First Line, Second Line, Third Line"
        boolean is_pediatric
        boolean is_active
        text description
        timestamp created_at
        timestamp updated_at
    }

    dispense {
        int dispense_id PK
        int patient_id FK
        int regimen_id FK
        date dispense_date
        int dispensed_by FK "Pharmacist"
        int days_supply "1-365"
        int quantity
        date next_refill_date
        string batch_number
        date expiry_date
        text notes
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% APPOINTMENT AND COUNSELING
    %% ============================================================================
    appointment {
        int appointment_id PK
        int patient_id FK
        date appointment_date
        time appointment_time
        enum appointment_type "Routine, Follow-up, VL Review, Counseling, Emergency"
        int scheduled_by FK
        enum status "Scheduled, Attended, Missed, Cancelled, Rescheduled"
        text notes
        timestamp created_at
        timestamp updated_at
    }

    counseling_session {
        int counseling_id PK
        int patient_id FK
        date session_date
        int counselor_id FK
        enum session_type "Adherence Support, Psychosocial, Disclosure, Pre-ART, Post-ART, Other"
        int session_duration "minutes"
        text topics_discussed
        text outcomes
        boolean follow_up_required
        date next_session_date
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% ADHERENCE AND ALERTS
    %% ============================================================================
    adherence_log {
        int adherence_id PK
        int patient_id FK
        date assessment_date
        enum assessment_method "Pill Count, Self-Report, CAG, Computed"
        int assessed_by FK
        decimal adherence_percentage "0-100%"
        int pills_missed
        int pills_expected
        int days_missed
        text notes
        timestamp created_at
        timestamp updated_at
    }

    alert {
        int alert_id PK
        int patient_id FK
        enum alert_type "High Viral Load, Overdue VL, Missed Refill, Missed Appointment, Low Adherence, LTFU Risk, Other"
        text alert_message
        enum severity "Low, Medium, High, Critical"
        enum status "Active, Acknowledged, Resolved, Dismissed"
        timestamp created_at
        timestamp acknowledged_at
        int acknowledged_by FK
        timestamp resolved_at
        int resolved_by FK
        string related_entity_type
        int related_entity_id
    }

    %% ============================================================================
    %% AUDIT LOG
    %% ============================================================================
    audit_log {
        bigint audit_id PK
        string table_name
        int record_id
        enum action "INSERT, UPDATE, DELETE"
        json old_values
        json new_values
        int changed_by FK
        timestamp changed_at
        string ip_address
        string user_agent
    }

    %% ============================================================================
    %% RELATIONSHIPS
    %% ============================================================================
    
    %% Generalization (Inheritance)
    person ||--o| patient : "inherits"
    person ||--o| staff : "inherits"
    
    %% Overlapping Specialization
    staff ||--o{ staff_role : "has"
    role ||--o{ staff_role : "assigned to"
    
    %% Patient Relationships
    patient ||--o{ visit : "has"
    patient ||--o{ lab_test : "has"
    patient ||--o{ dispense : "receives"
    patient ||--o{ appointment : "scheduled for"
    patient ||--o{ counseling_session : "attends"
    patient ||--o{ adherence_log : "has"
    patient ||--o{ alert : "has"
    
    %% Staff Relationships
    staff ||--o{ visit : "conducts"
    staff ||--o{ lab_test : "orders"
    staff ||--o{ lab_test : "performs"
    staff ||--o{ dispense : "dispenses"
    staff ||--o{ appointment : "schedules"
    staff ||--o{ counseling_session : "counsels"
    staff ||--o{ adherence_log : "assesses"
    staff ||--o{ alert : "acknowledges/resolves"
    staff ||--o{ audit_log : "makes changes"
    
    %% Pharmacy Relationships
    regimen ||--o{ dispense : "prescribed as"
    
    %% Notes:
    %% - person is a supertype with patient and staff as subtypes (Generalization)
    %% - staff_role implements overlapping specialization (staff can have multiple roles)
    %% - patient.current_status is disjoint categorization (one value only)
    %% - lab_test.test_type is categorization (multiple test types)
    %% - All relationships enforce referential integrity via foreign keys
```

## EER Model Features Explained

### 1. **Generalization (Supertype/Subtype)**
- **person** is the supertype
- **patient** and **staff** are subtypes that inherit from person
- Both share common attributes (NIN, name, DOB, gender, location, contact)

### 2. **Overlapping Specialization**
- **staff** can have multiple **roles** simultaneously
- Implemented via **staff_role** junction table
- Example: A staff member can be both a "nurse" and "midwife"

### 3. **Disjoint Categorization**
- **patient.current_status** must be exactly one of: Active, Transferred-Out, LTFU, Dead
- Mutually exclusive values

### 4. **Categorization**
- **lab_test.test_type** categorizes tests into: Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis
- Multiple test types can exist for the same patient

### 5. **Ugandan Context**
- NIN (National Identification Number) as unique identifier
- Location hierarchy: District → Subcounty → Parish → Village
- ART regimens follow Uganda MOH naming conventions
- CPHL sample ID for viral load tests
- LTFU guidelines (90 days) and appointment tracking (14 days)

### 6. **Referential Integrity**
- All foreign key relationships enforce CASCADE or RESTRICT rules
- Prevents orphaned records
- Maintains data consistency

### 7. **Business Rules Enforced**
- ART start date must be >= enrollment date
- Days supply must be 1-365
- Adherence percentage must be 0-100%
- Viral load results must be >= 0
- Dates cannot be in the future
- Next refill date calculated from dispense date + days supply

