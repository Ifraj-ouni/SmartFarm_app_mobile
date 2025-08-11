#!/usr/bin/env python
# coding: utf-8

# In[11]:


import pandas as pd

def dew_severity_level(temp, lw):
    if 13 <= temp <= 17:
        if lw <= 6: return 0
        elif lw <= 15: return 1
        elif lw <= 20: return 2
        else: return 3
    elif 18 <= temp <= 20:
        if lw <= 3: return 0
        elif lw <= 8: return 1
        elif lw <= 15: return 2
        elif lw <= 22: return 3
        else: return 4
    elif 21 <= temp <= 25:
        if lw <= 2: return 0
        elif lw <= 5: return 1
        elif lw <= 12: return 2
        elif lw <= 20: return 3
        else: return 4
    elif 26 <= temp <= 29:
        if lw <= 3: return 0
        elif lw <= 8: return 1
        elif lw <= 15: return 2
        elif lw <= 22: return 3
        else: return 4
    return 0

# Map severity level to percentage
severity_to_percent = {0: "0%", 1: "25%", 2: "50%", 3: "75%", 4: "100%"}

def run_dew_model(filepath, sheet='Sheet1'):
    df = pd.read_excel(filepath, sheet_name=sheet)

    # Ensure column names match exactly
    df.columns = [col.strip() for col in df.columns]

    df['datetime'] = pd.to_datetime(df['datetime'])

    # Group by date: avg temp, total leaf wetness
    daily_df = df.groupby(df['datetime'].dt.date).agg({
        'temperature': 'mean',
        'LeafWetness': 'sum'
    }).reset_index().rename(columns={'datetime': 'Day', 'temperature': 'AvgTemp', 'LeafWetness': 'LeafWetnessHours'})

    daily_df['DewSeverityLevel'] = daily_df.apply(lambda row: dew_severity_level(row['AvgTemp'], row['LeafWetnessHours']), axis=1)
    daily_df['DewSeverityPercent'] = daily_df['DewSeverityLevel'].map(severity_to_percent)

    print(daily_df[['Day', 'AvgTemp', 'LeafWetnessHours', 'DewSeverityPercent']])
    return daily_df

# Call the function
run_dew_model('D:/model/test1.xlsx')
results_df = run_dew_model('D:/model/test1.xlsx')
results_df.to_excel("D:/model/resultats_alternariose.xlsx", index=False)
print("Résultats exportés avec succès.")


# In[ ]:




