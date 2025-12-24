import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from datetime import datetime, timedelta

# Config table metadata 
TABLE_CONFIG = {
    # Incremental (have datetime)
    "orders":          {"domain": "sales",    "mode": "incremental", "date_col": "order_purchase_timestamp"},
    "order_reviews":   {"domain": "sales",    "mode": "incremental", "date_col": "review_creation_date"},
    "order_items":     {"domain": "sales",    "mode": "incremental", "date_col": "shipping_limit_date"},
    "leads_closed":    {"domain": "customer", "mode": "incremental", "date_col": "won_date"},
    "leads_qualified": {"domain": "customer", "mode": "incremental", "date_col": "first_contact_date"},

    # Full Snapshot (don't have -> full load)
    "customers":       {"domain": "customer", "mode": "full"},
    "geolocation":     {"domain": "customer", "mode": "full"},
    "products":        {"domain": "catalog",  "mode": "full"},
    "sellers":         {"domain": "catalog",  "mode": "full"},
    "product_category_name_translation": {"domain": "catalog", "mode": "full"},
    "order_payments":  {"domain": "sales",    "mode": "full"} 
}

# Job Arguments
try:
    args = getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'S3_OUTPUT_PATH',
        'RDS_ENDPOINT',
        'DB_NAME',
        'DB_USERNAME',
        'DB_PASSWORD'
    ])
    
    try:
        date_args = getResolvedOptions(sys.argv, ['EXECUTION_DATE'])
        exec_date_str = date_args['EXECUTION_DATE']
        print(f"Manual/Airflow Date Provided: {exec_date_str}")
    except:
        exec_date_str = datetime.now().strftime("%Y-%m-%d")
        print(f"No EXECUTION_DATE provided. Defaulting to TODAY: {exec_date_str}")

    exec_date = datetime.strptime(exec_date_str, "%Y-%m-%d")
    next_date = exec_date + timedelta(days=1)
    next_date_str = next_date.strftime("%Y-%m-%d")

    p_year = exec_date.strftime("%Y")
    p_month = exec_date.strftime("%m")
    p_day = exec_date.strftime("%d")

    print(f"Job started for date: {exec_date_str}")
    print(f"Target S3 Partition: year={p_year}/month={p_month}/day={p_day}")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)

# Init Spark
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Config Connection
jdbc_url = f"jdbc:postgresql://{args['RDS_ENDPOINT']}:5432/{args['DB_NAME']}"
connection_properties = {
    "user": args['DB_USERNAME'],
    "password": args['DB_PASSWORD'],
    "driver": "org.postgresql.Driver"
}

for table_name, config in TABLE_CONFIG.items():
    try:
        print(f"\n--- Processing: {table_name} ({config['mode']}) ---")
        
        if config['mode'] == 'incremental':
            query = f"""
                (SELECT * FROM public.{table_name} 
                 WHERE {config['date_col']} >= '{exec_date_str}' 
                 AND {config['date_col']} < '{next_date_str}') as tmp
            """
        else:
            query = f"public.{table_name}"

        print(f"Reading from RDS")
        
        df = spark.read.jdbc(
            url=jdbc_url,
            table=query,
            properties=connection_properties
        )
        
        count = df.count()
        print(f"Read success. All row: {count}")
        
        if count > 0:
            domain = config['domain']
            target_path = f"{args['S3_OUTPUT_PATH']}bronze/{domain}/{table_name}/year={p_year}/month={p_month}/day={p_day}/"
            
            print(f"💾 Writing to: {target_path}")
            
            # Write to Parquet
            df.write.mode("overwrite").parquet(target_path)
                
            print(f"Finished loading {table_name}")
        else:
            print(f"Table {table_name} has no data for this date/batch. Skipping write.")

    except Exception as e:
        print(f"ERROR processing {table_name}: {e}")

job.commit()
print("\nJOB FINISHED")