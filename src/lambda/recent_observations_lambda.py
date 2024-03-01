import requests
import boto3
import time
import concurrent.futures
from io import StringIO
import csv

def api_setup():

    """Function to set up headers for api call. Retrieves encrypted API key from Systems Manager Parameter Store"""

    parameter_name = "EBIRD_API_KEY"
    client = boto3.client('ssm')
    response = client.get_parameter(Name = parameter_name, WithDecryption =True)
    headers = {'X-eBirdApiToken': response['Parameter']['Value']}

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

def keys_to_s3(data):
    """This function retrieves all the unique values for species code and common name and stores them in s3 to later support filtering in the web app."""

    #Creating a set to keep only unique values of keys
    species_info = set()

    for item in data:
        #Retrieve only complete entries
        if 'speciesCode' in item and 'comName' in item:
            species_info.add((item['speciesCode'], item['comName']))

    #Create connection to s3
    s3 = boto3.client('s3')
    bucket_name = 'recent-observations-keys'
    file_name = 'recent_observation_keys.csv'

    headers = ['speciesCode', 'comName']

    #Retrieve keys from s3 if they exist. Otherwise start a set and add the column headers. 
    try:
        response = s3.get_object(Bucket = bucket_name, Key = file_name)
        existing_data = response['Body'].read().decode('utf-8-sig')
        reader = csv.reader(StringIO(existing_data))
        existing_keys = set(tuple(row) for row in reader if row != headers)

    except s3.exceptions.NoSuchKey:
        existing_keys = set()
    
    if not existing_keys:
        existing_keys.add(tuple(headers))

    #Union new keys with old keys and reappend headers
    updated_keys = existing_keys.union(species_info)

    updated_keys = sorted(list(updated_keys))

    updated_keys.insert(0, tuple(headers))

    #Write keys to a csv and send to s3
    with StringIO() as csv_output:
        csv_writer = csv.writer(csv_output)
        csv_writer.writerows(updated_keys)
        csv_content = csv_output.getvalue()

    s3.put_object(Bucket = bucket_name, Key = file_name, Body = csv_content, ContentType = 'text/csv')

def add_ttl(data: list) -> list:
    """This function adds a time to live attribute to each observation based on the observation date + 30 days"""
    data_with_ttl = []
    for entry in data:
        try:
            # Try parsing with hours and minutes
            obs_timestamp = time.mktime(time.strptime(entry['obsDt'], "%Y-%m-%d %H:%M"))
        except ValueError:
            # If parsing fails, try parsing without hours and minutes
            obs_timestamp = time.mktime(time.strptime(entry['obsDt'], "%Y-%m-%d"))
            
        ttl_timestamp = int(obs_timestamp + (30 * 24 * 60 * 60))  # Add 30 days in seconds. TTL is in epoch time.
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

    keys_to_include = ['comName', 'sciName', 'locName', 'obsDt', 'howMany', 'lat', 'lng', 'subId', 'ttl']

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

def lambda_handler(event, context):
    regions = get_regions('subnational2', ['US-VA', 'US-MD', 'US-DC'])
    data = get_recent_obs(1, regions)
    keys_to_s3(data)
    data_ttl = add_ttl(data)
    table = connect_to_table()
    batch_write_obs(data_ttl, table)

    return {
        'statusCode': 200,
        'body': 'Lambda function executed successfully.'
    }
