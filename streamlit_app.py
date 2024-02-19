import streamlit as st
import pandas as pd 
import boto3
import pydeck as pdk
from datetime import datetime

st.set_page_config(layout="wide", page_title = "Bird Sightings in DC, Maryland, and Virginia", page_icon= ":bird:")

#Functions to get data
def query_bird_sightings(common_name_selection, start_date_str, end_date_str):
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

#Add sidebar for data filter selection
with st.sidebar:
    st.sidebar.title('Inputs for Mapping')
    common_names = fetch_common_names('recent-observations-keys', 'recent_observation_keys.csv')

    common_name_selection = st.selectbox('Select a bird', options = common_names['comName'].unique())
    
    start_date_selection = st.date_input('Start Date for Sightings Search', value = pd.to_datetime('today') - pd.Timedelta(days=30))
    st.caption('Data is available for the past 30 days.')
    end_date_selection = st.date_input('End Date for Sightings Search', value = pd.to_datetime('today'))

    #Check if end date is after start date. 
    if end_date_selection < start_date_selection:
        st.error('Error: End date must be after start date')

    #Setting end date to be the latest value in the day and start date to be the earliest time in the day to support intra-day querying. 
    start_datetime = datetime.combine(start_date_selection, datetime.min.time())
    end_datetime = datetime.combine(end_date_selection, datetime.max.time())

    start_date_str = start_datetime.strftime('%Y-%m-%d %H:%M')
    end_date_str = end_datetime.strftime('%Y-%m-%d %H:%M')

#Add tabs

tab1, tab2 = st.tabs(["Bird Sightings", "About"])

with tab1:
    st.title('Bird Sightings in the DMV Area')

    #Map sightings
    if st.button('Show Sightings'):
        filtered_df = query_bird_sightings(common_name_selection, start_date_str, end_date_str)

        if not filtered_df.empty:
            #Perform data cleaning/converstion
            filtered_df = filtered_df.astype({'lng':'float', 'lat':'float'})
            filtered_df['howMany'] = pd.to_numeric(filtered_df['howMany'], errors = 'coerce')
            filtered_df['howMany'].fillna(1, inplace= True)

            #Create mapping dictionary 
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

        else:
            st.write(f"No {common_name_selection} were sighted between {start_date_str} and {end_date_str}.")

with tab2:
    st.title("About")
    st.write("This app is developed by Seth Taylor.")
    st.markdown("""
        <a href="https://www.linkedin.com/in/seth-taylor-3106486b/" target="_blank">
            <img src="https://content.linkedin.com/content/dam/me/business/en-us/amp/brand-site/v2/bg/LI-Bug.svg.original.svg" width="30" height="30" style="margin-right: 10px;">LinkedIn Profile
        </a><br>
        <a href="https://github.com/sethltaylor" target="_blank">
            <img src="https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/svgs/brands/github.svg" width="30" height="30" style="margin-right: 10px;">GitHub Profile
        </a>
        """, unsafe_allow_html=True)