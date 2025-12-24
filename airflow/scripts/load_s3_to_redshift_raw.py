import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

# CONFIG
REDSHIFT_HOST = os.getenv("REDSHIFT_ENDPOINT").replace(":5432", "").replace(":5439", "")
REDSHIFT_PORT = "5439"
REDSHIFT_DB = os.getenv("DB_NAME")
REDSHIFT_USER = os.getenv("DB_USERNAME")
REDSHIFT_PASS = os.getenv("DB_PASSWORD")
IAM_ROLE_ARN = os.getenv("REDSHIFT_IAM_ROLE_ARN")
BUCKET_NAME = os.getenv("S3_BUCKET_NAME")

# Config Table Schema
TABLES_CONFIG = {
    "customers": {
        "domain": "customer",
        "schema": """
            customer_id VARCHAR(32),
            customer_unique_id VARCHAR(32),
            customer_zip_code_prefix INT,
            customer_city VARCHAR(100),
            customer_state VARCHAR(5)
        """
    },
    "geolocation": {
        "domain": "customer",
        "schema": """
            geolocation_zip_code_prefix INT,
            geolocation_lat FLOAT,
            geolocation_lng FLOAT,
            geolocation_city VARCHAR(100),
            geolocation_state VARCHAR(5)
        """
    },
    "leads_closed": {
        "domain": "customer",
        "schema": """
            mql_id VARCHAR(32),
            seller_id VARCHAR(32),
            sdr_id VARCHAR(32),
            sr_id VARCHAR(32),
            won_date VARCHAR(50),
            business_segment VARCHAR(50),
            lead_type VARCHAR(50),
            lead_behaviour_profile VARCHAR(50),
            has_company VARCHAR(32),
            has_gtin VARCHAR(32),
            average_stock VARCHAR(50),
            business_type VARCHAR(50),
            declared_product_catalog_size FLOAT,
            declared_monthly_revenue FLOAT
        """
    },
    "leads_qualified": {
        "domain": "customer",
        "schema": """
            mql_id VARCHAR(32),
            first_contact_date VARCHAR(50),
            landing_page_id VARCHAR(32),
            origin VARCHAR(50)
        """
    },
    "orders": {
        "domain": "sales",
        "schema": """
            order_id VARCHAR(32),
            customer_id VARCHAR(32),
            order_status VARCHAR(20),
            order_purchase_timestamp VARCHAR(50),
            order_approved_at VARCHAR(50),
            order_delivered_carrier_date VARCHAR(50),
            order_delivered_customer_date VARCHAR(50),
            order_estimated_delivery_date VARCHAR(50)
        """
    },
    "order_items": {
        "domain": "sales",
        "schema": """
            order_id VARCHAR(32),
            order_item_id INT,
            product_id VARCHAR(32),
            seller_id VARCHAR(32),
            shipping_limit_date VARCHAR(50),
            price FLOAT,
            freight_value FLOAT
        """
    },
    "order_payments": {
        "domain": "sales",
        "schema": """
            order_id VARCHAR(32),
            payment_sequential INT,
            payment_type VARCHAR(20),
            payment_installments INT,
            payment_value FLOAT
        """
    },
    "order_reviews": {
        "domain": "sales",
        "schema": """
            review_id VARCHAR(32),
            order_id VARCHAR(32),
            review_score INT,
            review_comment_title VARCHAR(255),
            review_comment_message VARCHAR(65535),
            review_creation_date VARCHAR(50),
            review_answer_timestamp VARCHAR(50)
        """
    },
    "products": {
        "domain": "catalog",
        "schema": """
            product_id VARCHAR(32),
            product_category_name VARCHAR(100),
            product_name_lenght FLOAT,
            product_description_lenght FLOAT,
            product_photos_qty FLOAT,
            product_weight_g FLOAT,
            product_length_cm FLOAT,
            product_height_cm FLOAT,
            product_width_cm FLOAT
        """
    },
    "sellers": {
        "domain": "catalog",
        "schema": """
            seller_id VARCHAR(32),
            seller_zip_code_prefix INT,
            seller_city VARCHAR(100),
            seller_state VARCHAR(5)
        """
    },
    "product_category_name_translation": {
        "domain": "catalog",
        "schema": """
            product_category_name VARCHAR(100),
            product_category_name_english VARCHAR(100)
        """
    }
}

def run_redshift_setup():
    try:
        print(f"Connecting to Redshift at {REDSHIFT_HOST}")
        conn = psycopg2.connect(
            dbname=REDSHIFT_DB,
            user=REDSHIFT_USER,
            password=REDSHIFT_PASS,
            host=REDSHIFT_HOST,
            port=REDSHIFT_PORT
        )
        cur = conn.cursor()
        print("Connected")

        # Schema 'Raw' (for raw data)
        print("\nStep 1: Create Schema")
        cur.execute("CREATE SCHEMA IF NOT EXISTS raw_data;")
        print("Schema 'raw' created")

        # Loop for create each table
        print("\n--- Step 2: Create Tables & COPY Data ---")
        for table_name, config in TABLES_CONFIG.items():
            print(f"\nProcessing table: {table_name}")
            
            cur.execute(f"DROP TABLE IF EXISTS raw_data.{table_name};")
            
            create_query = f"""
                CREATE TABLE raw_data.{table_name} (
                    {config['schema']}
                );
            """
            cur.execute(create_query)
            print(f"   -> Table created.")

            s3_path = f"s3://{BUCKET_NAME}/bronze/{config['domain']}/{table_name}/"
            
            copy_query = f"""
                COPY raw_data.{table_name}
                FROM '{s3_path}'
                IAM_ROLE '{IAM_ROLE_ARN}'
                FORMAT AS PARQUET;
            """
            
            print(f"Copying data from {s3_path}...")
            try:
                cur.execute(copy_query)
                print(f"COPY Success")
            except Exception as e:
                print(f"COPY Failed: {e}")
                conn.rollback()
                continue

            conn.commit()

        print("\Loading to Raw data is ready.")

    except Exception as e:
        print(f"❌ Critical Error: {e}")
    finally:
        if conn:
            cur.close()
            conn.close()

if __name__ == "__main__":
    run_redshift_setup()