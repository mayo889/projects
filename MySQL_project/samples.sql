-- Самый популярный жанр кино. Популярность определяется по средней оценке фильма.

SELECT
  ROUND(AVG(movies.raiting), 1) AS avg_rating,
  (SELECT genre_id FROM about_movies WHERE movies.id = about_movies.movie_id) AS genre_movie,
  (SELECT genre FROM genres WHERE genres.id = genre_movie) AS name_genre
  FROM movies
  GROUP BY genre_movie
  ORDER BY avg_rating DESC
  LIMIT 1;

-- Средняя оценка фильмов людей, родившихся в разных десятилетиях. Учитываются только пользователи ставившие оценки.

SELECT
  CONCAT(SUBSTRING(profiles.birthday_at, 1, 3), '0-ые') AS decade,
  ROUND(AVG(raitings.raiting), 1) AS avg_rate
  FROM raitings
    JOIN profiles
      ON profiles.user_id = raitings.user_id
  WHERE raitings.target_type_id = 1
  GROUP BY decade
  ORDER BY avg_rate;

-- Определитель пользователи из какой страны больше всех оценивают фильмы, больше всех пишут рецензии, больше всех пишут комментарии.

SELECT DISTINCT
  profiles.country,
  ((COUNT(raitings.id) OVER w) + (COUNT(reviews.id) OVER w) + (COUNT(comments.id) OVER w) ) AS total
  FROM profiles
    LEFT JOIN raitings
      ON profiles.user_id = raitings.user_id AND raitings.target_type_id = 1
    LEFT JOIN reviews
      ON profiles.user_id = reviews.user_id
    LEFT JOIN comments
      ON profiles.user_id = comments.user_id
  WINDOW w AS (PARTITION BY profiles.country)
  ORDER BY total DESC
  LIMIT 1;

-- Самый популярный жанр кино среди пользователей из такой страны, людей из которой на сайте зарегистрировано больше всего.
-- Оценки фильмов оцениваются отдельно для людей из каждой страны.
     
SELECT DISTINCT
  profiles.country AS country,
  COUNT(raitings.id) OVER w1 AS number_people_from_this_country,
  SUM(raitings.raiting) OVER w2 / COUNT(genres.id) OVER w2 AS avg_rating_genre_of_this_country,
  genres.genre
  FROM profiles
    LEFT JOIN raitings
      ON profiles.user_id = raitings.user_id AND raitings.target_type_id = 1
    JOIN movies
      ON raitings.target_id = movies.id
    JOIN about_movies
      ON movies.id = about_movies.movie_id
    JOIN genres
      ON about_movies.genre_id = genres.id
  WINDOW w1 AS (PARTITION BY profiles.country),
         w2 AS (PARTITION BY profiles.country, about_movies.genre_id)
  ORDER BY number_people_from_this_country DESC
  LIMIT 1;

-- Для каждого фильма определить среди тех, кто принимал участие в его создании:
-- лучшего актера, режиссера, сценариста и продюссера, ориентируясь на рейтинг звезды.
-- (Среди тех, о ком есть информация в БД).

SELECT DISTINCT
  movies.id AS movie_id,
  movies.name AS movie,
  professions.profession,
  FIRST_VALUE(CONCAT(stars.first_name, ' ', stars.last_name)) OVER w AS best_in_his_profession_in_this_film
  FROM stars_movies
    JOIN stars
      ON stars_movies.star_id = stars.id
    JOIN professions
      ON stars.profession_id = professions.id
    JOIN movies
      ON stars_movies.movie_id = movies.id
    WINDOW w AS (PARTITION BY movies.id, professions.id ORDER BY stars.raiting DESC);

-- Определить какое внимание уделили пользователи самому неприбыльному фильму.
-- Количество внимания определяется количеством оценок фильму, количеством рецензий к фильму
-- и количеством комментариев к реценезиям к этому фильму.
 
SELECT
  tbl.movie AS movie,
  tbl.profit AS profit,
  COUNT(DISTINCT tbl.id_rate) AS number_ratings,
  COUNT(DISTINCT tbl.id_review) AS number_reviews,
  COUNT(DISTINCT tbl.id_comment) AS number_comments
  FROM (
    SELECT
      movies.id AS movie_id, 
      movies.name AS movie,
      (about_movies.box_office - about_movies.budget) AS profit,
      raitings.id AS id_rate,
      reviews.id AS id_review,
      comments.id AS id_comment
    FROM movies
      JOIN about_movies
        ON movies.id = about_movies.movie_id
      LEFT JOIN raitings
        ON raitings.target_type_id = 1 AND raitings.target_id = movies.id
      LEFT JOIN reviews
        ON reviews.movie_id = movies.id
      LEFT JOIN comments
        ON comments.review_id = reviews.id
  ) AS tbl
  GROUP BY tbl.movie_id
  ORDER BY tbl.profit
  LIMIT 1;

-- Улучшение предыдущего запроса. В данном случае количество внимания к самому неприбыльному фильму
-- высчитано в процентах по отношению ко всему количеству оценок, рецензий и комментариев соответсвенно

SELECT
  tbl.movie AS movie,
  tbl.profit AS profit,
  (COUNT(DISTINCT tbl.id_rate) / ANY_VALUE(tbl.rt_total) * 100) AS percent_number_ratings,
  (COUNT(DISTINCT tbl.id_review) / ANY_VALUE(tbl.rv_total) * 100) AS percent_number_reviews,
  (COUNT(DISTINCT tbl.id_comment) / ANY_VALUE(tbl.cm_total) * 100) AS percent_number_comments
  FROM (
    SELECT
      rt.total AS rt_total,
      rv.total AS rv_total,
      cm.total AS cm_total,
      movies.id AS movie_id, 
      movies.name AS movie,
      (about_movies.box_office - about_movies.budget) AS profit,
      raitings.id AS id_rate,
      reviews.id AS id_review,
      comments.id AS id_comment
    FROM 
          (SELECT COUNT(*) AS total FROM raitings WHERE target_type_id = 1) AS rt
        CROSS JOIN 
          (SELECT COUNT(*) AS total FROM reviews) AS rv
        CROSS JOIN
          (SELECT COUNT(*) AS total FROM comments) AS cm
        CROSS JOIN 
          movies
      JOIN about_movies
        ON movies.id = about_movies.movie_id
      LEFT JOIN raitings
        ON raitings.target_type_id = 1 AND raitings.target_id = movies.id
      LEFT JOIN reviews
        ON reviews.movie_id = movies.id
      LEFT JOIN comments
        ON comments.review_id = reviews.id
  ) AS tbl
  GROUP BY tbl.movie_id
  ORDER BY tbl.profit
  LIMIT 1;
  