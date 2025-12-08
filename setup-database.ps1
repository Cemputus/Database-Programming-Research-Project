# ============================================================================
# Database Setup Script for HIV Patient Care System
# Windows PowerShell Script
# ============================================================================

$MYSQL_USER = "root"
$MYSQL_PASSWORD = "root"
$DATABASE_NAME = "hiv_patient_care"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HIV Patient Care Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create database
Write-Host "[1/7] Creating database..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create database!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Database created" -ForegroundColor Green
Write-Host ""

# Step 2: Run schema.sql
Write-Host "[2/7] Running schema.sql (creating tables)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/schema.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run schema.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Tables created" -ForegroundColor Green
Write-Host ""

# Step 3: Run triggers.sql
Write-Host "[3/7] Running triggers.sql (creating triggers)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/triggers.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run triggers.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Triggers created" -ForegroundColor Green
Write-Host ""

# Step 4: Run views.sql
Write-Host "[4/7] Running views.sql (creating views)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/views.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run views.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Views created" -ForegroundColor Green
Write-Host ""

# Step 5: Run stored_procedures.sql
Write-Host "[5/7] Running stored_procedures.sql (creating procedures)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/stored_procedures.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run stored_procedures.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Stored procedures created" -ForegroundColor Green
Write-Host ""

# Step 6: Run security.sql
Write-Host "[6/7] Running security.sql (setting up roles)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/security.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run security.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Security roles created" -ForegroundColor Green
Write-Host ""

# Step 7: Run events.sql
Write-Host "[7/7] Running events.sql (creating scheduled events)..." -ForegroundColor Yellow
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/events.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to run events.sql!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Scheduled events created" -ForegroundColor Green
Write-Host ""

# Optional: Seed data
Write-Host "========================================" -ForegroundColor Cyan
$seedChoice = Read-Host "Do you want to load seed data? (y/n)"
if ($seedChoice -eq "y" -or $seedChoice -eq "Y") {
    Write-Host "Loading seed data..." -ForegroundColor Yellow
    mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME < database/seed_data.sql
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to load seed data!" -ForegroundColor Red
    } else {
        Write-Host "✓ Seed data loaded" -ForegroundColor Green
    }
} else {
    Write-Host "Skipping seed data..." -ForegroundColor Gray
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Database setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd backend" -ForegroundColor White
Write-Host "2. npm install" -ForegroundColor White
Write-Host "3. Create .env file with:" -ForegroundColor White
Write-Host "   DATABASE_URL=`"mysql://root:root@localhost:3306/hiv_patient_care`"" -ForegroundColor Gray
Write-Host "   JWT_SECRET=your-secret-key" -ForegroundColor Gray
Write-Host "   PORT=3000" -ForegroundColor Gray
Write-Host "4. npm run dev" -ForegroundColor White
Write-Host ""







