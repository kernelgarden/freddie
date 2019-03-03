USE freddie_test_repo;

DROP PROCEDURE IF EXISTS set_up_test_users;

DELIMITER #
CREATE PROCEDURE set_up_test_users()
BEGIN

DECLARE v_max int unsigned default 1000;
DECLARE v_counter int unsigned default 0;

TRUNCATE TABLE user;
START TRANSACTION;
    WHILE v_counter < v_max do
        SET @time = (SELECT NOW());
        INSERT INTO user (player_name, current_pos_x, current_pos_y, current_pos_z, create_time, is_valid)
            VALUES (CONCAT('User#', CAST(v_counter AS CHAR(4))), 0, 0, 0, @time, 1);
        SET v_counter=v_counter+1;
    END WHILE;
COMMIT;

END #

DELIMITER ;

CALL set_up_test_users();

SELECT * FROM user;