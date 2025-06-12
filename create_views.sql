CREATE OR REPLACE VIEW omdb_dwh.person_title_rating_view AS (with persons_roles AS (
      SELECT
        dim_film_id,
        dim_person_id,
        'actor' AS role
      FROM `future-minds-omdb.omdb_dwh.dim_actor`
      UNION ALL 
      SELECT
        dim_film_id,
        dim_person_id,
        'director' AS role
      FROM `future-minds-omdb.omdb_dwh.dim_director`
      UNION ALL
      SELECT
        dim_film_id,
        dim_person_id,
        'writer' AS role
      FROM `future-minds-omdb.omdb_dwh.dim_writer`
)


SELECT
  p.name,
  f.title,
  ROUND(
        AVG(
          CAST(
            SPLIT(value,'/')[OFFSET(0)] AS FLOAT64
          )
        ),1
      ) AS avg_rating
FROM
  omdb_dwh.dim_person AS p
JOIN
  persons_roles ON p.id = persons_roles.dim_person_id
JOIN
  omdb_dwh.dim_film AS f ON persons_roles.dim_film_id = f.id
JOIN
  omdb_dwh.fact_rating AS fr ON fr.dim_film_id = f.id
GROUP by 1,2)


CREATE OR REPLACE VIEW omdb_dwh.film_country_view AS (WITH film_country AS (
  SELECT
    id,
    title,
    TRIM(country) AS country
  FROM
    omdb_dwh.dim_film,
    UNNEST(SPLIT(Country, ',')) AS country
)

SELECT
  fc.title AS title,
  fc.country AS country,
  SUM(fdr.revenue) AS revenue
FROM
  film_country AS fc
JOIN
  omdb_dwh.fact_daily_revenue AS fdr ON fc.id = fdr.dim_film_id
GROUP BY 1,2);

CREATE OR REPLACE VIEW omdb_dwh.film_language_view AS (
  WITH film_language AS (
    SELECT
      id,
      title,
      TRIM(language) AS language
    FROM
      omdb_dwh.dim_film,
      UNNEST(SPLIT(language, ',')) AS language
  )
  SELECT
    fl.title AS title,
    fl.language AS language,
    SUM(fdr.revenue) AS revenue
  FROM
    film_language AS fl
  JOIN
    omdb_dwh.fact_daily_revenue AS fdr ON fl.id = fdr.dim_film_id
  GROUP BY 1,2
)

CREATE OR REPLACE VIEW omdb_dwh.director_film_revenue_view AS (SELECT
  f.title,
  p.name,
  SUM(fdr.revenue) AS revenue
FROM
  `future-minds-omdb.omdb_dwh.dim_director` AS d
JOIN
  omdb_dwh.dim_film AS f ON d.dim_film_id = f.id
JOIN
  omdb_dwh.dim_person AS p ON d.dim_person_id = p.id
JOIN
  omdb_dwh.fact_daily_revenue AS fdr ON fdr.dim_film_id = f.id
GROUP BY 1,2);

CREATE OR REPLACE VIEW omdb_dwh.actor_film_revenue_view AS (SELECT
  f.title,
  p.name,
  SUM(fdr.revenue) AS revenue
FROM
  `future-minds-omdb.omdb_dwh.dim_actor` AS d
JOIN
  omdb_dwh.dim_film AS f ON d.dim_film_id = f.id
JOIN
  omdb_dwh.dim_person AS p ON d.dim_person_id = p.id
JOIN
  omdb_dwh.fact_daily_revenue AS fdr ON fdr.dim_film_id = f.id
GROUP BY 1,2);

CREATE OR REPLACE VIEW omdb_dwh.writer_film_revenue_view AS (SELECT
  f.title,
  p.name,
  SUM(fdr.revenue) AS revenue
FROM
  `future-minds-omdb.omdb_dwh.dim_writer` AS d
JOIN
  omdb_dwh.dim_film AS f ON d.dim_film_id = f.id
JOIN
  omdb_dwh.dim_person AS p ON d.dim_person_id = p.id
JOIN
  omdb_dwh.fact_daily_revenue AS fdr ON fdr.dim_film_id = f.id
GROUP BY 1,2)

CREATE OR REPLACE VIEW omdb_dwh.film_genres_view AS (
  SELECT
    f.title AS title,
    STRING_AGG(g.genre,', ') AS genres
  FROM
    omdb_dwh.film_genre AS fg
  JOIN
    omdb_dwh.dim_film AS f ON f.id = fg.dim_film_id
  JOIN
    omdb_dwh.dim_genre AS g ON g.id = fg.dim_genre_id
  GROUP BY 1
)

CREATE OR REPLACE VIEW omdb_dwh.revenue_for_genre AS (
  SELECT
    g.genre AS genre,
    SUM(fdr.revenue) AS revenue
  FROM
    omdb_dwh.film_genre AS fg
  JOIN
    omdb_dwh.dim_genre AS g ON fg.dim_genre_id = g.id
  JOIN
    omdb_dwh.dim_film AS f ON fg.dim_film_id = f.id
  JOIN
    omdb_dwh.fact_daily_revenue AS fdr ON f.id = fdr.dim_film_id
  GROUP BY 1
  ORDER BY 
    revenue DESC
)

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