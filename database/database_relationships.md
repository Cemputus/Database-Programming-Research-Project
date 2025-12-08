# Database Relationships (Foreign Keys)
## HIV Patient Care & Treatment Monitoring System

This document lists all foreign key relationships in the database schema.

---

## 📋 Table Relationships Overview

### 1. **person** (Super Type)
- **No incoming foreign keys** (root table)
- **Outgoing relationships:**
  - → `patient.person_id` (1:1)
  - → `staff.person_id` (1:1)

---

### 2. **patient** (Sub Type from person)
- **Incoming foreign keys:**
  - `person.person_id` → `patient.person_id` (fk_patient_person)
- **Outgoing relationships:**
  - → `visit.patient_id` (1:many)
  - → `lab_test.patient_id` (1:many)
  - → `dispense.patient_id` (1:many)
  - → `appointment.patient_id` (1:many)
  - → `counseling_session.patient_id` (1:many)
  - → `adherence_log.patient_id` (1:many)
  - → `alert.patient_id` (1:many)
  - → `patient_cag.patient_id` (many:many via junction)
  - → `cag.coordinator_patient_id` (1:many, optional)
  - → `cag_rotation.pickup_patient_id` (1:many)

---

### 3. **staff** (Sub Type from person)
- **Incoming foreign keys:**
  - `person.person_id` → `staff.person_id` (fk_staff_person)
- **Outgoing relationships:**
  - → `staff_role.staff_id` (many:many via junction)
  - → `visit.staff_id` (1:many)
  - → `lab_test.staff_id` (1:many)
  - → `dispense.staff_id` (1:many)
  - → `appointment.staff_id` (1:many)
  - → `counseling_session.counselor_id` (1:many)
  - → `cag.facility_staff_id` (1:many, optional)
  - → `audit_log.staff_id` (1:many, optional)

---

### 4. **role**
- **No incoming foreign keys**
- **Outgoing relationships:**
  - → `staff_role.role_id` (many:many via junction)

---

### 5. **staff_role** (Junction Table)
- **Incoming foreign keys:**
  - `staff.staff_id` → `staff_role.staff_id` (fk_staff_role_staff)
  - `role.role_id` → `staff_role.role_id` (fk_staff_role_role)

---

### 6. **visit**
- **Incoming foreign keys:**
  - `patient.patient_id` → `visit.patient_id` (fk_visit_patient)
  - `staff.staff_id` → `visit.staff_id` (fk_visit_staff)
- **Outgoing relationships:**
  - → `lab_test.visit_id` (1:many, optional)

---

### 7. **lab_test**
- **Incoming foreign keys:**
  - `patient.patient_id` → `lab_test.patient_id` (fk_lab_test_patient)
  - `visit.visit_id` → `lab_test.visit_id` (fk_lab_test_visit, optional)
  - `staff.staff_id` → `lab_test.staff_id` (fk_lab_test_staff)

---

### 8. **regimen**
- **No incoming foreign keys**
- **Outgoing relationships:**
  - → `dispense.regimen_id` (1:many)

---

### 9. **dispense**
- **Incoming foreign keys:**
  - `patient.patient_id` → `dispense.patient_id` (fk_dispense_patient)
  - `regimen.regimen_id` → `dispense.regimen_id` (fk_dispense_regimen)
  - `staff.staff_id` → `dispense.staff_id` (fk_dispense_staff)
- **Outgoing relationships:**
  - → `cag_rotation.dispense_id` (1:many, optional)

---

### 10. **appointment**
- **Incoming foreign keys:**
  - `patient.patient_id` → `appointment.patient_id` (fk_appointment_patient)
  - `staff.staff_id` → `appointment.staff_id` (fk_appointment_staff)

---

### 11. **counseling_session**
- **Incoming foreign keys:**
  - `patient.patient_id` → `counseling_session.patient_id` (fk_counseling_patient)
  - `staff.staff_id` → `counseling_session.counselor_id` (fk_counseling_counselor)

---

### 12. **cag** (Community ART Group)
- **Incoming foreign keys:**
  - `patient.patient_id` → `cag.coordinator_patient_id` (fk_cag_coordinator, optional)
  - `staff.staff_id` → `cag.facility_staff_id` (fk_cag_staff, optional)
- **Outgoing relationships:**
  - → `patient_cag.cag_id` (many:many via junction)
  - → `cag_rotation.cag_id` (1:many)

---

### 13. **patient_cag** (Junction Table)
- **Incoming foreign keys:**
  - `patient.patient_id` → `patient_cag.patient_id` (fk_patient_cag_patient)
  - `cag.cag_id` → `patient_cag.cag_id` (fk_patient_cag_cag)

---

### 14. **cag_rotation**
- **Incoming foreign keys:**
  - `cag.cag_id` → `cag_rotation.cag_id` (fk_rotation_cag)
  - `patient.patient_id` → `cag_rotation.pickup_patient_id` (fk_rotation_patient)
  - `dispense.dispense_id` → `cag_rotation.dispense_id` (fk_rotation_dispense, optional)

---

### 15. **adherence_log**
- **Incoming foreign keys:**
  - `patient.patient_id` → `adherence_log.patient_id` (fk_adherence_patient)

---

### 16. **alert**
- **Incoming foreign keys:**
  - `patient.patient_id` → `alert.patient_id` (fk_alert_patient)

---

### 17. **audit_log**
- **Incoming foreign keys:**
  - `staff.staff_id` → `audit_log.staff_id` (fk_audit_staff, optional)

---

## 🔗 Relationship Summary

### Total Foreign Keys: 26

### By Referenced Table:
- **person**: 2 references (patient, staff)
- **patient**: 11 references (visit, lab_test, dispense, appointment, counseling_session, adherence_log, alert, patient_cag, cag.coordinator, cag_rotation)
- **staff**: 8 references (staff_role, visit, lab_test, dispense, appointment, counseling_session, cag.facility_staff, audit_log)
- **role**: 1 reference (staff_role)
- **visit**: 1 reference (lab_test)
- **regimen**: 1 reference (dispense)
- **cag**: 2 references (patient_cag, cag_rotation)
- **dispense**: 1 reference (cag_rotation)

### Relationship Types:
- **1:1 (One-to-One)**: person ↔ patient, person ↔ staff
- **1:Many (One-to-Many)**: Most relationships (patient → visits, staff → visits, etc.)
- **Many:Many**: patient ↔ cag (via patient_cag), staff ↔ role (via staff_role)

### Delete Actions:
- **RESTRICT**: Most relationships (prevents deletion if referenced)
- **CASCADE**: Updates cascade, but deletions are restricted
- **SET NULL**: Optional relationships (coordinator_patient_id, facility_staff_id, visit_id, dispense_id, staff_id in audit_log)

---

## 📊 Entity Relationship Diagram Structure

```
person (Super Type)
├── patient (Sub Type)
│   ├── visit
│   ├── lab_test
│   ├── dispense
│   ├── appointment
│   ├── counseling_session
│   ├── adherence_log
│   ├── alert
│   ├── patient_cag → cag
│   └── cag_rotation
└── staff (Sub Type)
    ├── staff_role → role
    ├── visit
    ├── lab_test
    ├── dispense
    ├── appointment
    ├── counseling_session
    ├── cag (facility_staff_id)
    └── audit_log

regimen
└── dispense

cag
├── patient_cag → patient
└── cag_rotation
    └── dispense
```

---

**End of Database Relationships Documentation**

