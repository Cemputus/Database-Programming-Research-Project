# Quick Start Guide
## HIV Patient Care & Treatment Monitoring System

---

## 🚀 Step 1: Setup Database

Run the automated setup script:

```powershell
.\setup-database.ps1
```

**OR** run manually:

```powershell
# Create database
mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS hiv_patient_care;"

# Run SQL files in order
mysql -u root -proot hiv_patient_care < database/schema.sql
mysql -u root -proot hiv_patient_care < database/triggers.sql
mysql -u root -proot hiv_patient_care < database/views.sql
mysql -u root -proot hiv_patient_care < database/stored_procedures.sql
mysql -u root -proot hiv_patient_care < database/security.sql
mysql -u root -proot hiv_patient_care < database/events.sql

# Optional: Load sample data
mysql -u root -proot hiv_patient_care < database/seed_data.sql
```

---

## 🔧 Step 2: Setup Backend

```powershell
cd backend
npm install
```

---

## 📝 Step 3: Create Environment File

Create `backend/.env` file with:

```env
DATABASE_URL="mysql://root:root@localhost:3306/hiv_patient_care"
JWT_SECRET=your-super-secret-jwt-key-change-in-production
PORT=3000
NODE_ENV=development
```

---

## ▶️ Step 4: Start Server

```powershell
npm run dev
```

Server will start on `http://localhost:3000`

---

## ✅ Verify Setup

1. **Check Database:**
   ```sql
   mysql -u root -proot hiv_patient_care
   SHOW TABLES;
   ```

2. **Test API:**
   ```powershell
   # Health check
   curl http://localhost:3000/api/health
   
   # Login (if seed data loaded)
   curl -X POST http://localhost:3000/api/auth/login `
     -H "Content-Type: application/json" `
     -d '{\"staffCode\":\"MGH/STAFF/001\",\"password\":\"password123\"}'
   ```

---

## 📋 Default Login (if seed data loaded)

- **Staff Code:** `MGH/STAFF/001`
- **Password:** `password123`

---

## 🆘 Troubleshooting

- **MySQL not found:** Make sure MySQL is in your PATH
- **Connection refused:** Check MySQL is running
- **Port already in use:** Change PORT in `.env` file
- **Module not found:** Run `npm install` in `backend/` folder

