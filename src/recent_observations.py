import os
import requests
import boto3
import time
import concurrent.futures

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
    """Function to get the most recent observations for a set of regions going back a number of specified days"""
    headers = api_setup()
    params = {'back': days}  # Specifies number of days to retrieve data for

    # Use a session for connection pooling
    with requests.Session() as session:
        session.headers.update(headers)

        def fetch_data(code):
            url = f"https://api.ebird.org/v2/data/obs/{code}/recent"
            response = session.get(url, params=params)
            return response.json()

        #Concurrently executing API requests 
        with concurrent.futures.ThreadPoolExecutor() as executor:
            results = executor.map(fetch_data, region_codes)

        #Iterate over each JSON response and each entry in a response to construct a list of responses
        data = [entry for result in results for entry in result]
       
        return data

def add_ttl(data: list) -> list:
    """This function adds a time to live attribute to each observation based on the observation date + 30 days"""
    data_with_ttl = []
    for entry in data:
        obs_timestamp = time.mktime(time.strptime(entry['obsDt'], "%Y-%m-%d %H:%M"))
        ttl_timestamp = int(obs_timestamp + (30*24*60*60)) #Add 30 days in seconds. TTL is in epoch time. 30 days * 24 hours * 60 minutes * 60 seconds
        entry['ttl'] = ttl_timestamp

        data_with_ttl.append(entry)
    
    return data_with_ttl

def connect_to_table():
    """Function to establish connection to the DDB table"""
    dynamodb = boto3.resource('dynamodb') #boto3 should check env for access keys automatically
    table_name = 'RecentObservations'
    table = dynamodb.Table(table_name)
    return table

def batch_write_obs(data: list, table) -> None:
    """Function to batch write items to the DDB table, which is more efficient from a read/write perspective than just put_item"""

    keys_to_include = ['speciesCode', 'comName', 'sciName', 'locId', 'locName', 'obsDt', 'howMany', 'lat', 'lng', 'subId', 'ttl']

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

# def update_recent_obs(data: list, table) -> None:
#     keys_to_include = ['speciesCode', 'comName', 'sciName', 'locId', 'locName', 'obsDt', 'howMany', 'lat', 'lng', 'subId']
    
#     for item in data:
#         dynamo_item = {}
#         for key in keys_to_include:
#             if key in item:
#                     # Convert lat and lng to strings
#                 value = str(item[key]) if key in ['lat', 'lng'] else item[key]
#                 dynamo_item[key] = value

    
#         table.update_item(
#             Key ={
#                 'subId': item['subId'],
#                 'speciesCode': item['speciesCode'] #Not complete. Read boto3 doc
#             }
#         )

if __name__ == "__main__":
    regions = get_regions('subnational2', ['US-VA','US-MD','US-DC'])
    get_recent_obs(1, regions)

