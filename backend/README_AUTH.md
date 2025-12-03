# Authentication & RBAC Implementation
## HIV Patient Care & Treatment Monitoring System

---

## Overview

This system implements JWT-based authentication and Role-Based Access Control (RBAC) for the API.

---

## Features

### ✅ Authentication
- JWT-based token authentication
- Password hashing with bcrypt
- Token expiration (8 hours)
- Secure login/logout endpoints

### ✅ RBAC (Role-Based Access Control)
- Database roles mapped to API permissions
- Middleware for route protection
- Role-based authorization checks
- Support for multiple roles per staff member

---

## Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

New dependencies added:
- `jsonwebtoken` - JWT token generation/verification
- `bcryptjs` - Password hashing

### 2. Environment Variables

Create a `.env` file in the `backend` directory:

```env
JWT_SECRET=your-super-secret-jwt-key-change-in-production
DATABASE_URL="mysql://user:password@localhost:3306/hiv_patient_care"
PORT=3000
NODE_ENV=development
```

**Important:** Change `JWT_SECRET` in production!

---

## API Endpoints

### Authentication Endpoints

#### POST /api/auth/login
Login with staff code and password.

**Request:**
```json
{
  "staffCode": "MGH/STAFF/001",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "staff": {
    "staffId": 1,
    "staffCode": "MGH/STAFF/001",
    "name": "John Doe",
    "cadre": "Doctor",
    "roles": ["db_clinician", "db_admin"]
  }
}
```

#### POST /api/auth/logout
Logout (client-side token removal).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Logout successful"
}
```

#### GET /api/auth/me
Get current authenticated user information.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "staffId": 1,
  "staffCode": "MGH/STAFF/001",
  "name": "John Doe",
  "email": null,
  "phone": "+256700000000",
  "cadre": "Doctor",
  "moHRegistrationNo": "MOH/12345",
  "active": true,
  "roles": ["db_clinician", "db_admin"]
}
```

#### POST /api/auth/change-password
Change password (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123"
}
```

#### GET /api/auth/roles
Get all available roles (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

---

## Protected Routes

All routes except `/api/health` and `/api/auth/*` require authentication.

### Using Authentication

Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### Role-Based Access

Routes are protected with role-based authorization:

- **Patients:**
  - GET: All authenticated users
  - POST/PUT: `db_clinician` or `db_admin` only

- **Visits:**
  - GET: All authenticated users
  - POST/PUT: `db_clinician` or `db_admin` only

- **Lab Tests:**
  - GET: All authenticated users
  - POST/PUT: `db_lab`, `db_clinician`, or `db_admin` only

---

## Database Roles

The system uses these database roles (from `security.sql`):

1. **db_admin** - Full access to everything
2. **db_clinician** - Clinical operations (patients, visits, appointments)
3. **db_lab** - Laboratory operations (lab tests)
4. **db_pharmacy** - Pharmacy operations (dispenses)
5. **db_counselor** - Counseling operations
6. **db_readonly** - Read-only access
7. **db_patient** - Patient self-service (read own data)

---

## Middleware

### authenticate
Verifies JWT token and attaches staff/roles to request.

```javascript
const { authenticate } = require('./middleware/auth');

router.get('/protected', authenticate, (req, res) => {
  // req.staff - Staff object
  // req.roles - Array of role names
});
```

### authorize(...roles)
Checks if user has required role(s).

```javascript
const { authorize } = require('./middleware/auth');

// Require clinician or admin
router.post('/patients', authorize('db_clinician', 'db_admin'), handler);
```

### authorizeAny(...roles)
Checks if user has any of the required roles (OR logic).

```javascript
const { authorizeAny } = require('./middleware/auth');

router.get('/data', authorizeAny('db_clinician', 'db_lab'), handler);
```

### optionalAuth
Optional authentication - doesn't fail if no token.

```javascript
const { optionalAuth } = require('./middleware/auth');

router.get('/public', optionalAuth, handler);
// req.staff and req.roles available if token provided
```

---

## Development Notes

### Default Password
For development, the default password is `password123` for all staff.

**⚠️ IMPORTANT:** In production:
1. Add a `passwordHash` field to the `staff` table
2. Hash all passwords before storing
3. Remove default password logic
4. Implement proper password reset functionality

### Password Storage
Currently, passwords are not stored in the database. To implement properly:

1. Add to `schema.sql`:
```sql
ALTER TABLE `staff` ADD COLUMN `password_hash` VARCHAR(255) DEFAULT NULL;
```

2. Update Prisma schema:
```prisma
model Staff {
  // ... existing fields
  passwordHash String? @map("password_hash")
}
```

3. Update login route to check against stored hash

---

## Security Best Practices

1. ✅ Use HTTPS in production
2. ✅ Change JWT_SECRET in production
3. ✅ Implement password complexity requirements
4. ✅ Add rate limiting for login attempts
5. ✅ Implement token refresh mechanism
6. ✅ Add password reset functionality
7. ✅ Log authentication attempts
8. ✅ Implement account lockout after failed attempts

---

## Example Usage

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"staffCode":"MGH/STAFF/001","password":"password123"}'
```

### Access Protected Route
```bash
curl -X GET http://localhost:3000/api/patients \
  -H "Authorization: Bearer <your-token>"
```

### Create Patient (Requires Clinician Role)
```bash
curl -X POST http://localhost:3000/api/patients \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "nin": "CM12345-67890-1",
    "firstName": "John",
    "lastName": "Doe",
    ...
  }'
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "error": "No token provided. Authorization header required."
}
```

### 403 Forbidden
```json
{
  "error": "Access denied. Insufficient permissions.",
  "required": ["db_clinician", "db_admin"],
  "current": ["db_readonly"]
}
```

---

**End of Authentication Documentation**

