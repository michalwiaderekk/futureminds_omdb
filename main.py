import requests

API_KEY = 'd80ddb62' 
BASE_URL = 'http://www.omdbapi.com/'

def search_movie(title):
    params = {
        'apikey': API_KEY,
        't': title  
    }

    try:
        response = requests.get(BASE_URL, params=params)
        response.raise_for_status()
        data = response.json()

    except Exception as e:
        print(f'Błąd połączenia: {e}')
