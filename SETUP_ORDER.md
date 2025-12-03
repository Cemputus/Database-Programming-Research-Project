# Database Setup Order
## Correct Sequence for Running SQL Files

This guide shows you the exact order to run the database files. **Order matters!** Some files depend on others, so running them in the wrong order will cause errors.

---

## 📋 Setup Order (Run These Files in This Exact Sequence)

### Step 1: Create the Database (One-Time Setup)
```sql
-- First, create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS hiv_care_monitoring;
USE hiv_care_monitoring;
```

### Step 2: Run Schema File (Foundation)
**File**: `database/schema.sql`

**Why first?** This creates all the tables - the foundation of everything else.

**What it does:**
- Creates all 14 tables (person, patient, staff, visit, lab_test, etc.)
- Sets up relationships between tables (foreign keys)
- Creates indexes for performance
- Sets up constraints and business rules

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/schema.sql
```

---

### Step 3: Run Stored Procedures
**File**: `database/stored_procedures.sql`

**Why second?** Procedures use the tables we just created.

**What it does:**
- Creates procedures for computing adherence
- Creates procedures for checking overdue viral loads
- Creates procedures for marking missed appointments
- Creates procedures for updating LTFU status
- Creates procedures for checking missed refills

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/stored_procedures.sql
```

---

### Step 4: Run Triggers
**File**: `database/triggers.sql`

**Why third?** Triggers use tables and sometimes call procedures.

**What it does:**
- Creates triggers that automatically create alerts (high VL, missed appointments, etc.)
- Creates triggers for audit logging (tracks who changed what)
- Creates triggers for low adherence alerts

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/triggers.sql
```

---

### Step 5: Run Views (Staff/Admin Views)
**File**: `database/views.sql`

**Why fourth?** Views query the tables we created.

**What it does:**
- Creates views for staff to see patient summaries
- Creates views for viral load monitoring
- Creates views for adherence summaries
- Creates views for active alerts

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/views.sql
```

---

### Step 6: Run Patient Views
**File**: `database/patient_views.sql`

**Why fifth?** Patient views also query the tables.

**What it does:**
- Creates views for patients to see their own dashboard
- Creates views for patients to see their visit history
- Creates views for patients to see their lab results
- Creates views for patients to see their medication history
- Creates views for patients to see their appointments
- Creates views for patients to see their progress timeline

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/patient_views.sql
```

---

### Step 7: Run Patient Procedures
**File**: `database/patient_procedures.sql`

**Why sixth?** Patient procedures use the patient views we just created.

**What it does:**
- Creates procedures for patients to get their dashboard
- Creates procedures for patients to get their visit history
- Creates procedures for patients to get their lab tests
- Creates procedures for patients to get their medications
- Creates procedures for patients to get their appointments
- Creates procedures for patients to get their alerts
- Creates procedures for patients to get their progress timeline

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/patient_procedures.sql
```

---

### Step 8: Run Security Setup
**File**: `database/security.sql`

**Why seventh?** Security roles need tables to exist first.

**What it does:**
- Creates database roles (db_admin, db_clinician, db_lab, db_pharmacy, db_counselor, db_readonly, db_patient)
- Grants appropriate permissions to each role
- Sets up access control so different users can only do what they're allowed

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/security.sql
```

---

### Step 9: Run Scheduled Events
**File**: `database/events.sql`

**Why eighth?** Events call the stored procedures we created earlier.

**What it does:**
- Sets up daily checks for overdue viral loads
- Sets up daily checks for missed appointments
- Sets up daily checks for missed refills
- Sets up daily updates for LTFU status
- Sets up weekly adherence computation

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/events.sql
```

---

### Step 10: Run Seed Data (Optional)
**File**: `database/seed_data.sql`

**Why last?** This inserts sample data, so everything else must exist first.

**What it does:**
- Inserts sample staff members
- Inserts sample patients
- Inserts sample visits
- Inserts sample lab tests
- Inserts sample dispenses
- Inserts sample appointments
- Inserts sample counseling sessions
- Inserts sample adherence logs

**Command:**
```bash
mysql -u root -p hiv_care_monitoring < database/seed_data.sql
```

**Note:** Only run this if you want sample/test data. Skip it for production!

---

## 🚀 Quick Setup Script

You can create a script to run everything in order:

### For Windows (PowerShell):
```powershell
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS hiv_care_monitoring;"

# Run files in order
mysql -u root -p hiv_care_monitoring < database/schema.sql
mysql -u root -p hiv_care_monitoring < database/stored_procedures.sql
mysql -u root -p hiv_care_monitoring < database/triggers.sql
mysql -u root -p hiv_care_monitoring < database/views.sql
mysql -u root -p hiv_care_monitoring < database/patient_views.sql
mysql -u root -p hiv_care_monitoring < database/patient_procedures.sql
mysql -u root -p hiv_care_monitoring < database/security.sql
mysql -u root -p hiv_care_monitoring < database/events.sql
# mysql -u root -p hiv_care_monitoring < database/seed_data.sql  # Optional
```

### For Linux/Mac (Bash):
```bash
#!/bin/bash
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS hiv_care_monitoring;"

# Run files in order
mysql -u root -p hiv_care_monitoring < database/schema.sql
mysql -u root -p hiv_care_monitoring < database/stored_procedures.sql
mysql -u root -p hiv_care_monitoring < database/triggers.sql
mysql -u root -p hiv_care_monitoring < database/views.sql
mysql -u root -p hiv_care_monitoring < database/patient_views.sql
mysql -u root -p hiv_care_monitoring < database/patient_procedures.sql
mysql -u root -p hiv_care_monitoring < database/security.sql
mysql -u root -p hiv_care_monitoring < database/events.sql
# mysql -u root -p hiv_care_monitoring < database/seed_data.sql  # Optional
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

-- Should show 14 tables:
-- person, patient, staff, role, staff_role, visit, lab_test, 
-- regimen, dispense, appointment, counseling_session, 
-- adherence_log, alert, audit_log

-- Check that procedures exist
SHOW PROCEDURE STATUS WHERE Db = 'hiv_care_monitoring';

-- Check that triggers exist
SHOW TRIGGERS;

-- Check that views exist
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Check that events exist
SHOW EVENTS;
```

---

## 📝 Summary

**Run in this order:**
1. ✅ `schema.sql` - **START HERE!**
2. ✅ `stored_procedures.sql`
3. ✅ `triggers.sql`
4. ✅ `views.sql`
5. ✅ `patient_views.sql`
6. ✅ `patient_procedures.sql`
7. ✅ `security.sql`
8. ✅ `events.sql`
9. ✅ `seed_data.sql` (optional)

**Remember:** `schema.sql` must be run first - it's the foundation!

