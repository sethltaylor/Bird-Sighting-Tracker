import os
import requests

def api_setup():
    """Function to set up headers for api call"""
    api_key = os.getenv("EBIRD_API_KEY")
    headers = {'X-eBirdApiToken': api_key}

    return headers

def get_recent_obs():
    headers = api_setup()

    url = 'https://api.ebird.org/v2/data/obs/US/recent'
    params = {'back': 30} #Specifies getting data 30 days back
    response = requests.get(url, headers = headers, params = params)
  
    return response.json()
    
    

if __name__ == "__main__":
    get_recent_obs()