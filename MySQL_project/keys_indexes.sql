#
# Внешние ключи
#

ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_id_fk
    FOREIGN KEY (user_id) REFERENCES users(id)
      ON DELETE CASCADE,
  ADD CONSTRAINT profiles_photo_id_fk
    FOREIGN KEY (photo_id) REFERENCES media(id)
      ON DELETE SET NULL;

ALTER TABLE about_movies
  ADD CONSTRAINT about_movies_movie_id_fk
    FOREIGN KEY (movie_id) REFERENCES movies(id)
      ON DELETE CASCADE,
  ADD CONSTRAINT about_movies_genre_id_fk
    FOREIGN KEY (genre_id) REFERENCES genres(id)
      ON DELETE SET NULL,
  ADD CONSTRAINT about_movies_poster_id_fk
    FOREIGN KEY (poster_id) REFERENCES media(id)
      ON DELETE SET NULL,
  ADD CONSTRAINT about_movies_trailer_id_fk
    FOREIGN KEY (trailer_id) REFERENCES media(id)
      ON DELETE SET NULL;

ALTER TABLE reviews
  ADD CONSTRAINT reviews_user_id_fk
    FOREIGN KEY (user_id) REFERENCES users(id),
  ADD CONSTRAINT reviews_movie_id_fk
    FOREIGN KEY (movie_id) REFERENCES movies(id)
      ON DELETE CASCADE;

ALTER TABLE comments
  ADD CONSTRAINT comments_user_id_fk
    FOREIGN KEY (user_id) REFERENCES users(id),
  ADD CONSTRAINT comments_review_id_fk
    FOREIGN KEY (review_id) REFERENCES reviews(id)
      ON DELETE CASCADE;

ALTER TABLE stars
  ADD CONSTRAINT stars_photo_id_fk
    FOREIGN KEY (photo_id) REFERENCES media(id)
      ON DELETE SET NULL,
  ADD CONSTRAINT stars_profession_id_fk
    FOREIGN KEY (profession_id) REFERENCES professions(id)
      ON DELETE RESTRICT;

ALTER TABLE stars_movies
  ADD CONSTRAINT stars_star_id_fk
    FOREIGN KEY (star_id) REFERENCES stars(id),
  ADD CONSTRAINT stars_movie_id_fk
    FOREIGN KEY (movie_id) REFERENCES movies(id);

ALTER TABLE raitings
  ADD CONSTRAINT raitings_user_id_fk
    FOREIGN KEY (user_id) REFERENCES users(id),
  ADD CONSTRAINT raitings_target_type_id_fk
    FOREIGN KEY (target_type_id) REFERENCES target_types(id);

ALTER TABLE friendship
  ADD CONSTRAINT friendship_user_id_fk
    FOREIGN KEY (user_id) REFERENCES users(id)
      ON DELETE CASCADE,
  ADD CONSTRAINT friendship_friend_id_fk
    FOREIGN KEY (friend_id) REFERENCES users(id)
      ON DELETE CASCADE;

ALTER TABLE media
  ADD CONSTRAINT media_media_type_id_fk
    FOREIGN KEY (media_type_id) REFERENCES media_types(id);

#
# Индексы
#

CREATE INDEX users_first_name_last_name_idx ON users(first_name, last_name);

CREATE INDEX profiles_birthday_at_idx ON profiles(birthday_at);
CREATE INDEX profiles_city_idx ON profiles(city);
CREATE INDEX profiles_country_idx ON profiles(country);

CREATE INDEX movies_raiting_idx ON movies(raiting);

CREATE INDEX about_movies_production_year_idx ON about_movies(production_year);

CREATE INDEX reviews_raiting_idx ON reviews(raiting);

CREATE INDEX comments_raiting_idx ON comments(raiting);

CREATE INDEX stars_first_name_last_name_idx ON stars(first_name, last_name);
CREATE INDEX stars_raiting_idx ON stars(raiting);

CREATE INDEX raitings_target_id_idx ON raitings(target_id);

CREATE INDEX friendship_user_id_friend_id_idx ON friendship(user_id, friend_id);

CREATE INDEX media_size_idx ON media(size);
