FROM python:3.10-slim

WORKDIR /app

COPY ./requirements.txt /app/requirements.txt
COPY ./streamlit_app.py /app/streamlit_app.py

RUN apt-get update && apt-get install -y curl && pip3 install -r /app/requirements.txt

EXPOSE 8501

HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

ENTRYPOINT ["streamlit", "run", "streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]
