# Database Setup Order
## Correct Sequence for Running SQL Files

This guide shows you the exact order to run the database files. **Order matters!** Some files depend on others, so running them in the wrong order will cause errors.

---

## 📋 Setup Order (Run These Files in This Exact Sequence)

### Step 1: Create the Database (One-Time Setup)
```sql
-- First, create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS hiv_patient_care;
USE hiv_patient_care;
```

### Step 2: Run Schema File (Foundation)
**File**: `database/schema.sql`

**Why first?** This creates all the tables - the foundation of everything else.

**What it does:**
- Creates all 17 tables (person, patient, staff, visit, lab_test, cag, patient_cag, cag_rotation, etc.)
- Sets up relationships between tables (foreign keys)
- Creates indexes for performance
- Sets up constraints and business rules

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/schema.sql
```

---

### Step 3: Run Triggers
**File**: `database/triggers.sql`

**Why third?** Triggers use tables and sometimes call procedures. Must run before procedures that might be called by triggers.

**What it does:**
- Creates triggers that automatically create alerts (high VL, missed appointments, etc.)
- Creates triggers for audit logging (tracks who changed what)
- Creates triggers for low adherence alerts

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/triggers.sql
```

---

### Step 4: Run Views (All Views - Staff/Admin, Patient, and CAG)
**File**: `database/views.sql`

**Why fourth?** Views query the tables we created.

**What it does:**
- Creates views for staff to see patient summaries
- Creates views for viral load monitoring
- Creates views for adherence summaries
- Creates views for active alerts
- Creates views for CAG management (summary, members, rotations, performance)
- Creates views for patients to see their own dashboard
- Creates views for patients to see their visit history, lab results, medications, appointments, and progress timeline

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/views.sql
```

---

### Step 5: Run Stored Procedures (All Procedures - General, Patient, and CAG)
**File**: `database/stored_procedures.sql`

**Why fifth?** Procedures use the tables and views we created.

**What it does:**
- Creates procedures for computing adherence
- Creates procedures for checking overdue viral loads
- Creates procedures for marking missed appointments
- Creates procedures for updating LTFU status
- Creates procedures for checking missed refills
- Creates procedures for patients to get their dashboard, visits, lab tests, medications, appointments, alerts, and progress timeline
- Creates procedures for CAG management (add/remove patients, record rotations, get members/statistics)

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/stored_procedures.sql
```

---

### Step 6: Run Security Setup
**File**: `database/security.sql`

**Why sixth?** Security roles need tables to exist first.

**What it does:**
- Creates database roles (db_admin, db_clinician, db_lab, db_pharmacy, db_counselor, db_readonly, db_patient)
- Grants appropriate permissions to each role
- Sets up access control so different users can only do what they're allowed

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/security.sql
```

---

### Step 7: Run Scheduled Events
**File**: `database/events.sql`

**Why seventh?** Events call the stored procedures we created earlier.

**What it does:**
- Sets up daily checks for overdue viral loads
- Sets up daily checks for missed appointments
- Sets up daily checks for missed refills
- Sets up daily updates for LTFU status
- Sets up weekly adherence computation

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/events.sql
```

---

### Step 8: Run Seed Data (Optional)
**File**: `database/seed_data.sql`

**Why last?** This inserts sample data, so everything else must exist first.

**What it does:**
- Inserts sample staff members
- Inserts sample patients (747 patients)
- Inserts sample visits
- Inserts sample lab tests
- Inserts sample dispenses
- Inserts sample appointments
- Inserts sample counseling sessions
- Inserts sample adherence logs
- Creates CAGs (30 CAGs across 5 districts)
- Maps all patients to CAGs in their villages
- Creates sample rotation records

**Command:**
```bash
mysql -u root -p hiv_patient_care < database/seed_data.sql
```

**Note:** Only run this if you want sample/test data. Skip it for production!

---

## 🚀 Quick Setup Script

You can create a script to run everything in order:

