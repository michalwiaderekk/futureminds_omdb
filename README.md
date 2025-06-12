# futureminds_omdb
Recruitment task for Future Mind

1. Data Warehouse based on `revenues_per_day.csv` file and OMDb API data. 

Data model contains 2 fact tables and 8 dimesions. Below is a description of each table:
- dim_film - stores detailed information about films,
- dim_genre - stores the list of film genres,
- film_genre - a bridge table connecting dim_film and dim_genre
- dim_person - stores the list about people involved in film production,
- dim_director/actor/writer - bridge tables connecting dim_film with dim_person, specyfing roles of individuals of each film,
- dim_distributor - stores the list of film distributor
- fact_daily_revenue - stores daily revenue data for each film, including distributor and number of theaters,
- fact_rating - stores ratings of films with their sources (e.g. IMDB, Rotten Tomatoes)

Declarations of each table are in create_dwh.sql file. The CREATE scripts include SQL queries with all necessary transformations.

2. Pipeline ingesting OMDb API data to BigQuery

The ingestion pipeline is implemented using Google Cloud Functions. The source code is located under the 'cloud_function/' directory.

The pipeline uses titles from the 'revenues_per_day.csv' file to fetch data from the OMDB API. The fetched data is loaded into the `omdb_raw.film_temp` table using the insert_rows_json(table, data[]) method. The function is scheduled and triggered via Cloud Scheduler.

To avoid duplicated rows, only films not present in the `omdb_raw.film` table are fetched.

In linked path there are all files that are needed to create this Cloud Function via Cloud Build. Also, this cloud functions uses variables and secret from secret manager.

3. Dashboards

Here are all links to looker studio where all dashboards based on data model:
- https://lookerstudio.google.com/reporting/a50820f0-795c-441e-804a-5326c2d222c7 - Country and language impact on film revenue - A heat map showing regions and languages with the highest revenue performance
- https://lookerstudio.google.com/reporting/af8bf373-08e5-4fcb-9047-4bd6f949ac2b - Title and Person impact on revenue - Analyzes how specific titles or cast members affect a film's earnings
- https://lookerstudio.google.com/reporting/5ad15b7b-9fa3-4015-a3f7-277b0490875c - Revenue Tracker Dashboard - Tracks daily film revenue across multiple dimensions