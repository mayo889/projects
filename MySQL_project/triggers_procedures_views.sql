-- Триггеры, отклоняющие внесение или обновление оценки в таблице raitings, если она имеет неправильное значение.
-- Правильные значения для фильмов (1 - 10), для рецензий или комментариев (-1 или 1).
-- Также отклоняются новые строки или обновления, если цели оценки не существует в соответсвующей таблице.

DELIMITER //

DROP TRIGGER IF EXISTS raitings_insert_check_raiting//
CREATE TRIGGER raitings_insert_check_raiting BEFORE INSERT ON raitings
FOR EACH ROW
BEGIN
	IF (NEW.target_type_id = 1 AND NEW.raiting NOT BETWEEN 1 AND 10)
	  OR (NEW.target_type_id IN (2, 3) AND NEW.raiting NOT IN (-1, 1)) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled. Film rating (1 - 10). Review or comment (-1 or 1)';
    END IF;
   
	IF (NEW.target_type_id = 1 AND NEW.target_id NOT IN (SELECT id FROM movies)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled. Rate of a non-existent movie';
	END IF;

	IF (NEW.target_type_id = 2 AND NEW.target_id NOT IN (SELECT id FROM reviews)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled. Rate of a non-existent review';
	END IF;

	IF (NEW.target_type_id = 3 AND NEW.target_id NOT IN (SELECT id FROM comments)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled. Rate of a non-existent comment';
	END IF;
END//

DROP TRIGGER IF EXISTS raitings_update_check_rating//
CREATE TRIGGER raitings_update_check_rating BEFORE UPDATE ON raitings
FOR EACH ROW
BEGIN
	IF (NEW.target_type_id = 1 AND NEW.raiting NOT BETWEEN 1 AND 10)
	  OR (NEW.target_type_id IN (2, 3) AND NEW.raiting NOT IN (-1, 1)) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled. Film rating (1 - 10). Review or comment (-1 or 1)';
    END IF;
   
   IF (NEW.target_type_id = 1 AND NEW.target_id NOT IN (SELECT id FROM movies)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled. Rate of a non-existent movie';
	END IF;

	IF (NEW.target_type_id = 2 AND NEW.target_id NOT IN (SELECT id FROM reviews)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled. Rate of a non-existent review';
	END IF;

	IF (NEW.target_type_id = 3 AND NEW.target_id NOT IN (SELECT id FROM comments)) THEN
	  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled. Rate of a non-existent comment';
	END IF;
END//

DELIMITER ;

-- Создание представлений таблиц movies, reviews, comments and stars, где подсчитаны актуальные рейтинги из таблицы raitings

CREATE OR REPLACE VIEW movies_ratings AS
  (SELECT DISTINCT
    movies.id AS movie_id,
    ROUND(SUM(raitings.raiting) OVER(PARTITION BY movies.id) / COUNT(*) OVER(PARTITION BY movies.id), 1) AS rating
   FROM movies
     JOIN raitings
       ON (raitings.target_type_id = 1 AND raitings.target_id = movies.id)
  );
 
CREATE OR REPLACE VIEW reviews_ratings AS
  (SELECT DISTINCT
    reviews.id AS review_id,
    SUM(raitings.raiting) OVER(PARTITION BY reviews.id) AS rating
   FROM reviews
     JOIN raitings
       ON (raitings.target_type_id = 2 AND raitings.target_id = reviews.id)
  );
 
CREATE OR REPLACE VIEW comments_ratings AS
  (SELECT DISTINCT
    comments.id AS comment_id,
    SUM(raitings.raiting) OVER(PARTITION BY comments.id) AS rating
   FROM comments
     JOIN raitings
       ON (raitings.target_type_id = 3 AND raitings.target_id = comments.id)
  );

CREATE OR REPLACE VIEW stars_ratings AS
  (SELECT DISTINCT 
     stars.id AS star_id,
     ROUND(SUM(movies.raiting) OVER(PARTITION BY stars.id) / COUNT(*) OVER(PARTITION BY stars.id), 1) AS rating
   FROM stars
     JOIN stars_movies
       ON stars.id = stars_movies.star_id
     JOIN movies
       ON stars_movies.movie_id = movies.id
  );
 
-- Функции обновляющие рейтинги таблиц movies, reviews, comments и stars, считывая значения из соответствующих им представлений.

DELIMITER //

DROP PROCEDURE IF EXISTS movies_insert_ratings//
CREATE PROCEDURE movies_insert_ratings ()
BEGIN
  DECLARE id INT UNSIGNED;
  DECLARE rating FLOAT;
  DECLARE is_end INT DEFAULT 0;
 
  DECLARE curcat CURSOR FOR SELECT * FROM movies_ratings;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;
 
  OPEN curcat;
  
  cycle: LOOP
    FETCH curcat INTO id, rating;
    IF is_end THEN LEAVE cycle;
    END IF;
    UPDATE movies SET movies.raiting = rating WHERE movies.id = id;
  END LOOP cycle;
 
  CLOSE curcat;
END//

DROP PROCEDURE IF EXISTS reviews_insert_ratings//
CREATE PROCEDURE reviews_insert_ratings ()
BEGIN
  DECLARE id INT UNSIGNED;
  DECLARE rating FLOAT;
  DECLARE is_end INT DEFAULT 0;
 
  DECLARE curcat CURSOR FOR SELECT * FROM reviews_ratings;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;
 
  OPEN curcat;
  
  cycle: LOOP
    FETCH curcat INTO id, rating;
    IF is_end THEN LEAVE cycle;
    END IF;
    UPDATE reviews SET reviews.raiting = rating WHERE reviews.id = id;
  END LOOP cycle;
 
  CLOSE curcat;
END//

DROP PROCEDURE IF EXISTS comments_insert_ratings//
CREATE PROCEDURE comments_insert_ratings ()
BEGIN
  DECLARE id INT UNSIGNED;
  DECLARE rating FLOAT;
  DECLARE is_end INT DEFAULT 0;
 
  DECLARE curcat CURSOR FOR SELECT * FROM comments_ratings;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;
 
  OPEN curcat;
  
  cycle: LOOP
    FETCH curcat INTO id, rating;
    IF is_end THEN LEAVE cycle;
    END IF;
    UPDATE comments SET comments.raiting = rating WHERE comments.id = id;
  END LOOP cycle;
 
  CLOSE curcat;
END//

DROP PROCEDURE IF EXISTS stars_insert_ratings//
CREATE PROCEDURE stars_insert_ratings ()
BEGIN
  DECLARE id INT UNSIGNED;
  DECLARE rating FLOAT;
  DECLARE is_end INT DEFAULT 0;
 
  DECLARE curcat CURSOR FOR SELECT * FROM stars_ratings;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;
 
  OPEN curcat;
  
  cycle: LOOP
    FETCH curcat INTO id, rating;
    IF is_end THEN LEAVE cycle;
    END IF;
    UPDATE stars SET stars.raiting = rating WHERE stars.id = id;
  END LOOP cycle;
 
  CLOSE curcat;
END//

DELIMITER ;       
       