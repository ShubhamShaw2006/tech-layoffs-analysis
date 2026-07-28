import pandas as pd
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

load_dotenv()
 
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME')

engine = create_engine(
    f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
)

df = pd.read_csv('data/processed/layoffs_clean.csv')
print(f"Loaded {len(df)} rows from cleaned CSV")


df.to_sql(
    'layoffs',
    engine,
    if_exists='replace',   # drops and recreates the table with this data - fine for now
    index=False
)


print("Data successfully loaded into PostgreSQL table 'layoffs'")


with engine.connect() as conn:
    result = conn.exec_driver_sql("SELECT COUNT(*) FROM layoffs")
    count = result.scalar()
    print(f"Row count in database: {count}")