import os
import requests
import boto3

def api_setup():

    """Function to set up headers for api call"""

    api_key = os.environ.get("EBIRD_API_KEY")
    headers = {'X-eBirdApiToken': api_key}

    return headers

def get_recent_obs(days: int) -> list:

    """Function to get the most recent observations for the US going back a number of specified days"""
    headers = api_setup()

    url = 'https://api.ebird.org/v2/data/obs/US/recent'
    params = {'back': days} #Specifies number of days to retrieve data for
    response = requests.get(url, headers = headers, params = params)
    data = response.json()
    return data

def connect_to_table():
    dynamodb = boto3.resource('dynamodb') #boto3 should check env for access keys automatically
    table_name = 'RecentObservations'
    table = dynamodb.Table(table_name)
    return table

def batch_write_data(data: list, table) -> None:
    with table.batch_writer() as writer:
        for item in data:
            writer.put_item(
                Item={
                'speciesCode': item['speciesCode'],
                'obsDt': item['obsDt'],
                'comName': item['comName'],
                'sciName': item['sciName'],
                'locId': item['locId'],
                'locName': item['locName'],
                'howMany': item['howMany'], 
                'lat': str(item['lat']),  # Lat/Long converted to string because DDB doesn't handle floats
                'lng': str(item['lng']),  
                'obsValid': item['obsValid'],
                'obsReviewed': item['obsReviewed'],
                'locationPrivate': item['locationPrivate'],
                'subId': item['subId'],
                }
                )

#if __name__ == "__main__":
    #data = get_recent_obs()
    #table = connect_to_table()
    #batch_write_data(data, table)

