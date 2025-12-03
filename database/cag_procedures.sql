-- ============================================================================
-- CAG MANAGEMENT STORED PROCEDURES
-- HIV Patient Care & Treatment Monitoring System
-- Community ART Group (CAG) operations
-- ============================================================================

DELIMITER //

-- ============================================================================
-- SP: Add Patient to CAG
-- Adds a patient to a Community ART Group
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_add_patient`//
CREATE PROCEDURE `sp_cag_add_patient`(
    IN p_patient_id INT UNSIGNED,
    IN p_cag_id INT UNSIGNED,
    IN p_role_in_cag ENUM('Member', 'Coordinator', 'Deputy Coordinator')
)
BEGIN
    DECLARE v_cag_status VARCHAR(20);
    DECLARE v_current_members INT;
    DECLARE v_max_members INT;
    DECLARE v_patient_status VARCHAR(20);
    
    -- Check CAG exists and is active
    SELECT status, max_members INTO v_cag_status, v_max_members
    FROM cag
    WHERE cag_id = p_cag_id;
    
    IF v_cag_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG not found';
    END IF;
    
    IF v_cag_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG is not active';
    END IF;
    
    -- Check patient status
    SELECT current_status INTO v_patient_status
    FROM patient
    WHERE patient_id = p_patient_id;
    
    IF v_patient_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;
    
    IF v_patient_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only active patients can join CAG';
    END IF;
    
    -- Check if patient already has active membership
    IF EXISTS (
        SELECT 1 FROM patient_cag 
        WHERE patient_id = p_patient_id 
          AND cag_id = p_cag_id 
          AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already an active member of this CAG';
    END IF;
    
    -- Check member limit
    SELECT COUNT(*) INTO v_current_members
    FROM patient_cag
    WHERE cag_id = p_cag_id AND is_active = TRUE;
    
    IF v_current_members >= v_max_members THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('CAG has reached maximum members (', v_max_members, ')');
    END IF;
    
    -- Deactivate any previous memberships in other CAGs
    UPDATE patient_cag
    SET is_active = FALSE,
        exit_date = CURDATE(),
        exit_reason = 'Joined another CAG'
    WHERE patient_id = p_patient_id 
      AND is_active = TRUE
      AND cag_id != p_cag_id;
    
    -- Add patient to CAG
    INSERT INTO patient_cag (
        patient_id,
        cag_id,
        join_date,
        role_in_cag,
        is_active
    ) VALUES (
        p_patient_id,
        p_cag_id,
        CURDATE(),
        p_role_in_cag,
        TRUE
    );
    
    -- If coordinator role, update CAG coordinator
    IF p_role_in_cag = 'Coordinator' THEN
        UPDATE cag
        SET coordinator_patient_id = p_patient_id
        WHERE cag_id = p_cag_id;
    END IF;
    
    SELECT 'Patient added to CAG successfully' AS result;
END//

-- ============================================================================
-- SP: Remove Patient from CAG
-- Removes a patient from a CAG (marks as inactive)
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_remove_patient`//
CREATE PROCEDURE `sp_cag_remove_patient`(
    IN p_patient_id INT UNSIGNED,
    IN p_cag_id INT UNSIGNED,
    IN p_exit_reason VARCHAR(200)
)
BEGIN
    DECLARE v_is_coordinator BOOLEAN DEFAULT FALSE;
    
    -- Check if patient is coordinator
    SELECT COUNT(*) > 0 INTO v_is_coordinator
    FROM patient_cag
    WHERE patient_id = p_patient_id
      AND cag_id = p_cag_id
      AND role_in_cag = 'Coordinator'
      AND is_active = TRUE;
    
    -- Remove patient from CAG
    UPDATE patient_cag
    SET is_active = FALSE,
        exit_date = CURDATE(),
        exit_reason = p_exit_reason
    WHERE patient_id = p_patient_id
      AND cag_id = p_cag_id
      AND is_active = TRUE;
    
    -- If coordinator, clear coordinator from CAG
    IF v_is_coordinator THEN
        UPDATE cag
        SET coordinator_patient_id = NULL
        WHERE cag_id = p_cag_id;
    END IF;
    
    SELECT 'Patient removed from CAG successfully' AS result;
END//

