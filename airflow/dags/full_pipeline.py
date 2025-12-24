import os
from datetime import timedelta
from dotenv import load_dotenv

import pendulum
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator

dag_folder = os.path.dirname(__file__)
env_path = os.path.join(dag_folder, ".env")
load_dotenv(env_path)

PROJECT_PATH = os.getenv("PROJECT_PATH")
DBT_HOST = os.getenv("DBT_HOST")
DBT_USER = os.getenv("DBT_USER")
DBT_PASSWORD = os.getenv("DBT_PASSWORD")
DBT_PORT = os.getenv("DBT_PORT")
DBT_DBNAME = os.getenv("DBT_DBNAME")
DBT_SCHEMA = os.getenv("DBT_SCHEMA")

GLUE_JOB_NAME = os.getenv("GLUE_JOB_NAME")
S3_OUTPUT_PATH = os.getenv("S3_OUTPUT_PATH")
RDS_ENDPOINT = os.getenv("RDS_ENDPOINT")
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")

DBT_ENV = {
    "DBT_PROFILES_DIR": f"{PROJECT_PATH}/dbt", # ชี้ไปที่ที่มี profiles.yml (ถ้าคุณย้ายมาใส่ในโปรเจค)
    # หรือถ้าใช้ env var ล้วนๆ
    "DBT_HOST": DBT_HOST,
    "DBT_USER": DBT_USER,
    "DBT_PASSWORD": DBT_PASSWORD,
    "DBT_PORT": DBT_PORT,
    "DBT_DBNAME": DBT_DBNAME,
    "DBT_SCHEMA": DBT_SCHEMA
}

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

@dag (
    dag_id="full_pipeline",
    default_args=default_args,
    description="""
                Load raw data from RDS to S3 in bronze zone
                -> Copy raw data to staging layer in Redshift
                -> Use DBT to transform and build data model in mart layer
                """,
    start_date=pendulum.today("UTC").add(days=-1),
    schedule="@daily",
    catchup=False,
    tags=["production"]
)

def run_dag():

    t1_glue_extract_rds_load_s3 = GlueJobOperator(
        task_id="glue_extract_rds_load_s3",
        job_name=GLUE_JOB_NAME,
        script_args={
            "--EXECUTION_DATE": "{{ ds }}",
            "--S3_OUTPUT_PATH": S3_OUTPUT_PATH,
            "--RDS_ENDPOINT": RDS_ENDPOINT,
            "--DB_NAME": DB_NAME,
            "--DB_USERNAME": DB_USERNAME,
            "--DB_PASSWORD": DB_PASSWORD 
        },
        wait_for_completion=True,
        verbose=True,
        aws_conn_id="aws_default",
        region_name="ap-southeast-1"
    )

    t2_load_s3_to_redshift = BashOperator(
        task_id="load_s3_to_redshift",
        bash_command=f"cd {PROJECT_PATH}/scripts && python3 load_s3_to_redshift_raw.py"
    )

    t3_dbt_run_model = BashOperator(
        task_id="dbt_run_model",
        bash_command=f"cd {PROJECT_PATH}/dbt && dbt run --profiles-dir .",
        env={**os.environ, **DBT_ENV}
    )

    t4_dbt_test_model = BashOperator(
        task_id="dbt_test_model",
        bash_command=f"cd {PROJECT_PATH}/dbt && dbt test",
        env={**os.environ, **DBT_ENV}
    )

    t1_glue_extract_rds_load_s3 >> t2_load_s3_to_redshift >> t3_dbt_run_model >> t4_dbt_test_model

run_dag()