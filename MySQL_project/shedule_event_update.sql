-- Создание события с помощью планировщика mysql,
-- которое запускает каждый час 4 функции для пересчета рейтингов

SET GLOBAL event_scheduler = ON;

DELIMITER //

CREATE EVENT IF NOT EXISTS update_all_ratings
ON SCHEDULE EVERY 1 HOUR
DO
  BEGIN 
    CALL movies_insert_ratings;
    CALL reviews_insert_ratings;
    CALL comments_insert_ratings;
    CALL stars_insert_ratings;  
  END//
  
DELIMITER ;
