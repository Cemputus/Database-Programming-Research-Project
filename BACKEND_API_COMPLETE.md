# Backend API Implementation - Complete
## HIV Patient Care & Treatment Monitoring System

**Status:** ✅ **100% COMPLETE** (All routes implemented)

---

## ✅ All Routes Implemented

### 1. Authentication Routes (`auth.js`) ✅
- `POST /api/auth/login` - Staff login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user
- `POST /api/auth/change-password` - Change password
- `GET /api/auth/roles` - Get all roles

### 2. Patient Routes (`patients.js`) ✅
- `GET /api/patients` - Get all patients (with pagination, filtering)
- `GET /api/patients/:id` - Get patient by ID
- `POST /api/patients` - Create new patient (requires `db_clinician` or `db_admin`)
- `PUT /api/patients/:id` - Update patient (requires `db_clinician` or `db_admin`)
- `GET /api/patients/:id/timeline` - Get patient care timeline

### 3. Visit Routes (`visits.js`) ✅
- `GET /api/visits` - Get all visits (with filtering)
- `GET /api/visits/:id` - Get visit by ID
- `POST /api/visits` - Create new visit (requires `db_clinician` or `db_admin`)
- `PUT /api/visits/:id` - Update visit (requires `db_clinician` or `db_admin`)

### 4. Lab Test Routes (`lab-tests.js`) ✅
- `GET /api/lab-tests` - Get all lab tests (with filtering)
- `GET /api/lab-tests/:id` - Get lab test by ID
- `POST /api/lab-tests` - Create new lab test (requires `db_lab`, `db_clinician`, or `db_admin`)
- `PUT /api/lab-tests/:id` - Update lab test (requires `db_lab`, `db_clinician`, or `db_admin`)
- `GET /api/lab-tests/patient/:patientId/viral-load` - Get viral load history

### 5. Pharmacy Routes (`pharmacy.js`) ✅ **NEW**
- `GET /api/pharmacy/dispenses` - Get all dispenses
- `GET /api/pharmacy/dispenses/:id` - Get dispense by ID
- `POST /api/pharmacy/dispenses` - Create new dispense (requires `db_pharmacy` or `db_admin`)
- `PUT /api/pharmacy/dispenses/:id` - Update dispense (requires `db_pharmacy` or `db_admin`)
- `GET /api/pharmacy/dispenses/patient/:patientId` - Get patient's dispense history
- `GET /api/pharmacy/overdue-refills` - Get patients with overdue refills

### 6. Appointment Routes (`appointments.js`) ✅ **NEW**
- `GET /api/appointments` - Get all appointments
- `GET /api/appointments/:id` - Get appointment by ID
- `POST /api/appointments` - Create new appointment (requires `db_clinician`, `db_counselor`, or `db_admin`)
- `PUT /api/appointments/:id` - Update appointment (requires `db_clinician`, `db_counselor`, or `db_admin`)
- `PUT /api/appointments/:id/mark-attended` - Mark appointment as attended
- `GET /api/appointments/patient/:patientId` - Get patient's appointments
- `GET /api/appointments/missed` - Get missed appointments

### 7. Counseling Routes (`counseling.js`) ✅ **NEW**
- `GET /api/counseling` - Get all counseling sessions
- `GET /api/counseling/:id` - Get counseling session by ID
- `POST /api/counseling` - Create new counseling session (requires `db_counselor` or `db_admin`)
- `PUT /api/counseling/:id` - Update counseling session (requires `db_counselor` or `db_admin`)
- `GET /api/counseling/patient/:patientId` - Get patient's counseling sessions

### 8. Alert Routes (`alerts.js`) ✅ **NEW**
- `GET /api/alerts` - Get all alerts
- `GET /api/alerts/:id` - Get alert by ID
- `GET /api/alerts/patient/:patientId` - Get patient's alerts
- `GET /api/alerts/active` - Get all active (unresolved) alerts
- `PUT /api/alerts/:id/resolve` - Resolve alert (requires `db_clinician`, `db_counselor`, or `db_admin`)
- `PUT /api/alerts/:id/unresolve` - Unresolve alert (requires `db_clinician`, `db_counselor`, or `db_admin`)

### 9. Adherence Routes (`adherence.js`) ✅ **NEW**
- `GET /api/adherence` - Get all adherence logs
- `GET /api/adherence/:id` - Get adherence log by ID
- `POST /api/adherence` - Create new adherence log (requires `db_clinician`, `db_counselor`, or `db_admin`)
- `PUT /api/adherence/:id` - Update adherence log (requires `db_clinician`, `db_counselor`, or `db_admin`)
- `GET /api/adherence/patient/:patientId` - Get patient's adherence history
- `POST /api/adherence/compute/:patientId` - Compute adherence for patient (requires `db_clinician` or `db_admin`)

### 10. Staff Routes (`staff.js`) ✅ **NEW**
- `GET /api/staff` - Get all staff
- `GET /api/staff/:id` - Get staff by ID
- `POST /api/staff` - Create new staff (requires `db_admin`)
- `PUT /api/staff/:id` - Update staff (requires `db_admin`)
- `GET /api/staff/:id/roles` - Get staff roles
- `POST /api/staff/:id/roles` - Assign roles to staff (requires `db_admin`)

### 11. Regimen Routes (`regimens.js`) ✅ **NEW**
- `GET /api/regimens` - Get all regimens
- `GET /api/regimens/:id` - Get regimen by ID
- `POST /api/regimens` - Create new regimen (requires `db_admin`)
- `PUT /api/regimens/:id` - Update regimen (requires `db_admin`)
- `GET /api/regimens/line/:line` - Get regimens by line (First Line, Second Line, Third Line)

