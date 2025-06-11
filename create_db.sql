-- CREATING film table
CREATE OR REPLACE TABLE omdb_raw.film_raw (
  Title STRING,
  Year STRING,
  Rated STRING,
  Released STRING,
  Runtime STRING,
  Genre STRING,
  Director STRING,
  Writer STRING,
  Actors STRING,
  Plot STRING,
  Language STRING,
  Country STRING,
  Awards STRING,
  Poster STRING,
  Ratings ARRAY<STRUCT<Source STRING, Value STRING>>,
  Metascore STRING,
  imdbRating STRING,
  imdbVotes STRING,
  imdbID STRING,
  Type STRING,
  DVD STRING,
  BoxOffice STRING,
  Production STRING,
  Website STRING,
  Response STRING,
  totalSeasons STRING
)

CREATE OR REPLACE TABLE omdb_raw.film (
  Title STRING,
  Year STRING,
  Rated STRING,
  Released STRING,
  Runtime STRING,
  Genre STRING,
  Director STRING,
  Writer STRING,
  Actors STRING,
  Plot STRING,
  Language STRING,
  Country STRING,
  Awards STRING,
  Poster STRING,
  Ratings ARRAY<STRUCT<Source STRING, Value STRING>>,
  Metascore STRING,
  imdbRating STRING,
  imdbVotes STRING,
  imdbID STRING,
  Type STRING,
  DVD STRING,
  BoxOffice STRING,
  Production STRING,
  Website STRING,
  Response STRING,
  totalSeasons STRING
);

-- CREATING revenues_per_day
CREATE OR REPLACE EXTERNAL TABLE omdb_raw.revenues_per_day_ext (
  id STRING,
  date DATE,
  title STRING,
  revenue INT64,
  theaters STRING,
  distributor STRING
) OPTIONS (
  format = 'CSV',
  uris = ['gs://michal-wiaderek-omdb-files/revenues_per_day.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE omdb_raw.revenues_per_day (
  id STRING,
  date DATE,
  title STRING,
  revenue INT64,
  theaters STRING,
  distributor STRING
);