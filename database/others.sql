SELECT * FROM mysql.role_edges;

-- When logged in as pharmacist1, run:
SELECT CURRENT_ROLE();
SHOW GRANTS FOR CURRENT_USER();


USE hiv_patient_care;

SHOW tables;

SELECT * FROM person LIMIT 5;