-- ============================================================================
-- SP: Record CAG Rotation
-- Records when a CAG member picks up medications for the group
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_record_rotation`//
CREATE PROCEDURE `sp_cag_record_rotation`(
    IN p_cag_id INT UNSIGNED,
    IN p_pickup_patient_id INT UNSIGNED,
    IN p_rotation_date DATE,
    IN p_dispense_id BIGINT UNSIGNED,
    IN p_patients_served TINYINT UNSIGNED,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_cag_status VARCHAR(20);
    DECLARE v_is_member BOOLEAN DEFAULT FALSE;
    
    -- Check CAG exists and is active
    SELECT status INTO v_cag_status
    FROM cag
    WHERE cag_id = p_cag_id;
    
    IF v_cag_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG not found';
    END IF;
    
    IF v_cag_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CAG is not active';
    END IF;
    
    -- Check pickup patient is member of CAG
    SELECT COUNT(*) > 0 INTO v_is_member
    FROM patient_cag
    WHERE patient_id = p_pickup_patient_id
      AND cag_id = p_cag_id
      AND is_active = TRUE;
    
    IF NOT v_is_member THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pickup patient is not an active member of this CAG';
    END IF;
    
    -- Record rotation
    INSERT INTO cag_rotation (
        cag_id,
        pickup_patient_id,
        rotation_date,
        dispense_id,
        patients_served,
        notes
    ) VALUES (
        p_cag_id,
        p_pickup_patient_id,
        p_rotation_date,
        p_dispense_id,
        p_patients_served,
        p_notes
    );
    
    SELECT LAST_INSERT_ID() AS rotation_id, 'Rotation recorded successfully' AS result;
END//

-- ============================================================================
-- SP: Get CAG Members
-- Returns all active members of a specific CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_members`//
CREATE PROCEDURE `sp_cag_get_members`(
    IN p_cag_id INT UNSIGNED
)
BEGIN
    SELECT 
        pc.patient_cag_id,
        pc.patient_id,
        p.patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS patient_name,
        per.sex,
        TIMESTAMPDIFF(YEAR, per.date_of_birth, CURDATE()) AS age,
        pc.join_date,
        pc.role_in_cag,
        p.current_status,
        p.art_start_date,
        (SELECT MAX(visit_date) FROM visit WHERE patient_id = p.patient_id) AS last_visit_date,
        (SELECT MAX(test_date) FROM lab_test 
         WHERE patient_id = p.patient_id 
           AND test_type = 'Viral Load' 
           AND result_status = 'Completed') AS last_vl_date,
        (SELECT result_numeric FROM lab_test 
         WHERE patient_id = p.patient_id 
           AND test_type = 'Viral Load' 
           AND result_status = 'Completed'
         ORDER BY test_date DESC LIMIT 1) AS last_vl_result,
        (SELECT adherence_percent FROM adherence_log 
         WHERE patient_id = p.patient_id 
         ORDER BY log_date DESC LIMIT 1) AS last_adherence
    FROM patient_cag pc
    INNER JOIN patient p ON pc.patient_id = p.patient_id
    INNER JOIN person per ON p.person_id = per.person_id
    WHERE pc.cag_id = p_cag_id
      AND pc.is_active = TRUE
    ORDER BY pc.role_in_cag DESC, pc.join_date;
END//

-- ============================================================================
-- SP: Get CAG Rotation History
-- Returns rotation history for a specific CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_rotations`//
CREATE PROCEDURE `sp_cag_get_rotations`(
    IN p_cag_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        cr.rotation_id,
        cr.rotation_date,
        cr.pickup_patient_id,
        p.patient_code AS pickup_patient_code,
        CONCAT(per.first_name, ' ', COALESCE(per.other_name, ''), ' ', per.last_name) AS pickup_patient_name,
        cr.patients_served,
        cr.dispense_id,
        d.dispense_date,
        r.regimen_name,
        cr.notes
    FROM cag_rotation cr
    INNER JOIN patient p ON cr.pickup_patient_id = p.patient_id
    INNER JOIN person per ON p.person_id = per.person_id
    LEFT JOIN dispense d ON cr.dispense_id = d.dispense_id
    LEFT JOIN regimen r ON d.regimen_id = r.regimen_id
    WHERE cr.cag_id = p_cag_id
      AND (p_start_date IS NULL OR cr.rotation_date >= p_start_date)
      AND (p_end_date IS NULL OR cr.rotation_date <= p_end_date)
    ORDER BY cr.rotation_date DESC;
END//

-- ============================================================================
-- SP: Get CAG Statistics
-- Returns comprehensive statistics for a CAG
-- ============================================================================

DROP PROCEDURE IF EXISTS `sp_cag_get_statistics`//
CREATE PROCEDURE `sp_cag_get_statistics`(
    IN p_cag_id INT UNSIGNED
)
BEGIN
    SELECT 
        c.cag_id,
        c.cag_name,
        c.district,
        c.subcounty,
        c.parish,
        c.village,
        c.formation_date,
        c.status,
        c.max_members,
        COUNT(DISTINCT pc.patient_id) AS active_members,
        AVG(ad.adherence_percent) AS avg_adherence,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 95 THEN pc.patient_id END) AS excellent_adherence_count,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent >= 85 AND ad.adherence_percent < 95 THEN pc.patient_id END) AS good_adherence_count,
        COUNT(DISTINCT CASE WHEN ad.adherence_percent < 85 THEN pc.patient_id END) AS poor_adherence_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric < 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS suppressed_vl_count,
        COUNT(DISTINCT CASE WHEN lt.result_numeric >= 1000 AND lt.test_type = 'Viral Load' THEN pc.patient_id END) AS unsuppressed_vl_count,
        COUNT(DISTINCT cr.rotation_id) AS total_rotations,
        MAX(cr.rotation_date) AS last_rotation_date,
        MIN(cr.rotation_date) AS first_rotation_date,
        DATEDIFF(CURDATE(), MIN(cr.rotation_date)) AS days_since_first_rotation
    FROM cag c
    LEFT JOIN patient_cag pc ON c.cag_id = pc.cag_id AND pc.is_active = TRUE
    LEFT JOIN adherence_log ad ON pc.patient_id = ad.patient_id
    LEFT JOIN lab_test lt ON pc.patient_id = lt.patient_id 
        AND lt.test_type = 'Viral Load' 
        AND lt.result_status = 'Completed'
        AND lt.test_date = (
            SELECT MAX(test_date) 
            FROM lab_test 
            WHERE patient_id = pc.patient_id 
              AND test_type = 'Viral Load' 
              AND result_status = 'Completed'
        )
    LEFT JOIN cag_rotation cr ON c.cag_id = cr.cag_id
    WHERE c.cag_id = p_cag_id
    GROUP BY c.cag_id, c.cag_name, c.district, c.subcounty, c.parish, c.village, 
             c.formation_date, c.status, c.max_members;
END//

DELIMITER ;

