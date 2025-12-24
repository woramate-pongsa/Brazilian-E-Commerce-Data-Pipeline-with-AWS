import pandas as pd
import numpy as np
import calendar

MONTH_MAPPING = {
    "2025-04": "2025-11",
    "2025-05": "2025-12",
    "2025-06": "2026-01",
    "2025-07": "2026-02",
    "2025-08": "2026-03",
    "2025-09": "2026-04",
    "2025-10": "2026-05",

    "2026-07": "2026-06",
    "2026-08": "2025-11",
    "2026-09": "2025-12",
    "2026-10": "2026-01",
    "2026-11": "2026-02",
    "2026-12": "2026-03",
}

month_map = {
    1: 7, 2: 8, 3: 9, 4: 10,
    5: 11, 6: 12, 7: 1, 8: 2,
    9: 3, 10: 4, 11: 5, 12: 6
}

table_clumns = {
    "leads_closed": "won_date",
    "leads_qualified": "first_contact_date",
    "order_items": "shipping_limit_date",
    "order_reviews": ["review_creation_date", "review_answer_timestamp"],
    "df_orders": [
        "order_purchase_timestamp", "order_approved_at",
        "order_delivered_carrier_date", "order_delivered_customer_date",
        "order_estimated_delivery_date"
    ]
}

path = "/workspaces/Data-Pipeline-AWS-Terraform/rds/csv_data/"

tables = {
    "leads_closed": pd.read_csv(f"{path}leads_closed.csv"),
    "leads_qualified": pd.read_csv(f"{path}leads_qualified.csv"),
    "order_items": pd.read_csv(f"{path}order_items.csv"),
    "order_reviews": pd.read_csv(f"{path}order_reviews.csv"),
    "df_orders": pd.read_csv(f"{path}orders.csv"),
}

paths = {
    "leads_closed": f"{path}leads_closed.csv",
    "leads_qualified": f"{path}leads_qualified.csv",
    "order_items": f"{path}order_items.csv",
    "order_reviews": f"{path}order_reviews.csv",
    "df_orders": f"{path}orders.csv",
}

# ============================================
# Helper: Apply Mapping Logic
# ============================================
def apply_month_mapping(dt):
    if pd.isna(dt):
        return dt
    
    key_ym = dt.strftime("%Y-%m")
    
    if key_ym in MONTH_MAPPING:
        target_ym = MONTH_MAPPING[key_ym]
        t_year, t_month = map(int, target_ym.split('-'))
        
        _, last_day_of_target_month = calendar.monthrange(t_year, t_month)
        
        new_day = min(dt.day, last_day_of_target_month)
        
        return dt.replace(year=t_year, month=t_month, day=new_day)
        
    return dt

# ============================================
# Core function: Transform single datetime col
# ============================================
def transform_datetime_column_safe(series: pd.Series) -> pd.Series:
    dt_series = pd.to_datetime(series, errors="coerce")

    dt_series_plus_days = dt_series + pd.Timedelta(days=3000)

    final_series = dt_series_plus_days.apply(apply_month_mapping)

    return final_series

# =======================================================
# Transform + Save Back
# =======================================================
def transform_and_save_tables(tables: dict, table_columns: dict, paths: dict):
    for name, df in tables.items():
        cols = table_columns[name]

        if isinstance(cols, str):
            target_cols = [cols]
        else:
            target_cols = cols
            
        for col in target_cols:
            print(f"Processing {name} -> {col}...")
            df[col] = transform_datetime_column_safe(df[col])
            
        df.to_csv(paths[name], index=False, encoding="utf-8")
        print(f"Saved transformed table: {name} -> {paths[name]}")

transform_and_save_tables(tables, table_clumns, paths)