import os
import sqlite3
import pandas as pd
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

SQLITE_PATH = os.environ.get("SQLITE_PATH")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR")

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

sqlite_conn = sqlite3.connect(SQLITE_PATH)

print("Exporting schema...")
with open(os.path.join(OUTPUT_DIR, "schema.sql"), "w") as f:
    for line in sqlite_conn.iterdump():
        if "CREATE TABLE" in line:
            f.write(f"{line}\n")

tables = ["customers", "geolocation", "leads_closed", "leads_qualified", "order_items", "order_payments",
          "order_reviews", "orders", "product_category_name_translation", "products", "sellers"]

for table in tables:
    print(f"Exporting table: {table}")
    try:
        df = pd.read_sql_query(f"SELECT * FROM {table}", sqlite_conn)
                
        output_path = os.path.join(OUTPUT_DIR, f"{table}.csv")
        df.to_csv(output_path, index=False, header=True)
        
        print(f"Successfully exported {table} to {output_path}")

    except Exception as e:
        print(f"Error exporting {table}: {e}")

sqlite_conn.close()
print("All files exported successfully!")