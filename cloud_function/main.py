import functions_framework
import requests
import json
from google.cloud import bigquery, storage
from datetime import datetime

API_KEY = 'd80ddb62'  # request_json['api_key']
BASE_URL = 'http://www.omdbapi.com/'
PROJECT_ID = 'future-minds-omdb'
DATASET_ID = 'omdb_raw'
TABLE_ID = 'film_raw'

@functions_framework.http
def ingest_omdb_film(request):
    request_json = request.get_json(silent=True)
    title = request_json['title']

    counter = 0
    bq_client = bigquery.Client()
    query = f"""
        SELECT DISTINCT
        TRIM(REGEXP_REPLACE(title, r'\d{4}.*$', '')) AS title
        FROM
        omdb_raw.revenues_per_day
        WHERE
        TRIM(REGEXP_REPLACE(title, r'\d{4}.*$', '')) NOT IN (
            SELECT
            title
            FROM
            omdb_raw.film
        )
    """
    query_job = bq_client.query(query)
    results = query_job.result()
    for row in results:
        counter+=1
        print(f"Processing: {row.title}, counter: {counter}")
        params = {
            't': row.title,
            'apikey': API_KEY
        }
        try:
            response = requests.get(BASE_URL, params=params, timeout=5)
            data = response.json()
            print(data)
            if data['Response'] == False:
                raise Exception
                return 'FAIL'
            bq_client.insert_rows_json(f'{DATASET_ID}.{TABLE_ID}',[data])
        except Exception as e:
            print(f"Error for title '{row.title}': {e}")

    return 'Success!'