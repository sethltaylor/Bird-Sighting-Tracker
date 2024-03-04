import os
import requests
import pytest
from src.recent_observations import api_setup

@pytest.fixture
def api_key():
    return os.environ.get('EBIRD_API_KEY')

def test_api_setup(api_key):
    headers = api_setup()

    assert 'X-eBirdApiToken' in headers
    assert headers['X-eBirdApiToken'] == api_key

def test_api_connection():
    response = requests.get('https://api.ebird.org/v2/data/obs/US/recent', headers = api_setup())

    assert response.status_code == 200
