# ── Load Superstore CSV into MySQL ──
import pandas as pd
import mysql.connector
from mysql.connector import Error

# ── 1. Connect to MySQL ──
conn = mysql.connector.connect(
    host     = 'localhost',
    user     = 'root',
    password = 'Sai@2003',  # ← change this
    database = 'superstore_sales'
)
cursor = conn.cursor()
print("✅ Connected to MySQL!")
# ── 2. Load CSV ──
df = pd.read_csv(
    r'C:\Users\hemas\OneDrive\Desktop\sql-sales-project\datasets\Sample - Superstore.csv',
    encoding='latin1'
)
print(f"✅ CSV loaded: {df.shape[0]} rows")

# ── 3. Clean column names ──
df.columns = (df.columns
              .str.strip()
              .str.lower()
              .str.replace(' ', '_')
              .str.replace('-', '_'))

# ── 4. Fix date columns ──
df['order_date'] = pd.to_datetime(df['order_date']).dt.date
df['ship_date']  = pd.to_datetime(df['ship_date']).dt.date

print("Columns:", df.columns.tolist())

# ── 5. Insert CUSTOMERS ──
customers = df[['customer_id','customer_name',
                'segment','country','city',
                'state','postal_code','region']].drop_duplicates()

customer_sql = """
    INSERT IGNORE INTO customers
    (customer_id, customer_name, segment,
     country, city, state, postal_code, region)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
"""
for _, row in customers.iterrows():
    cursor.execute(customer_sql, tuple(row))
conn.commit()
print(f"✅ Customers inserted: {len(customers)}")

# ── 6. Insert PRODUCTS ──
products = df[['product_id','category',
               'sub_category','product_name']].drop_duplicates()

product_sql = """
    INSERT IGNORE INTO products
    (product_id, category, sub_category, product_name)
    VALUES (%s,%s,%s,%s)
"""
for _, row in products.iterrows():
    cursor.execute(product_sql, tuple(row))
conn.commit()
print(f"✅ Products inserted: {len(products)}")

# ── 7. Insert ORDERS ──
orders = df[['order_id','order_date','ship_date',
             'ship_mode','customer_id']].drop_duplicates()

order_sql = """
    INSERT IGNORE INTO orders
    (order_id, order_date, ship_date,
     ship_mode, customer_id)
    VALUES (%s,%s,%s,%s,%s)
"""
for _, row in orders.iterrows():
    cursor.execute(order_sql, tuple(row))
conn.commit()
print(f"✅ Orders inserted: {len(orders)}")

# ── 8. Insert ORDER DETAILS ──
detail_sql = """
    INSERT INTO order_details
    (order_id, product_id, sales,
     quantity, discount, profit)
    VALUES (%s,%s,%s,%s,%s,%s)
"""
for _, row in df.iterrows():
    cursor.execute(detail_sql, (
        row['order_id'], row['product_id'],
        row['sales'],    row['quantity'],
        row['discount'], row['profit']
    ))
conn.commit()
print(f"✅ Order details inserted: {len(df)}")

cursor.close()
conn.close()
print("\n🎉 All data loaded successfully into MySQL!")