### For Windows (PowerShell):
```powershell
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS hiv_patient_care;"

# Run files in order
mysql -u root -p hiv_patient_care < database/schema.sql
mysql -u root -p hiv_patient_care < database/triggers.sql
mysql -u root -p hiv_patient_care < database/views.sql
mysql -u root -p hiv_patient_care < database/stored_procedures.sql
mysql -u root -p hiv_patient_care < database/security.sql
mysql -u root -p hiv_patient_care < database/events.sql
# mysql -u root -p hiv_patient_care < database/seed_data.sql  # Optional
```

### For Linux/Mac (Bash):
```bash
#!/bin/bash
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS hiv_patient_care;"

# Run files in order
mysql -u root -p hiv_patient_care < database/schema.sql
mysql -u root -p hiv_patient_care < database/triggers.sql
mysql -u root -p hiv_patient_care < database/views.sql
mysql -u root -p hiv_patient_care < database/stored_procedures.sql
mysql -u root -p hiv_patient_care < database/security.sql
mysql -u root -p hiv_patient_care < database/events.sql
# mysql -u root -p hiv_patient_care < database/seed_data.sql  # Optional
```

---

## ⚠️ Important Notes

1. **Always run `schema.sql` first** - Everything else depends on it!

2. **Check for errors** - If a file fails, fix the error before continuing.

3. **Seed data is optional** - Only use `seed_data.sql` for testing/development.

4. **Backup first** - If you're updating an existing database, backup first!

5. **Use the correct database** - Make sure you're connected to the right database.

---

## 🔍 Verification

After running all files, verify everything worked:

```sql
-- Check that tables exist
SHOW TABLES;

-- Should show 17 tables:
-- person, patient, staff, role, staff_role, visit, lab_test, 
-- regimen, dispense, appointment, counseling_session, 
-- cag, patient_cag, cag_rotation,
-- adherence_log, alert, audit_log

-- Check that procedures exist
SHOW PROCEDURE STATUS WHERE Db = 'hiv_patient_care';

-- Should show 16 procedures:
-- sp_compute_adherence, sp_check_overdue_vl, sp_mark_missed_appointments,
-- sp_update_patient_status_ltfu, sp_check_missed_refills,
-- sp_patient_dashboard, sp_patient_visits, sp_patient_lab_tests,
-- sp_patient_medications, sp_patient_appointments, sp_patient_adherence,
-- sp_patient_alerts, sp_patient_progress_timeline, sp_patient_next_appointment,
-- sp_patient_summary_stats, sp_cag_add_patient, sp_cag_remove_patient,
-- sp_cag_record_rotation, sp_cag_get_members, sp_cag_get_rotations,
-- sp_cag_get_statistics

-- Check that triggers exist
SHOW TRIGGERS;

-- Check that views exist
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Should show 18 views:
-- v_active_patients_summary, v_patient_care_timeline, v_active_alerts_summary,
-- v_viral_load_monitoring, v_adherence_summary, v_staff_with_roles,
-- v_cag_summary, v_cag_members, v_cag_rotation_history, v_cag_performance,
-- v_patient_dashboard, v_patient_visit_history, v_patient_lab_history,
-- v_patient_medication_history, v_patient_appointments, v_patient_adherence_history,
-- v_patient_alerts, v_patient_progress_timeline

-- Check that events exist
SHOW EVENTS;
```

---

## 📝 Summary

**Run in this order:**
1. ✅ `schema.sql` - **START HERE!**
2. ✅ `triggers.sql`
3. ✅ `views.sql` (includes all views: staff/admin, patient, and CAG)
4. ✅ `stored_procedures.sql` (includes all procedures: general, patient, and CAG)
5. ✅ `security.sql`
6. ✅ `events.sql`
7. ✅ `seed_data.sql` (optional)

**Remember:** `schema.sql` must be run first - it's the foundation!

**Note:** Files have been merged to reduce redundancy:
- `patient_views.sql` merged into `views.sql`
- `patient_procedures.sql` and `cag_procedures.sql` merged into `stored_procedures.sql`
