-- DIM_FILM
CREATE OR REPLACE TABLE omdb_dwh.dim_film AS (
  SELECT
    GENERATE_UUID() AS id,
    Title,
    SAFE_CAST(Year AS int64) as year,
    SAFE_CAST(REPLACE(Runtime,'min','') AS int64) as runtime,
    Type,
    Plot,
    Language,
    Country
  FROM
    omdb_raw.film
);

-- DIM_GENRE
CREATE OR REPLACE TABLE omdb_dwh.dim_genre AS (
  WITH genre AS (
    SELECT DISTINCT
      TRIM(name) AS name
    FROM 
      omdb_raw.film,
      UNNEST(SPLIT(Genre, ',')) AS name
  )
  SELECT
    GENERATE_UUID() AS id,
    name AS genre
  FROM
    genre
);

-- FILM_GENRE
CREATE OR REPLACE TABLE omdb_dwh.film_genre AS (
  WITH title_genre AS (
    SELECT
      film.title AS title,
      TRIM(name) AS name
    FROM 
      omdb_raw.film AS film,
      UNNEST(SPLIT(Genre, ',')) AS name
  ),

  dim_film AS (
    SELECT
      id,
      title
    FROM
      omdb_dwh.dim_film
  ),

  dim_genre AS (
    SELECT
      id,
      genre
    FROM
      omdb_dwh.dim_genre
  )

  SELECT
    dim_film.id AS dim_film_id,
    dim_genre.id AS dim_genre_id,
  FROM
    title_genre AS t
  JOIN
    dim_genre ON t.name = dim_genre.genre
  JOIN
    dim_film ON t.title = dim_film.title
);

-- DIM_PERSON
CREATE OR REPLACE TABLE omdb_dwh.dim_person AS (WITH directors AS (
    SELECT
      TRIM(name) AS name
    FROM 
      omdb_raw.film,
      UNNEST(SPLIT(Director, ',')) AS name
  ),

  writers AS (
    SELECT
      TRIM(name) AS name
    FROM 
      omdb_raw.film,
      UNNEST(SPLIT(Writer, ',')) AS name
  ),

  actors AS (
    SELECT
      TRIM(name) AS name
    FROM 
      omdb_raw.film,
      UNNEST(SPLIT(Actors, ',')) AS name
  )
  SELECT
    GENERATE_UUID() AS id,
    name
  FROM
  (SELECT name FROM directors
  UNION DISTINCT
  SELECT name FROM writers
  UNION DISTINCT
  SELECT name FROM actors)
);

-- DIM_DIRECTOR
CREATE OR REPLACE TABLE omdb_dwh.dim_director AS (
  WITH title_director AS (
  SELECT
    film.title AS title,
    TRIM(name) AS name
  FROM 
    omdb_raw.film AS film,
    UNNEST(SPLIT(Director, ',')) AS name),

  dim_film AS (
    SELECT
      id,
      title
    FROM
      omdb_dwh.dim_film
  ),

  dim_person AS (
    SELECT
      id,
      name
    FROM
      omdb_dwh.dim_person
  )

  SELECT
    dim_film.id AS dim_film_id,
    dim_person.id AS dim_person_id,
  FROM
    title_director AS t
  JOIN
    dim_person ON t.name = dim_person.name
  JOIN
    dim_film ON t.title = dim_film.title
);

-- DIM_ACTOR
CREATE OR REPLACE TABLE omdb_dwh.dim_actor AS (
  WITH title_actor AS (
  SELECT
    film.title AS title,
    TRIM(name) AS name
  FROM 
    omdb_raw.film AS film,
    UNNEST(SPLIT(Actors, ',')) AS name),

  dim_film AS (
    SELECT
      id,
      title
    FROM
      omdb_dwh.dim_film
  ),

  dim_person AS (
    SELECT
      id,
      name
    FROM
      omdb_dwh.dim_person
  )

  SELECT
    dim_film.id AS dim_film_id,
    dim_person.id AS dim_person_id,
  FROM
    title_actor AS t
  JOIN
    dim_person ON t.name = dim_person.name
  JOIN
    dim_film ON t.title = dim_film.title
);

-- DIM_WRITER
CREATE OR REPLACE TABLE omdb_dwh.dim_writer AS (
  WITH title_writer AS (
  SELECT
    film.title AS title,
    TRIM(name) AS name
  FROM 
    omdb_raw.film AS film,
    UNNEST(SPLIT(Writer, ',')) AS name),

  dim_film AS (
    SELECT
      id,
      title
    FROM
      omdb_dwh.dim_film
  ),

  dim_person AS (
    SELECT
      id,
      name
    FROM
      omdb_dwh.dim_person
  )

  SELECT
    dim_film.id AS dim_film_id,
    dim_person.id AS dim_person_id,
  FROM
    title_writer AS t
  JOIN
    dim_person ON t.name = dim_person.name
  JOIN
    dim_film ON t.title = dim_film.title
);

