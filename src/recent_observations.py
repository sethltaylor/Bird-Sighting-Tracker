import os
import requests
import boto3

def api_setup():

    """Function to set up headers for api call"""

    api_key = os.environ.get("EBIRD_API_KEY")
    headers = {'X-eBirdApiToken': api_key}

    return headers

def get_regions(region_type: str, parent_codes: list) -> list:
    """This function returns a list of eBird regions for a specified region type (country, subnational1, subnational2)
       and a list of parent region codes (e.g., 'US' or 'US-VA')"""
    
    header = api_setup()
    params = {'fmt':'json'}
    region_codes = []
    for code in parent_codes:
        url = f"https://api.ebird.org/v2/ref/region/list/{region_type}/{code}"
        response = requests.get(url, headers = header, params=params)
        sub_codes = [item['code'] for item in response.json()]
        region_codes.extend(sub_codes)
    
    return region_codes
    

def get_recent_obs(days: int, region_codes: list) -> list:

    """Function to get the most recent observations for a set of  going back a number of specified days"""
    headers = api_setup()
    params = {'back': days}  #Specifies number of days to retrieve data for

    data = []
    for code in region_codes:
        url = f"https://api.ebird.org/v2/data/obs/{code}/recent"
        response = requests.get(url, headers = headers, params = params)
        data.extend(response.json())
        print(f"Retrieved data for {code}")

    print(data) 
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
        
            print(f"Wrote {len(data)} items to table.")

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
    regions = get_regions('subnational2', ['US-VA','US-MD','US-DC'])
    get_recent_obs(1, regions)

