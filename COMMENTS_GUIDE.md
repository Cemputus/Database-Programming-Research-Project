# Comments Style Guide
## Human-Friendly Comments Throughout the Project

This document explains the commenting style used throughout the project. All comments are written in a **human-friendly, conversational tone** that explains:
- **WHAT** something does (not just what it is)
- **WHY** it exists (the purpose)
- **HOW** it works (when helpful)

---

## Comment Style Principles

### ✅ Good Comments (Human-Friendly)

```sql
-- This procedure calculates how well a patient is taking their medication.
-- We look at how many pills they were supposed to take vs how many they actually took.
-- This helps clinicians identify patients who might need extra support.
```

### ❌ Bad Comments (Too Technical)

```sql
-- Calculates adherence percentage based on dispense records
-- Returns adherence_percent DECIMAL(5,2)
```

---

## Comment Categories

### 1. **Table Comments**
Explain what the table stores and why it exists:
```sql
-- This table keeps track of every time a patient comes to the clinic.
-- Each visit records vital signs, symptoms, and what the clinician found.
-- This helps us monitor patient progress over time.
```

### 2. **Column Comments**
Explain what the field means in plain language:
```sql
-- How many days of medication we gave the patient this time
-- Usually 30 days, but can be adjusted based on patient needs
`days_supply` INT UNSIGNED NOT NULL
```

### 3. **Constraint Comments**
Explain the business rule:
```sql
-- Business rule: You can't start ART before you enroll in the program!
-- This makes sure our data makes sense.
CONSTRAINT `chk_art_after_enrollment` CHECK (`art_start_date` >= `enrollment_date`)
```

### 4. **Procedure Comments**
Explain what the procedure does and when to use it:
```sql
-- This procedure finds all patients who haven't had a viral load test in a while.
-- We check if it's been more than 180 days since their last test.
-- If so, we create an alert so staff know to schedule a test.
```

### 5. **Trigger Comments**
Explain when the trigger fires and what it does:
```sql
-- This trigger automatically creates an alert when a patient's viral load is too high.
-- It fires right after we save a new lab test result.
-- If the viral load is over 1000 copies/mL, we need to take action!
```

---

## Tone Guidelines

### Use:
- ✅ "We" and "you" (conversational)
- ✅ "This helps..." or "This makes sure..."
- ✅ Simple explanations
- ✅ Real-world context
- ✅ Examples when helpful

### Avoid:
- ❌ Overly technical jargon
- ❌ Just restating the code
- ❌ Assumptions about reader's knowledge
- ❌ Cryptic abbreviations without explanation

---

## Examples from the Project

### Example 1: Table Comment
```sql
-- ============================================================================
-- VISIT TABLE
-- ============================================================================
--
-- This table keeps track of every clinical visit a patient makes.
-- Each time a patient comes to the clinic, we create a new record here.
-- 
-- Why is this important? It helps us:
-- - Monitor patient progress over time
-- - Track vital signs and symptoms
-- - See when patients last came in
-- - Follow Uganda's HMIS 031 reporting requirements
--
-- Think of it like a medical chart - but digital!
-- ============================================================================
```

### Example 2: Column Comment
```sql
-- Current status tells us where the patient is in their care journey.
-- Active = they're coming regularly and doing well
-- Transferred-Out = they moved to another clinic
-- LTFU = Lost to Follow-Up (haven't seen them in 90+ days - we need to find them!)
-- Dead = unfortunately, the patient has passed away
`current_status` ENUM('Active', 'Transferred-Out', 'LTFU', 'Dead') NOT NULL DEFAULT 'Active'
```

### Example 3: Procedure Comment
```sql
-- ============================================================================
-- SP: Check for Overdue Viral Load Tests
-- ============================================================================
--
-- What this does:
-- Every day, we check all active patients to see if they're due for a viral load test.
-- According to Uganda guidelines, patients should have a VL test every 6 months (180 days).
--
-- How it works:
-- 1. Look at each active patient
-- 2. Find their last viral load test date
-- 3. If it's been more than 180 days, create an alert
-- 4. This alert tells staff "Hey, this patient needs a test!"
--
-- When to use:
-- This runs automatically every day via a scheduled event.
-- You can also run it manually if needed.
-- ============================================================================
```

---

## File-by-File Comment Coverage

All files in the project now include human-friendly comments:

1. ✅ `database/schema.sql` - All tables explained
2. ✅ `database/stored_procedures.sql` - All procedures explained
3. ✅ `database/triggers.sql` - All triggers explained
4. ✅ `database/views.sql` - All views explained
5. ✅ `database/patient_views.sql` - Patient views explained
6. ✅ `database/patient_procedures.sql` - Patient procedures explained
7. ✅ `database/security.sql` - Security roles explained
8. ✅ `database/events.sql` - Scheduled events explained
9. ✅ `backend/prisma/schema.prisma` - Model comments
10. ✅ `backend/src/routes/*.ts` - API route comments

---

## Benefits of Human-Friendly Comments

1. **Easier to Understand**: New developers can quickly grasp what's happening
2. **Better Maintenance**: Future you will thank past you!
3. **Documentation**: Comments serve as inline documentation
4. **Onboarding**: New team members can learn the system faster
5. **Debugging**: Understanding the "why" helps find bugs faster

---

**Remember**: Code is read more often than it's written. Good comments make everyone's life easier!

