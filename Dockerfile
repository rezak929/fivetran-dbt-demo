FROM python:3.11-slim

WORKDIR /dbt

RUN pip install --no-cache-dir dbt-snowflake==1.9.0

COPY profiles.yml .
COPY dbt_project.yml .
COPY models/ models/

ENV SNOWFLAKE_PRIVATE_KEY_PATH=/secrets/snowflake_private_key.pem

CMD ["dbt", "run", "--profiles-dir", "."]
