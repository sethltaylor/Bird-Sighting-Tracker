import streamlit as st
import pandas as pd 
import boto3

st.set_page_config(layout="wide", page_title = "Bird Sightings in the DC, Maryland, Virginia (DMV) Area", page_icon= ":bird:")

def load_recent_obs():
    dynamodb = boto3.resource('dynamodb')
    table_name = 'RecentObservations'
    table = dynamodb.Table(table_name)

    response = table.scan()
    
    return response
