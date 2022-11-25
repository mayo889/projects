-- Обновление столбца updated_at во всех таблицах, где он есть

UPDATE users SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE profiles SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE movies SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE about_movies SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE stars SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE raitings SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE target_types SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE friendship SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE media SET updated_at = NOW() WHERE created_at > updated_at;
UPDATE media_types SET updated_at = NOW() WHERE created_at > updated_at;

-- Заполнение таблицы media файлами постеров и трейлеров к фильмам, где названия файлов соответствуют названию фильма

INSERT INTO media (filename, size, media_type_id)
  SELECT name, FLOOR(RAND()*(100*1024 - 10*1024) + 10*1024), 1 FROM movies ORDER BY id;

INSERT INTO media (filename, size, media_type_id)
  SELECT name, FLOOR(RAND()*(1000*1024 - 250*1024) + 250*1024), 2 FROM movies ORDER BY id;

-- Приведение названий файлов в таблице media к правильному виду

CREATE TEMPORARY TABLE extensions_photo(name VARCHAR(10));
INSERT INTO extensions_photo VALUES ('jpeg'), ('png');
CREATE TEMPORARY TABLE extensions_video(name VARCHAR(10));
INSERT INTO extensions_video VALUES ('mpg'), ('avi'), ('mov'), ('wmv');

UPDATE media
  SET filename = CONCAT(
    'http://dropbox.net/kinopoisk/posters/',
    filename,
    '.',
    (SELECT name FROM extensions_photo ORDER BY RAND() LIMIT 1))
  WHERE media_type_id = 1;

UPDATE media
  SET filename = CONCAT(
    'http://dropbox.net/kinopoisk/',
    filename,
    '.',
    (SELECT name FROM extensions_photo ORDER BY RAND() LIMIT 1))
  WHERE media_type_id = 3;

UPDATE media
  SET filename = CONCAT(
    'http://dropbox.net/kinopoisk/trailers/',
    filename,
    '.',
    (SELECT name FROM extensions_video ORDER BY RAND() LIMIT 1))
  WHERE media_type_id = 2;

-- Приведение ссылок пользователей на соц сети к правильному виду

UPDATE profiles SET social_network = CONCAT('http://vk.com/', social_network);
 
-- Исправление того факта, что фотографии пользователей и звезд ссылаются на одни и те же записи в media
-- Так как некоторые пользователи любят ставить в качестве аватарки не свою фотографию,
-- то при совпадении photo_id фотография остается у звезды, а пользователю выставляется NULL

UPDATE profiles
  JOIN stars
    ON profiles.photo_id = stars.photo_id
  SET profiles.photo_id = NULL;

-- Исправление таблицы raitings. Если цель оценки - фильм, то оценкой является случайное число от (1, 10).
-- Если цель оценки - рецензия или комментарий, то оценкой является -1 или 1.

UPDATE raitings SET raiting = FLOOR(RAND()* 10 + 1) WHERE target_type_id = 1;
UPDATE raitings SET raiting = ELT(FLOOR(RAND() * 2 + 1), -1, 1) WHERE target_type_id IN (2, 3);

-- Исправление таблицы raitings так, чтобы target_id был в допустимом диапазоне для соответствующей таблицы

UPDATE raitings SET target_id = FLOOR(RAND() * 20 + 1) WHERE target_type_id = 1;
UPDATE raitings SET target_id = FLOOR(RAND() * 40 + 1) WHERE target_type_id = 2;
UPDATE raitings SET target_id = FLOOR(RAND() * 60 + 1) WHERE target_type_id = 3;

-- Удаление из таблицы friendship строк, где пользователь подписан на себя или дружит сам с собой

DELETE FROM friendship WHERE user_id = friend_id;

-- Заполнение поля raiting в таблице movies

UPDATE movies
  JOIN (SELECT DISTINCT
          movies.id AS id,
          ROUND(SUM(raitings.raiting) OVER(PARTITION BY movies.id) / COUNT(*) OVER(PARTITION BY movies.id), 1) AS raiting
        FROM movies
          JOIN raitings
            ON (target_type_id = 1 AND raitings.target_id = movies.id)
       ) AS extra
    ON movies.id = extra.id
  SET movies.raiting = extra.raiting;

-- -- Заполнение поля raiting в таблице reviews
 
UPDATE reviews
  JOIN (SELECT DISTINCT
          reviews.id AS id,
          SUM(raitings.raiting) OVER(PARTITION BY reviews.id) AS raiting
        FROM reviews
          JOIN raitings
            ON (raitings.target_type_id = 2 AND raitings.target_id = reviews.id)
       ) AS extra
    ON reviews.id = extra.id
  SET reviews.raiting = extra.raiting;
 
-- Заполнение поля raiting в таблице comments
 
UPDATE comments
  JOIN (SELECT DISTINCT
          comments.id AS id,
          SUM(raitings.raiting) OVER(PARTITION BY comments.id) AS raiting
        FROM comments
          JOIN raitings
            ON (raitings.target_type_id = 3 AND raitings.target_id = comments.id)
       ) AS extra
    ON comments.id = extra.id
  SET comments.raiting = extra.raiting;
 
-- Заполнение поля raiting в таблице stars
 
UPDATE stars
  JOIN (SELECT DISTINCT 
          stars.id AS id,
          ROUND(SUM(movies.raiting) OVER(PARTITION BY stars.id) / COUNT(*) OVER(PARTITION BY stars.id), 1) AS raiting
        FROM stars
          JOIN stars_movies
            ON stars.id = stars_movies.star_id
          JOIN movies
            ON stars_movies.movie_id = movies.id
       ) AS extra
    ON stars.id = extra.id
  SET stars.raiting = extra.raiting;
  