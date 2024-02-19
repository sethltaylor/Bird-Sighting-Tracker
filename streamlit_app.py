import streamlit as st
import pandas as pd 
import boto3
import pydeck as pdk
from datetime import datetime
from decimal import Decimal

st.set_page_config(layout="wide", page_title = "Bird Sightings in DC, Maryland, and Virginia", page_icon= ":bird:")

def query_bird_sightings(common_name, start_date, end_date):
    dynamodb = boto3.resource('dynamodb')
    table_name = 'RecentObservations'
    table = dynamodb.Table(table_name)

    response = table.query(
        IndexName = 'comName-obsDt-index',
        Select = 'ALL_ATTRIBUTES',
        KeyConditionExpression = "comName = :common_name AND obsDt BETWEEN :start_date AND :end_date",
        ExpressionAttributeValues = {
            ':common_name': common_name_selection,
            ':start_date': start_date_str, 
            ':end_date': end_date_str,
        }
    )
    
    items = response['Items']
    
    df = pd.DataFrame(items)
    return df

def fetch_common_names(bucket_name, file_name):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket = bucket_name, Key= file_name)
    common_names = pd.read_csv(response['Body'])
    return common_names

#Streamlit UI
st.title('Bird Sightings in the DMV Area')

common_names = fetch_common_names('recent-observations-keys', 'recent_observation_keys.csv')

common_name_selection = st.selectbox('Select a bird', options = common_names['comName'].unique())
start_date_selection = st.date_input('Start Date for Sightings Search', value = pd.to_datetime('today') - pd.Timedelta(days=30))
st.caption('Data is available for the past 30 days.')
end_date_selection = st.date_input('End Date for Sightings Search', value = pd.to_datetime('today'))

#Convert dates to strings to support query
start_date_str = start_date_selection.strftime('%Y-%m-%d')
end_date_str = end_date_selection.strftime('%Y-%m-%d')

#Map sightings
if st.button('Show Sightings'):
    filtered_df = query_bird_sightings(common_name_selection, start_date_str, end_date_str)

    #Perform data cleaning/converstion
    filtered_df = filtered_df.astype({'lng':'float', 'lat':'float'})
    filtered_df['howMany'] = pd.to_numeric(filtered_df['howMany'], errors = 'coerce')
    filtered_df['howMany'].fillna(1, inplace= True)

    if not filtered_df.empty:
        data_dict = filtered_df[['lat', 'lng', 'locName', 'howMany']].to_dict(orient='records')

        # Pydeck map
        layer = pdk.Layer(
            "ScatterplotLayer",
            data_dict,
            get_position="[lng, lat]",
            get_color="[200, 30, 0, 160]",
            get_radius=2000,
            pickable=True,
        )

        view_state = pdk.ViewState(
            latitude= filtered_df['lat'].mean(),
            longitude= filtered_df['lng'].mean(),
            zoom=6,
            pitch=0,
        )

        deck = pdk.Deck(
            layers=[layer],
            initial_view_state=view_state,
            map_style='mapbox://styles/mapbox/light-v10',
            tooltip = {
                "html": "<b>Location:</b> {locName} <br/> <b>Number of Birds Sighted:</b> {howMany}",
                "style": {
                    "backgroundColor": "steelblue",
                    "color": "white"
   }
}
        )

        st.pydeck_chart(deck)
    
    #Calculate average number of sightings
    st.subheader(f"Total number of {common_name_selection} sighted between {start_date_str} and {end_date_str}")
    st.write(round(filtered_df['howMany'].sum()))

    st.dataframe(filtered_df)