### 12. CAG Routes (`cag.js`) ✅ **NEW**
- `GET /api/cag` - Get all CAGs
- `GET /api/cag/:id` - Get CAG by ID
- `GET /api/cag/:id/members` - Get CAG members
- `GET /api/cag/:id/rotations` - Get CAG rotation history
- `GET /api/cag/:id/statistics` - Get CAG statistics
- `POST /api/cag/:id/add-member` - Add patient to CAG (requires `db_clinician` or `db_admin`)
- `POST /api/cag/:id/remove-member` - Remove patient from CAG (requires `db_clinician` or `db_admin`)
- `POST /api/cag/:id/rotation` - Record CAG rotation (requires `db_pharmacy` or `db_admin`)
- `PUT /api/cag/:id/coordinator` - Set CAG coordinator (requires `db_clinician` or `db_admin`)

---

## 📊 Route Statistics

- **Total Route Files:** 13
- **Total Endpoints:** 70+
- **Public Routes:** 2 (`/api/health`, `/api/auth/*`)
- **Protected Routes:** 68+ (all require authentication)
- **Role-Based Authorization:** All write operations protected

---

## 🔐 Authentication & Authorization

### Authentication
- All routes (except `/api/health` and `/api/auth/*`) require JWT authentication
- Token passed in `Authorization: Bearer <token>` header
- Token expires after 8 hours

### Role-Based Access Control

**Read Operations:**
- All authenticated users can read data

**Write Operations:**
- **Patients:** `db_clinician`, `db_admin`
- **Visits:** `db_clinician`, `db_admin`
- **Lab Tests:** `db_lab`, `db_clinician`, `db_admin`
- **Pharmacy/Dispenses:** `db_pharmacy`, `db_admin`
- **Appointments:** `db_clinician`, `db_counselor`, `db_admin`
- **Counseling:** `db_counselor`, `db_admin`
- **Alerts:** `db_clinician`, `db_counselor`, `db_admin`
- **Adherence:** `db_clinician`, `db_counselor`, `db_admin`
- **Staff:** `db_admin` only
- **Regimens:** `db_admin` only
- **CAG:** `db_clinician`, `db_admin` (management), `db_pharmacy` (rotations)

---

## ✅ Features Implemented

### Common Features Across All Routes
- ✅ Pagination support
- ✅ Filtering and search
- ✅ Error handling
- ✅ Input validation
- ✅ Related data inclusion (with `include` options)
- ✅ Proper HTTP status codes
- ✅ Consistent response format

### Special Features
- ✅ Patient timeline aggregation
- ✅ Overdue refills detection
- ✅ Missed appointments tracking
- ✅ Active alerts filtering
- ✅ Adherence computation via stored procedure
- ✅ CAG statistics and performance metrics
- ✅ Role assignment and management

---

## 📁 File Structure

```
backend/src/
├── middleware/
│   └── auth.js          # Authentication & authorization middleware
├── routes/
│   ├── index.js         # Route aggregator
│   ├── auth.js          # Authentication routes
│   ├── patients.js      # Patient routes
│   ├── visits.js        # Visit routes
│   ├── lab-tests.js     # Lab test routes
│   ├── pharmacy.js      # Pharmacy/dispense routes
│   ├── appointments.js  # Appointment routes
│   ├── counseling.js    # Counseling session routes
│   ├── alerts.js        # Alert routes
│   ├── adherence.js     # Adherence tracking routes
│   ├── staff.js         # Staff management routes
│   ├── regimens.js      # Regimen catalog routes
│   └── cag.js           # CAG management routes
├── app.js               # Express app configuration
└── server.js            # Server entry point
```

---

## 🎯 API Coverage

### Database Tables Covered
- ✅ `person` (via patient/staff routes)
- ✅ `patient` ✅
- ✅ `staff` ✅
- ✅ `visit` ✅
- ✅ `lab_test` ✅
- ✅ `regimen` ✅
- ✅ `dispense` ✅
- ✅ `appointment` ✅
- ✅ `counseling_session` ✅
- ✅ `adherence_log` ✅
- ✅ `alert` ✅
- ✅ `cag` ✅
- ✅ `patient_cag` ✅
- ✅ `cag_rotation` ✅
- ✅ `role` ✅
- ✅ `staff_role` ✅

### Stored Procedures Integrated
- ✅ `sp_compute_adherence` (via adherence route)
- ✅ `sp_cag_add_patient` (via CAG route)
- ✅ `sp_cag_remove_patient` (via CAG route)
- ✅ `sp_cag_set_coordinator` (via CAG route)
- ✅ `sp_cag_record_rotation` (via CAG route)

---

## 🚀 Next Steps

1. **Install Dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Set Environment Variables:**
   - Copy `.env.example` to `.env`
   - Update `JWT_SECRET` and `DATABASE_URL`

3. **Start Server:**
   ```bash
   npm run dev  # Development
   npm start    # Production
   ```

4. **Test API:**
   - Login: `POST /api/auth/login`
   - Use token in subsequent requests

---

## ✅ Status: COMPLETE

**All backend API routes are now implemented and ready for use!**

- ✅ 13 route files
- ✅ 70+ endpoints
- ✅ Full CRUD operations
- ✅ Authentication & RBAC
- ✅ Error handling
- ✅ Input validation
- ✅ Pagination & filtering

---

**End of Backend API Documentation**



