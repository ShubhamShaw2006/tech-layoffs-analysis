import pandas as pd
import numpy as np

df = pd.read_csv('data/raw/layoffs.csv')
print("Initial shape:", df.shape)

def parse_mixed_date(date_str):
    """Try both known formats, return a proper datetime or NaT if neither works."""
    if pd.isna(date_str):
        return pd.NaT
    date_str = str(date_str).strip()
    for fmt in ("%m/%d/%Y", "%m-%d-%Y"):
        try:
            return pd.to_datetime(date_str, format=fmt)
        except ValueError:
            continue
    return pd.NaT  # if neither format matches, mark as missing rather than guessing
 
df['date'] = df['date'].apply(parse_mixed_date)

df['date_added'] = df['date_added'].apply(parse_mixed_date)

print("Unparseable dates after fix:", df['date'].isna().sum())



text_cols = ['company', 'location', 'industry', 'stage', 'country', 'source']
for col in text_cols:
    df[col] = df[col].astype(str).str.strip()
    df[col] = df[col].replace('nan', np.nan)

for col in ['industry', 'stage', 'country', 'location']:
    df[col] = df[col].fillna('Unknown')



missing_total = df['total_laid_off'].isna().sum()
missing_pct = df['percentage_laid_off'].isna().sum()
print(f"total_laid_off missing: {missing_total} ({missing_total/len(df):.1%})")
print(f"percentage_laid_off missing: {missing_pct} ({missing_pct/len(df):.1%})")

missing_funds = df['funds_raised'].isna().sum()
print(f"funds_raised missing: {missing_funds} ({missing_funds/len(df):.1%})")



before = len(df)
df = df.drop_duplicates()
print(f"Dropped {before - len(df)} exact duplicate rows")



stage_map = {
    'Seed': 'Early', 'Series A': 'Early', 'Series B': 'Early',
    'Series C': 'Growth', 'Series D': 'Growth', 'Series E': 'Growth',
    'Series F': 'Late', 'Series G': 'Late', 'Series H': 'Late',
    'Series I': 'Late', 'Series J': 'Late',
    'Post-IPO': 'Mature/Exit', 'Acquired': 'Mature/Exit',
    'Private Equity': 'Mature/Exit', 'Subsidiary': 'Mature/Exit',
    'Unknown': 'Unknown'
}
df['stage_group'] = df['stage'].map(stage_map).fillna('Unknown')


df['year'] = df['date'].dt.year
df['month'] = df['date'].dt.to_period('M').astype(str)



df.to_csv('data/processed/layoffs_clean.csv', index=False)
print("Saved cleaned data to data/processed/layoffs_clean.csv")
print("Final shape:", df.shape)