# HIV Patient Care & Treatment Monitoring System

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**A comprehensive database-driven system for managing HIV patient care, treatment monitoring, and clinical operations at Mukono General Hospital ART Clinic, Uganda**

[Features](#-key-features) • [Installation](#-installation) • [Documentation](#-documentation) • [API Reference](#-api-reference) • [Contributing](#-contributing)

</div>

---

## ⚠️ IMPORTANT DISCLAIMER: DUMMY DATA

<div align="center">

**🔴 ALL DATA IN THIS SYSTEM IS SYNTHETIC/DUMMY DATA FOR DEVELOPMENT AND TESTING PURPOSES ONLY 🔴**

</div>

**This system contains NO real patient information, personal health records, or actual clinical data.**

- **All patient records** (747+ patients in seed data) are **fabricated** for demonstration purposes
- **All staff records** (30+ staff members) are **fictional** and do not represent real healthcare workers
- **All clinical data** (visits, lab tests, medications, appointments) is **synthetic** and generated for testing
- **All identifiers** (NIN numbers, patient codes, staff codes) are **fictional** and randomly generated
- **All names, addresses, and contact information** are **dummy data** and do not correspond to real individuals

**This system is intended for:**

- ✅ Academic research and learning
- ✅ System development and testing
- ✅ Database design demonstration
- ✅ Software engineering education

**This system is NOT intended for:**

- ❌ Production use with real patient data
- ❌ Clinical decision-making
- ❌ Storage of actual health records
- ❌ Any real-world healthcare operations

**Before using this system with real data, you MUST:**

1. Remove all dummy/seed data
2. Implement proper data privacy and security measures
3. Comply with local healthcare data protection regulations (e.g., Uganda Data Protection Act)
4. Obtain necessary approvals from healthcare authorities
5. Conduct security audits and penetration testing
6. Implement HIPAA/equivalent compliance measures

**The authors and contributors of this project assume NO responsibility for any misuse of this system or any consequences arising from the use of dummy data in production environments.**

---

## 📋 Table of Contents

- [⚠️ Important Disclaimer](#️-important-disclaimer-dummy-data)
- [Problem Statement](#-problem-statement)
- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Technology Stack](#-technology-stack)
- [Database Schema](#-database-schema)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage Guide](#-usage-guide)
- [API Reference](#-api-reference)
- [Security &amp; Access Control](#-security--access-control)
- [Database Components](#-database-components)
- [Testing &amp; Verification](#-testing--verification)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact &amp; Support](#-contact--support)

---

## 📄 Problem Statement

### The HIV/AIDS Challenge in Uganda

Uganda — a country with an estimated population of about **44 million** in 2023 ([UNIPH][1]) — continues to face a significant public health challenge with HIV/AIDS. According to the latest data from the Uganda AIDS Commission (UAC), approximately **1.49 million people living in Uganda are HIV-positive**, representing a national adult prevalence rate of about **5.1%**. ([Parliament Uganda][2])

Despite progress over the past decades, new infections remain a concern: in recent years Uganda has recorded **tens of thousands of new HIV infections annually** — underscoring that the epidemic is not over. ([Be in the KNOW][3])

### The Problem: Paper-Based Record Keeping

In this context, many health facilities — especially at lower levels (health centers, local clinics) — still rely on **paper-based record keeping** for HIV patient data (clinical visits, lab results, drug refills, adherence, counselling). This manual system imposes serious limitations:

#### Critical Limitations

1. **Fragmented Patient Histories**

   - Patient histories are fragmented or lost, making longitudinal tracking (over months/years) difficult
   - No centralized view of a patient's complete care journey
   - Historical data is often incomplete or inaccessible
2. **Lack of Automated Alerts**

   - Missed appointments, drug refills, or lab tests are not automatically flagged
   - Leads to lapses in treatment adherence or follow-up
   - Critical interventions are delayed or missed entirely
3. **Data Silos**

   - Viral load test results, CD4 counts, comorbid conditions (e.g., opportunistic infections, TB) are stored in separate registries or lab ledgers
   - Makes integrated patient care difficult
   - Clinicians cannot see the full picture of a patient's health status
4. **Informal Tracking**

   - Counselling, psychosocial support, and adherence monitoring are often done in informal notes
   - No centralized tracking of adherence interventions
   - Difficult to measure effectiveness of counseling programs
5. **Inefficient Reporting**

   - Data retrieval for reporting, audits, or research is slow, incomplete, or inaccurate
   - Impedes evidence-based decision making and public health response
   - Delays in identifying trends and outbreaks

### Impact of These Weaknesses

These limitations can lead to:

- ❌ **Treatment Failure** - Incomplete treatment histories prevent optimal care decisions
- ❌ **Drug Resistance** - Poor adherence tracking leads to suboptimal medication management
- ❌ **Poor Viral Suppression** - Delayed interventions for high viral loads
- ❌ **Lost-to-Follow-Up Patients** - No automated tracking of patient engagement
- ❌ **Missed Opportunities** - Critical interventions are delayed or missed
- ❌ **Reduced Quality of Care** - Overall system inefficiencies impact patient outcomes

For a populous country like Uganda with **~1.5 million people living with HIV**, such gaps in care management represent a significant risk to both:

- **Individual patient outcomes** - Poor health outcomes, treatment failure, preventable deaths
- **National HIV control goals** - Viral suppression targets, reduced new infections, better retention in care

### The Solution: Digital HIV Patient Care & Treatment Monitoring System

Therefore, there is a **critical need** for a robust, **digital HIV Patient Care & Treatment Monitoring System** that ensures:

#### Core Requirements

1. **Longitudinal Tracking**

   - Complete tracking of every patient's clinical visits, lab results, ART dispensing, counselling and adherence
   - Historical data accessible in one place
   - Timeline view of patient care journey
2. **Automated Alerts**

   - Automated alerts for missed appointments, overdue viral load tests, drug refills, or high-risk lab results
   - Proactive intervention triggers
   - Real-time notifications for critical events
3. **Integrated Modules**

   - Integration across modules (clinical, lab, pharmacy, counseling) so that data silos are eliminated
   - Single source of truth for patient data
   - Seamless data flow between departments
4. **Secure Access Control**

   - Secure access control (roles for doctors, nurses, lab staff, pharmacists, counsellors) to maintain confidentiality and data integrity
   - Role-based permissions
   - Audit trails for compliance
5. **Reliable Reporting**

   - Reliable reporting capabilities for clinic management, public health authorities, and research
   - Real-time dashboards
   - Export capabilities for HMIS reporting
6. **Improved Outcomes**

   - Improved continuity of care, better adherence, earlier detection of complications
   - Ultimately improved health outcomes for people living with HIV
   - Support for national HIV response goals

### Why This Problem Deserves a Database Project

This problem is particularly well-suited for a comprehensive database solution because:

1. **Massive Scale**

   - **1.49 million people** living with HIV in Uganda
   - Many clinics across the country need this system
   - Requires scalable, efficient data management
2. **Complexity**

   - Multiple data types (demographics, clinical, lab, pharmacy, counselling)
   - Needs relational design, data integrity, security, user roles
   - Requires advanced database concepts (ER/EER, normalization, constraints, stored procedures, user roles)
3. **Real-World Relevance**

   - Improving this system has **direct impact on health outcomes**
   - Aligns with **SDG 3: Good Health and Well‑being**
   - Supports national HIV response goals
   - Addresses a critical public health need
4. **Technical Challenge**

   - Modeling longitudinal data (patient histories over years)
   - Ensuring data privacy and security
   - Designing triggers/alerts for automated interventions
   - Building views/reports for different stakeholders
   - Implementing role-based access control

### Expected Impact

**Despite significant national-level progress**, the **lack of an integrated, digital patient-centered HIV data management system at the facility level** remains a major bottleneck to delivering high-quality care to the ~1.5 million Ugandans living with HIV. This gap undermines efforts toward:

- Treatment adherence
- Viral suppression
- Long-term disease control

**This system addresses this gap urgently** by providing a comprehensive, integrated solution that can be deployed at health facilities across Uganda, ultimately contributing to:

- ✅ Better patient outcomes
- ✅ Improved treatment adherence
- ✅ Enhanced viral suppression rates
- ✅ Reduced lost-to-follow-up rates
- ✅ More efficient healthcare delivery
- ✅ Evidence-based decision making
- ✅ Progress toward national HIV control goals

### References

---

## 🎯 Overview

The **HIV Patient Care & Treatment Monitoring System** is a comprehensive database and API solution designed specifically for **Mukono General Hospital ART Clinic** in Uganda. The system manages the complete lifecycle of HIV patient care, from enrollment through treatment monitoring, adherence tracking, and clinical reporting.

### Purpose

This system addresses critical healthcare management needs in Uganda's HIV treatment programs by:

- **Compliance**: Adhering to Ugandan Ministry of Health (MOH) standards and HMIS reporting requirements
- **Patient Tracking**: Managing patient demographics using Uganda National Identification Numbers (NIN)
- **Treatment Monitoring**: Tracking ART regimens, viral load tests, and adherence metrics
- **Clinical Operations**: Supporting clinical visits, appointments, and counseling sessions
- **Community Programs**: Managing Community ART Groups (CAGs) for decentralized care delivery
- **Automated Alerts**: Generating alerts for high viral loads, missed appointments, and adherence issues
- **Audit & Compliance**: Maintaining comprehensive audit logs for regulatory compliance

### Target Users

- **Clinicians**: Doctors, Clinical Officers, Nurses managing patient care
- **Lab Technicians**: Processing and recording laboratory test results
- **Pharmacists**: Managing medication dispensing and refills
- **Counselors**: Conducting adherence counseling and psychosocial support
- **Records Officers**: Generating reports and maintaining data integrity
- **Administrators**: System oversight and user management
- **Patients**: Self-service access to personal health records

---

## ✨ Key Features

### 🏥 Patient Management

- **Demographic Tracking**: Complete patient information with Uganda NIN integration
- **Enrollment Management**: Track patient enrollment dates and ART initiation
- **Status Tracking**: Monitor patient status (Active, Transferred-Out, LTFU, Dead)
- **Location Hierarchy**: District → Subcounty → Parish → Village tracking for community tracing

### 🔬 Clinical Operations

- **Clinical Visits**: HMIS 031 compliant visit records with vital signs, symptoms, and diagnoses
- **Laboratory Tests**: Comprehensive test management (Viral Load, CD4, HB, Creatinine, Malaria RDT, TB-LAM, Urinalysis)
- **CPHL Integration**: Viral load sample tracking with CPHL sample IDs
- **WHO Staging**: Clinical staging (1-4) for patient assessment

### 💊 Pharmacy Management

- **Regimen Catalog**: Uganda MOH standard ART regimens (First Line, Second Line, Third Line)
- **Dispensing Records**: Track medication dispensing with days supply and refill dates
- **Refill Management**: Automated tracking of medication refills and overdue alerts

### 📅 Appointment & Scheduling

- **Appointment Management**: Schedule, track, and manage patient appointments
- **Status Tracking**: Monitor appointment status (Scheduled, Attended, Missed, Rescheduled, Cancelled)
- **Missed Visit Alerts**: Automated alerts for missed appointments

### 💬 Counseling & Adherence

- **Counseling Sessions**: Record counseling sessions with topics and adherence barriers
- **Adherence Tracking**: Multiple assessment methods (Pill Count, Pharmacy Refill, Self Report, CAG Report, Computed)
- **Adherence Analytics**: Track adherence percentages and identify patients needing support

### 👥 Community ART Groups (CAGs)

- **CAG Management**: Create and manage Community ART Groups for decentralized care
- **Member Tracking**: Track patient membership and roles (Member, Coordinator, Deputy Coordinator)
- **Rotation System**: Record medication pickup rotations for group members
- **Performance Metrics**: Monitor CAG adherence and viral load suppression rates

### 🚨 Automated Alerts

- **High Viral Load**: Critical alerts for viral loads > 1000 copies/mL
- **Overdue VL Tests**: Warnings for patients overdue for viral load testing (>180 days)
- **Missed Appointments**: Alerts for missed scheduled appointments
- **Missed Refills**: Warnings for patients with overdue medication refills
- **Low Adherence**: Alerts for patients with adherence < 85%
- **Severe OI**: Critical alerts for severe opportunistic infections

### 📊 Reporting & Analytics

- **Role-Based Analysis**: Comprehensive analytics tailored to each user role
- **Patient Dashboards**: Complete patient overview with key metrics
- **System Reports**: Activity summaries, demographic reports, and performance metrics
- **Data Verification**: Automated data integrity and consistency checks

### 🔐 Security & Access Control

- **Role-Based Access Control (RBAC)**: Granular permissions based on user roles
- **Database Roles**: 7 distinct roles (Admin, Clinician, Lab, Pharmacy, Counselor, Read-Only, Patient)
- **Audit Logging**: Complete audit trail of all data changes
- **JWT Authentication**: Secure API authentication with JSON Web Tokens

---

## 🏗️ System Architecture

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                       │
│  (Web App, Mobile App, Reporting Tools, Patient Portal)     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ HTTP/REST API
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                  Backend API Server                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Express.js + JWT Authentication + RBAC Middleware   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Route Handlers (Patients, Visits, Lab, Pharmacy)   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Prisma ORM (Database Abstraction Layer)            │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ SQL Queries
                        │
┌───────────────────────▼─────────────────────────────────────┐
│              MySQL 8.0+ Database Server                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Tables (17 core tables)                            │  │
│  │  Views (15+ views for reporting)                    │  │
│  │  Stored Procedures (21 procedures)                   │  │
│  │  Triggers (8 triggers for automation)               │  │
│  │  Events (5 scheduled events)                        │  │
│  │  Roles & Privileges (7 roles)                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Database Design Pattern

The system uses an **Enhanced Entity Relationship (EER) Model** with:

1. **Generalization (Supertype/Subtype)**

   - `person` (supertype) → `patient` and `staff` (subtypes)
   - Eliminates data duplication and ensures consistency
2. **Overlapping Specialization**

   - `staff` can have multiple `roles` simultaneously
   - Enables flexible access control
3. **Disjoint Categorization**

   - Patient status: Active, Transferred-Out, LTFU, Dead (mutually exclusive)
4. **Categorization**

   - Lab test types, alert types, adherence methods

---

## 🛠️ Technology Stack

### Backend

- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.18+
- **ORM**: Prisma 5.7+
- **Authentication**: JSON Web Tokens (JWT)
- **Password Hashing**: bcryptjs
- **CORS**: Enabled for cross-origin requests

### Database

- **RDBMS**: MySQL 8.0+
- **Character Set**: UTF8MB4 (Unicode support)
- **Storage Engine**: InnoDB (ACID compliance)

### Development Tools

- **Package Manager**: npm
- **Database Client**: MySQL Command Line / MySQL Workbench
- **API Testing**: cURL, Postman, or similar

---

## 🗄️ Database Schema

### Core Tables (17)

| Table                  | Description                                 | Key Relationships               |
| ---------------------- | ------------------------------------------- | ------------------------------- |
| `person`             | Supertype for all people (patients & staff) | Root table                      |
| `patient`            | HIV patient records                         | → person (1:1)                 |
| `staff`              | Healthcare staff records                    | → person (1:1)                 |
| `role`               | System access roles                         | → staff_role (many:many)       |
| `staff_role`         | Staff-role assignments                      | Junction table                  |
| `visit`              | Clinical visit records                      | → patient, staff               |
| `lab_test`           | Laboratory test results                     | → patient, visit, staff        |
| `regimen`            | ART regimen catalog                         | → dispense                     |
| `dispense`           | Medication dispensing records               | → patient, regimen, staff      |
| `appointment`        | Appointment scheduling                      | → patient, staff               |
| `counseling_session` | Counseling session records                  | → patient, staff               |
| `cag`                | Community ART Groups                        | → patient (coordinator), staff |
| `patient_cag`        | Patient-CAG memberships                     | Junction table                  |
| `cag_rotation`       | CAG medication pickup rotations             | → cag, patient, dispense       |
| `adherence_log`      | Medication adherence assessments            | → patient                      |
| `alert`              | Automated alerts                            | → patient                      |
| `audit_log`          | Audit trail of data changes                 | → staff                        |

### Key Relationships

- **One-to-One**: person ↔ patient, person ↔ staff
- **One-to-Many**: patient → visits, lab_tests, dispenses, appointments
- **Many-to-Many**: patient ↔ cag (via patient_cag), staff ↔ role (via staff_role)

### Database Statistics

- **Total Tables**: 17
- **Total Views**: 15+
- **Total Stored Procedures**: 21
- **Total Triggers**: 8
- **Total Scheduled Events**: 5
- **Total Roles**: 7
- **Sample Data**: 747+ patients, 30+ staff members (⚠️ **DUMMY DATA** - for development/testing only)

For detailed relationship documentation, see [`database/database_relationships.md`](database/database_relationships.md).

---

## 🚀 Installation

### Prerequisites

- **MySQL 8.0+** installed and running
- **Node.js 18+** and npm installed
- **PowerShell** (Windows) or **Bash** (Linux/Mac) for scripts
- **Git** (optional, for cloning repository)

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd Database-Programming-Research-Project
```

### Step 2: Database Setup

#### Option A: Automated Setup (Recommended)

**Windows (PowerShell):**

```powershell
.\setup-database.ps1
```

**Linux/Mac (Bash):**

```bash
chmod +x setup-database.sh
./setup-database.sh
```

#### Option B: Manual Setup

**Using Combined File (Easiest):**

```bash
mysql -u root -p < database/hiv_patient_care.sql
```

**Using Individual Files (Step-by-Step):**

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS hiv_patient_care;"

# Run files in order
mysql -u root -p hiv_patient_care < database/schema.sql
mysql -u root -p hiv_patient_care < database/triggers.sql
mysql -u root -p hiv_patient_care < database/views.sql
mysql -u root -p hiv_patient_care < database/stored_procedures.sql
mysql -u root -p hiv_patient_care < database/security.sql
mysql -u root -p hiv_patient_care < database/events.sql

# Optional: Load DUMMY/SYNTHETIC sample data (for testing only)
# ⚠️ WARNING: This contains NO real patient data - all data is fabricated for demonstration
mysql -u root -p hiv_patient_care < database/seed_data.sql

# Optional: Verify data integrity
mysql -u root -p hiv_patient_care < database/verify_data.sql
```

> **Note**: Replace `root` with your MySQL username and `-p` will prompt for password.

### Step 3: Backend Setup

```bash
cd backend
npm install
```

### Step 4: Environment Configuration

Create `backend/.env` file:

```env
# Database Connection
DATABASE_URL="mysql://root:your_password@localhost:3306/hiv_patient_care"

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars

# Server Configuration
PORT=3000
NODE_ENV=development

# CORS (optional)
CORS_ORIGIN=http://localhost:3000
```

> **⚠️ Security Warning**: Change `JWT_SECRET` to a strong, random string in production!

### Step 5: Prisma Setup

```bash
cd backend
npx prisma generate
```

### Step 6: Verify Installation

```bash
# Check database tables
mysql -u root -p hiv_patient_care -e "SHOW TABLES;"

# Start backend server
cd backend
npm run dev
```

Server should start on `http://localhost:3000`

---

## ⚙️ Configuration

### Database Configuration

**MySQL Settings** (recommended in `my.cnf` or `my.ini`):

```ini
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone=+00:00
event-scheduler=ON
```

### Backend Configuration

**Environment Variables**:

| Variable         | Description               | Default     | Required |
| ---------------- | ------------------------- | ----------- | -------- |
| `DATABASE_URL` | MySQL connection string   | -           | ✅ Yes   |
| `JWT_SECRET`   | Secret key for JWT tokens | -           | ✅ Yes   |
| `PORT`         | Server port               | 3000        | ❌ No    |
| `NODE_ENV`     | Environment mode          | development | ❌ No    |
| `CORS_ORIGIN`  | Allowed CORS origin       | *           | ❌ No    |

### Role Configuration

Default roles are created automatically. To customize, edit `database/security.sql`.

**Available Roles**:

- `db_admin` - Full system access
- `db_clinician` - Clinical operations
- `db_lab` - Laboratory operations
- `db_pharmacy` - Pharmacy operations
- `db_counselor` - Counseling operations
- `db_readonly` - Read-only access
- `db_patient` - Patient self-service

---

## 📖 Usage Guide

### Starting the System

1. **Start MySQL Server**

   ```bash
   # Windows (if installed as service, it should auto-start)
   # Linux/Mac
   sudo systemctl start mysql
   ```
2. **Start Backend Server**

   ```bash
   cd backend
   npm run dev  # Development mode with auto-reload
   # OR
   npm start    # Production mode
   ```
3. **Access API**

   - Base URL: `http://localhost:3000/api`
   - Health Check: `http://localhost:3000/api/health`

### Authentication

**Login Endpoint:**

```bash
POST /api/auth/login
Content-Type: application/json

{
  "staffCode": "MGH/STAFF/001",
  "password": "password123"
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "staff": {
    "staffCode": "MGH/STAFF/001",
    "person": {
      "firstName": "James",
      "lastName": "Nakato"
    },
    "roles": ["db_clinician"]
  }
}
```

**Using Token:**

```bash
Authorization: Bearer <token>
```

### Common Operations

**Get Patient List:**

```bash
GET /api/patients
Authorization: Bearer <token>
```

**Create Visit:**

```bash
POST /api/visits
Authorization: Bearer <token>
Content-Type: application/json

{
  "patientId": 1,
  "visitDate": "2024-01-15",
  "whoStage": 2,
  "weightKg": 65.5,
  "bp": "120/80"
}
```

**Record Lab Test:**

```bash
POST /api/lab-tests
Authorization: Bearer <token>
Content-Type: application/json

{
  "patientId": 1,
  "testType": "Viral Load",
  "testDate": "2024-01-15",
  "resultNumeric": 450.25,
  "units": "copies/mL",
  "resultStatus": "Completed"
}
```

For complete API documentation, see [API Reference](#-api-reference).

---

## 📡 API Reference

### Base URL

```
http://localhost:3000/api
```

### Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

### Endpoints

#### Authentication

- `POST /api/auth/login` - Staff login
- `POST /api/auth/register` - Register new staff (admin only)
- `GET /api/auth/me` - Get current user info

#### Patients

- `GET /api/patients` - List all patients
- `GET /api/patients/:id` - Get patient details
- `POST /api/patients` - Create new patient
- `PUT /api/patients/:id` - Update patient
- `GET /api/patients/:id/dashboard` - Get patient dashboard

#### Visits

- `GET /api/visits` - List visits
- `GET /api/visits/:id` - Get visit details
- `POST /api/visits` - Create visit
- `PUT /api/visits/:id` - Update visit

#### Lab Tests

- `GET /api/lab-tests` - List lab tests
- `GET /api/lab-tests/:id` - Get test details
- `POST /api/lab-tests` - Record lab test
- `PUT /api/lab-tests/:id` - Update test result

#### Pharmacy

- `GET /api/pharmacy/dispenses` - List dispenses
- `POST /api/pharmacy/dispense` - Record dispense
- `GET /api/pharmacy/regimens` - List regimens
- `GET /api/pharmacy/overdue-refills` - Get overdue refills

#### Appointments

- `GET /api/appointments` - List appointments
- `POST /api/appointments` - Schedule appointment
- `PUT /api/appointments/:id` - Update appointment status

#### Alerts

- `GET /api/alerts` - List alerts
- `GET /api/alerts/active` - Get active alerts
- `PUT /api/alerts/:id/resolve` - Resolve alert

#### CAG (Community ART Groups)

- `GET /api/cag` - List CAGs
- `POST /api/cag` - Create CAG
- `POST /api/cag/:id/add-patient` - Add patient to CAG
- `GET /api/cag/:id/members` - Get CAG members

#### Adherence

- `GET /api/adherence` - List adherence records
- `POST /api/adherence` - Record adherence assessment

#### Counseling

- `GET /api/counseling` - List counseling sessions
- `POST /api/counseling` - Create counseling session

For detailed endpoint documentation with request/response examples, see [`backend/README_AUTH.md`](backend/README_AUTH.md).

---

## 🔐 Security & Access Control

### Role-Based Access Control (RBAC)

The system implements granular access control through database roles:

| Role                   | Permissions                                                                         | Use Case                           |
| ---------------------- | ----------------------------------------------------------------------------------- | ---------------------------------- |
| **db_admin**     | Full system access (SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP)            | System administrators              |
| **db_clinician** | Read all, write to visits, appointments, patients, lab_tests, adherence_log, alerts | Doctors, Clinical Officers, Nurses |
| **db_lab**       | Read patient/staff data, write lab_test results                                     | Lab Technicians                    |
| **db_pharmacy**  | Read patient/regimen data, write dispense records                                   | Pharmacists                        |
| **db_counselor** | Read patient data, write counseling_session, adherence_log, appointments            | Counselors                         |
| **db_readonly**  | Read-only access to all tables and views                                            | Records Officers, Reporters        |
| **db_patient**   | Read-only access to own data via views and procedures                               | Patient self-service               |

### Default Users (from DUMMY seed data)

> **⚠️ DISCLAIMER**: These are **TEST ACCOUNTS** created from synthetic/dummy data. All user credentials, staff records, and associated data are **FABRICATED FOR TESTING PURPOSES ONLY**. Do not use these accounts in production.

| Username                       | Password             | Role         | Description                  |
| ------------------------------ | -------------------- | ------------ | ---------------------------- |
| `nsubuga@localhost`          | `admin123`         | db_admin     | System Administrator (DUMMY) |
| `doctor1@localhost`          | `doctor123`        | db_clinician | Clinician (DUMMY)            |
| `lab_tech1@localhost`        | `lab_tech123`      | db_lab       | Lab Technician (DUMMY)       |
| `pharmacist1@localhost`      | `pharmacist1`      | db_pharmacy  | Pharmacist (DUMMY)           |
| `counselor1@localhost`       | `counselor1`       | db_counselor | Counselor (DUMMY)            |
| `records_officer1@localhost` | `records_officer1` | db_readonly  | Records Officer (DUMMY)      |

> **⚠️ Security Warning**:
>
> - These are **TEST CREDENTIALS ONLY** - all data is synthetic
> - **NEVER** use these credentials in production
> - **ALWAYS** change default passwords before production deployment
> - **ALWAYS** create new user accounts for real staff members

### Audit Logging

All data modifications are automatically logged in the `audit_log` table:

- **Action**: INSERT, UPDATE, DELETE
- **Table**: Affected table name
- **Record ID**: Primary key of modified record
- **Details**: Description of change
- **Staff ID**: User who made the change (if available)
- **Action Time**: Timestamp of change

### Data Encryption

- **Passwords**: Hashed using bcryptjs (salt rounds: 10)
- **JWT Tokens**: Signed with HMAC SHA-256
- **Database**: MySQL SSL/TLS recommended for production

---

## 🗃️ Database Components

### Views (15+)

Views provide simplified access to complex queries:

**Clinical Views:**

- `v_active_patients_summary` - Active patients with key metrics
- `v_patient_care_timeline` - Chronological patient events
- `v_viral_load_monitoring` - VL status and test scheduling
- `v_adherence_summary` - Latest adherence assessments

**CAG Views:**

- `v_cag_summary` - CAG overview with member counts
- `v_cag_members` - Active CAG members
- `v_cag_rotation_history` - CAG rotation records
- `v_cag_performance` - CAG performance metrics

**Patient Self-Service Views:**

- `v_patient_dashboard` - Complete patient overview
- `v_patient_visit_history` - Clinical visit history
- `v_patient_lab_history` - Lab test results
- `v_patient_medication_history` - Medication records
- `v_patient_appointments` - Appointment schedule
- `v_patient_adherence_history` - Adherence assessments
- `v_patient_alerts` - Patient alerts and notifications
- `v_patient_progress_timeline` - Complete care timeline

**System Views:**

- `v_active_alerts_summary` - All unresolved alerts
- `v_staff_with_roles` - Staff with assigned roles

### Stored Procedures (21)

**Patient Self-Service:**

- `sp_patient_dashboard` - Get patient dashboard data
- `sp_patient_visits` - Get visit history
- `sp_patient_lab_tests` - Get lab test history
- `sp_patient_medications` - Get medication history
- `sp_patient_appointments` - Get appointments
- `sp_patient_adherence` - Get adherence history
- `sp_patient_alerts` - Get patient alerts
- `sp_patient_progress_timeline` - Get care timeline
- `sp_patient_next_appointment` - Get next appointment
- `sp_patient_summary_stats` - Get summary statistics

**Clinical Operations:**

- `sp_compute_adherence` - Calculate adherence percentage
- `sp_check_overdue_vl` - Check for overdue VL tests
- `sp_mark_missed_appointments` - Mark missed appointments
- `sp_update_patient_status_ltfu` - Update LTFU status
- `sp_check_missed_refills` - Check for missed refills

**CAG Management:**

- `sp_cag_add_patient` - Add patient to CAG
- `sp_cag_remove_patient` - Remove patient from CAG
- `sp_cag_record_rotation` - Record CAG rotation
- `sp_cag_get_members` - Get CAG members
- `sp_cag_get_rotations` - Get rotation history
- `sp_cag_get_statistics` - Get CAG statistics

### Triggers (8)

**Alert Triggers:**

- `trg_lab_test_high_vl_alert` - Creates alert on high VL (>1000)
- `trg_lab_test_high_vl_alert_update` - Creates alert on VL update
- `trg_appointment_missed_alert` - Creates alert on missed appointment
- `trg_adherence_low_alert` - Creates alert on low adherence (<85%)

**Audit Triggers:**

- `trg_patient_audit_insert` - Logs patient creation
- `trg_patient_audit_update` - Logs patient updates
- `trg_visit_audit_insert` - Logs visit creation
- `trg_lab_test_audit_insert` - Logs lab test creation
- `trg_lab_test_audit_update` - Logs lab test updates
- `trg_dispense_audit_insert` - Logs dispense creation

### Scheduled Events (5)

**Daily Events:**

- `evt_daily_check_overdue_vl` - Checks for overdue VL tests (8 AM)
- `evt_daily_check_missed_appointments` - Marks missed appointments (8 AM)
- `evt_daily_check_missed_refills` - Checks for missed refills (8 AM)
- `evt_daily_update_ltfu` - Updates LTFU status (7 AM)

**Weekly Events:**

- `evt_weekly_compute_adherence` - Computes adherence for all patients (9 AM, weekly)

> **Note**: Events require `event_scheduler = ON` in MySQL configuration.

---

## 🧪 Testing & Verification

### Data Verification

After loading **DUMMY seed data**, verify data integrity:

```bash
mysql -u root -p hiv_patient_care < database/verify_data.sql
```

> **⚠️ Note**: This verification is for **SYNTHETIC/DUMMY DATA ONLY**. All records are fabricated for testing purposes.

This script checks:

- ✅ Table record counts
- ✅ Foreign key integrity
- ✅ Data consistency
- ✅ Uniqueness constraints
- ✅ Enum value validity
- ✅ Referential data completeness
- ✅ Statistical summaries

### Role-Based Analysis

Test role-based access and analysis queries:

```bash
# Login as different users and run analysis
mysql -u doctor1 -pdoctor123 hiv_patient_care < database/role_based_analysis.sql
mysql -u lab_tech1 -plab_tech123 hiv_patient_care < database/role_based_analysis.sql
mysql -u pharmacist1 -ppharmacist1 hiv_patient_care < database/role_based_analysis.sql
```

### API Testing

**Health Check:**

```bash
curl http://localhost:3000/api/health
```

**Login Test:**

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"staffCode":"MGH/STAFF/001","password":"password123"}'
```

**Get Patients (with token):**

```bash
curl http://localhost:3000/api/patients \
  -H "Authorization: Bearer <your-token>"
```

### Performance Testing

**Check Database Performance:**

```sql
-- View table sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'hiv_patient_care'
ORDER BY size_mb DESC;

-- Check index usage
SHOW INDEX FROM patient;
SHOW INDEX FROM visit;
```

---

## 🔧 Troubleshooting

### Common Issues

#### Database Connection Errors

**Error**: `ER_ACCESS_DENIED_ERROR` or `ECONNREFUSED`

**Solutions**:

1. Verify MySQL is running:

   ```bash
   # Windows
   net start MySQL80

   # Linux/Mac
   sudo systemctl status mysql
   ```
2. Check credentials in `.env`:

   ```env
   DATABASE_URL="mysql://username:password@localhost:3306/hiv_patient_care"
   ```
3. Verify database exists:

   ```sql
   SHOW DATABASES;
   USE hiv_patient_care;
   SHOW TABLES;
   ```

#### Foreign Key Constraint Errors

**Error**: `Cannot add or update a child row: a foreign key constraint fails`

**Solutions**:

1. Ensure parent records exist (e.g., person before patient)
2. Check data insertion order matches schema dependencies
3. Verify foreign key values are valid

#### Trigger Errors

**Error**: `Trigger execution failed`

**Solutions**:

1. Check trigger definitions in `database/triggers.sql`
2. Verify referenced tables exist
3. Check trigger syntax for MySQL 8.0+ compatibility

#### Event Scheduler Not Running

**Error**: Events not executing

**Solutions**:

1. Enable event scheduler:

   ```sql
   SET GLOBAL event_scheduler = ON;
   ```
2. Check event status:

   ```sql
   SHOW EVENTS;
   SELECT * FROM information_schema.EVENTS;
   ```

#### JWT Authentication Errors

**Error**: `Invalid token` or `Token expired`

**Solutions**:

1. Verify `JWT_SECRET` in `.env` matches between restarts
2. Check token expiration time
3. Ensure token is sent in Authorization header:
   ```
   Authorization: Bearer <token>
   ```

#### Prisma Errors

**Error**: `PrismaClientInitializationError`

**Solutions**:

1. Regenerate Prisma client:

   ```bash
   cd backend
   npx prisma generate
   ```
2. Verify `DATABASE_URL` in `.env`
3. Check database connection:

   ```bash
   npx prisma db pull
   ```

### Performance Issues

**Slow Queries:**

- Check indexes: `SHOW INDEX FROM <table>;`
- Analyze query execution: `EXPLAIN SELECT ...;`
- Review table statistics: `ANALYZE TABLE <table>;`

**Large Dataset:**

- Consider partitioning for large tables
- Optimize indexes based on query patterns
- Use views for complex queries

### Getting Help

1. **Check Logs**: Review MySQL error logs and application logs
2. **Verify Setup**: Run `database/verify_data.sql` to check data integrity
3. **Review Documentation**: Check [`SETUP_ORDER.md`](SETUP_ORDER.md) and [`QUICK_START.md`](QUICK_START.md)
4. **Database Relationships**: See [`database/database_relationships.md`](database/database_relationships.md)

---

## 📁 Project Structure

```
Database-Programming-Research-Project/
│
├── backend/                          # Node.js API Server
│   ├── src/
│   │   ├── server.js                # Server entry point
│   │   ├── app.js                   # Express app configuration
│   │   ├── middleware/
│   │   │   └── auth.js              # JWT authentication middleware
│   │   └── routes/                  # API route handlers
│   │       ├── auth.js              # Authentication routes
│   │       ├── patients.js         # Patient routes
│   │       ├── visits.js            # Visit routes
│   │       ├── lab-tests.js         # Lab test routes
│   │       ├── pharmacy.js          # Pharmacy routes
│   │       ├── appointments.js      # Appointment routes
│   │       ├── alerts.js            # Alert routes
│   │       ├── cag.js               # CAG routes
│   │       ├── adherence.js          # Adherence routes
│   │       ├── counseling.js        # Counseling routes
│   │       ├── staff.js             # Staff routes
│   │       └── regimens.js          # Regimen routes
│   ├── prisma/
│   │   └── schema.prisma            # Prisma schema definition
│   ├── package.json                 # Node.js dependencies
│   └── README_AUTH.md               # Authentication documentation
│
├── database/                         # Database SQL Files
│   ├── hiv_patient_care.sql         # Combined complete setup file
│   ├── schema.sql                   # Database schema (tables)
│   ├── triggers.sql                 # Database triggers
│   ├── views.sql                    # Database views
│   ├── stored_procedures.sql        # Stored procedures
│   ├── events.sql                   # Scheduled events
│   ├── security.sql                 # Roles and privileges
│   ├── seed_data.sql                # ⚠️ DUMMY DATA - Sample data (747+ patients, testing only)
│   ├── verify_data.sql              # Data verification script
│   ├── role_based_analysis.sql      # Role-based analysis queries
│   └── database_relationships.md    # Foreign key documentation
│
├── docs/                             # Documentation
│   ├── DOCUMENTATION.md             # Complete system documentation
│   ├── PATIENT_SELF_SERVICE.md      # Patient portal documentation
│   └── eer_diagram.md               # EER diagram documentation
│
├── eerd/                             # EER Diagram Images
│   ├── eerd.png
│   ├── eerd1.png
│   ├── eerd2.png
│   ├── eerd3.png
│   └── eerd4.png
│
├── setup-database.ps1                # Automated database setup (PowerShell)
├── SETUP_ORDER.md                    # Database setup order guide
├── QUICK_START.md                    # Quick start guide
└── README.md                         # This file
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Contribution Process

1. **Fork the Repository**
2. **Create a Feature Branch**: `git checkout -b feature/your-feature-name`
3. **Make Changes**: Follow coding standards and add tests
4. **Commit Changes**: Use descriptive commit messages
5. **Push to Branch**: `git push origin feature/your-feature-name`
6. **Create Pull Request**: Provide detailed description of changes

### Coding Standards

- **SQL**: Follow MySQL 8.0+ syntax, use consistent naming conventions
- **JavaScript**: Follow ESLint configuration, use async/await for async operations
- **Documentation**: Update README and relevant docs for new features
- **Testing**: Add tests for new functionality

### Areas for Contribution

- 🐛 **Bug Fixes**: Report and fix bugs
- ✨ **New Features**: Add requested features
- 📚 **Documentation**: Improve documentation clarity
- 🧪 **Tests**: Add test coverage
- 🎨 **UI/UX**: Improve user interface (if applicable)
- ⚡ **Performance**: Optimize queries and code

---

## 📄 License

This project is licensed under the **MIT License**.

See `LICENSE` file for details.

---

## 📞 Contact & Support

### Project Information

- **Project Name**: HIV Patient Care & Treatment Monitoring System
- **Institution**: Mukono General Hospital ART Clinic
- **Location**: Uganda
- **Version**: 1.0.0

### Support Resources

- **Documentation**: See [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md)
- **Quick Start**: See [`QUICK_START.md`](QUICK_START.md)
- **Setup Guide**: See [`SETUP_ORDER.md`](SETUP_ORDER.md)
- **Database Relationships**: See [`database/database_relationships.md`](database/database_relationships.md)

### Reporting Issues

When reporting issues, please include:

- **Environment**: MySQL version, Node.js version, OS
- **Steps to Reproduce**: Detailed steps
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Error Messages**: Full error messages/logs
- **Screenshots**: If applicable

---

## 🙏 Acknowledgments

- **Uganda Ministry of Health** - For standards and guidelines
- **Mukono General Hospital** - For requirements and testing
- **MySQL Community** - For excellent database platform
- **Node.js Community** - For robust runtime and ecosystem

---

<div align="center">

**Built for improving HIV patient care in Uganda(Academic purposes)**

[⬆ Back to Top](#-table-of-contents)

</div>

[1]: https://uniph.go.ug/trends-and-distribution-of-hiv-incidence-among-children-aged-0-14-years-uganda-2015-2023/
[2]: https://www.parliament.go.ug/news/3576/uganda-aids-commission-needs-shs300-billion-bridge-hiv-funding-gap
[3]: https://www.beintheknow.org/understanding-hiv-epidemic/data/glance-hiv-uganda
