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
    print(len(data))
    return data

def connect_to_table():
    """Function to establish connection to the DDB table"""
    dynamodb = boto3.resource('dynamodb') #boto3 should check env for access keys automatically
    table_name = 'RecentObservations'
    table = dynamodb.Table(table_name)
    return table

def batch_write_obs(data: list, table) -> None:
    """Function to batch write items to the DDB table, which is more efficient from a read/write perspective than just put_item"""

    keys_to_include = ['speciesCode', 'comName', 'sciName', 'locId', 'locName', 'obsDt', 'howMany', 'lat', 'lng', 'obsValid', 'obsReviewed', 'locationPrivate', 'subId']

    with table.batch_writer() as writer:
        for item in data:
            dynamo_item = {}

        # Iterate through the keys and add them to the dynamo_item if they exist
            for key in keys_to_include:
                if key in item:
                # Convert lat and lng to strings
                    value = str(item[key]) if key in ['lat', 'lng'] else item[key]
                    dynamo_item[key] = value

        # Write the item to the DDB table 
            writer.put_item(
                Item=dynamo_item
            )

def update_recent_obs(data: list, table) -> None:
    keys_to_include = ['speciesCode', 'comName', 'sciName', 'locId', 'locName', 'obsDt', 'howMany', 'lat', 'lng', 'obsValid', 'obsReviewed', 'locationPrivate', 'subId']
    
    for item in data:
        dynamo_item = {}
        for key in keys_to_include:
            if key in item:
                    # Convert lat and lng to strings
                value = str(item[key]) if key in ['lat', 'lng'] else item[key]
                dynamo_item[key] = value

    
        table.update_item(
            Key ={
                'subId': item['subId'],
                'speciesCode': item['speciesCode'] #Not complete. Read boto3 doc
            }
        )

if __name__ == "__main__":
    data = get_recent_obs(30)
    table = connect_to_table()
    batch_write_obs(data, table)