-- DIM_DISTRIBUTOR
CREATE OR REPLACE TABLE omdb_dwh.dim_distributor AS(
  WITH distributors AS (
    SELECT DISTINCT
      distributor
    FROM
    `future-minds-omdb.omdb_raw.revenues_per_day`
  )
  SELECT
    GENERATE_UUID() AS id,
    distributor
  FROM
    distributors
);

-- FACT_DAILY_REVENUE
CREATE OR REPLACE TABLE omdb_dwh.fact_daily_revenue AS (
  SELECT
    DATE(date) AS date,
    f.id AS dim_film_id,
    d.id AS dim_distributor_id,
    r.theaters AS theaters,
    r.revenue AS revenue
  FROM
    omdb_raw.revenues_per_day AS r
  JOIN
    omdb_dwh.dim_film AS f ON TRIM(REGEXP_REPLACE(r.title, r'\d{4}.*$', '')) = f.title
  JOIN
    omdb_dwh.dim_distributor AS d ON r.distributor = d.distributor
);

-- FACT_RATING
CREATE OR REPLACE TABLE omdb_dwh.fact_rating AS (
  SELECT
    f.id AS dim_film_id,
    rating.Source AS source,
    CASE
      WHEN REGEXP_CONTAINS(rating.Value, r'^(\d+(\.\d+)?)/10$') THEN
        rating.Value

      WHEN REGEXP_CONTAINS(rating.Value, r'^(\d+(?:\.\d+)?)%$') THEN
        FORMAT("%.1f/10", CAST(REGEXP_EXTRACT(rating.Value, r'^(\d+(?:\.\d+)?)%$') AS FLOAT64) / 10)

      WHEN REGEXP_CONTAINS(rating.Value, r'^(\d+(?:\.\d+)?)/100$') THEN
        FORMAT("%.1f/10", CAST(REGEXP_EXTRACT(rating.Value, r'^(\d+(?:\.\d+)?)/100$') AS FLOAT64) / 10)

      ELSE NULL
    END AS value
  FROM
    omdb_raw.film AS r,
    UNNEST(r.Ratings) AS rating
  JOIN
    omdb_dwh.dim_film AS f ON r.title = f.title
);

-- VIEW FOR FILM PERFORMANCE OVERVIEW
CREATE OR REPLACE VIEW omdb_dwh.film_performance_overview AS (
  WITH avg_rating AS (
    SELECT
      dim_film_id,
      ROUND(
        AVG(
          CAST(
            SPLIT(value,'/')[OFFSET(0)] AS FLOAT64
          )
        ),1
      ) AS avg_rating,
      COUNT(fact.source) AS sources
    FROM
      `future-minds-omdb.omdb_dwh.fact_rating` AS fact
    GROUP BY 1
  ),

  avg_theaters AS (
    SELECT
      dim_film_id,
      SAFE_CAST(
        ROUND(
          AVG(
            COALESCE(
              SAFE_CAST(theaters AS INT64),0
            )
          ),0
        ) AS INT64
      ) AS avg_theaters,
      SAFE_CAST(
        MAX(
          COALESCE(
            SAFE_CAST(theaters AS INT64),0
          )
        ) AS INT64
      ) AS max_theaters
    FROM
      `future-minds-omdb.omdb_dwh.fact_daily_revenue`
    GROUP BY 1
  )

  SELECT
    film.title AS title,
    avg_rating.avg_rating AS avg_rating,
    avg_rating.sources AS num_of_sources,
    film.box_office AS box_office,
    theaters.avg_theaters AS avg_num_of_theaters,
    theaters.max_theaters AS max_num_of_theaters
  FROM 
    avg_rating
  JOIN
    `future-minds-omdb.omdb_dwh.dim_film` AS film ON avg_rating.dim_film_id = film.id
  JOIN
    avg_theaters AS theaters ON avg_rating.dim_film_id = theaters.dim_film_id
);

-- VIEW FOR REVENUE TRACKER
CREATE OR REPLACE VIEW omdb_dwh.revenue_tracker_view AS (
  SELECT
    date,
    film.title AS title,
    SUM(COALESCE(SAFE_CAST(fact.theaters AS INT64),0)) AS theaters,
    SUM(COALESCE(fact.revenue,0)) AS revenue
  FROM
    omdb_dwh.fact_daily_revenue AS fact
  JOIN
    omdb_dwh.dim_film AS film ON fact.dim_film_id = film.id
  GROUP BY
    1,2
)