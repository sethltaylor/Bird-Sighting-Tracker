import os
import requests

def api_setup():

    """Function to set up headers for api call"""

    api_key = os.environ.get("EBIRD_API_KEY")
    headers = {'X-eBirdApiToken': api_key}

    return headers

def get_recent_obs():

    """Function to get the most recent observations for the US going back 30 days"""
    headers = api_setup()

    url = 'https://api.ebird.org/v2/data/obs/US/recent'
    params = {'back': 30} #Specifies getting data 30 days back
    response = requests.get(url, headers = headers, params = params)
    return response.json()
    
if __name__ == "__main__":
    get_recent_obs()
