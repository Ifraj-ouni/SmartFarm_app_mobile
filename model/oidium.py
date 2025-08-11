#!/usr/bin/env python
# coding: utf-8

# In[4]:


import pandas as pd
import numpy as np

# -----------------------------------
# 1. Lecture et préparation des données
# -----------------------------------

def read_excel_data(filepath, sheet_name="Sheet1"):
    df = pd.read_excel(filepath, sheet_name=sheet_name)

    print("📋 Colonnes disponibles :", df.columns.tolist())

    # Vérifie les colonnes attendues
    required_cols = ['temperature', 'RelativeHumidity', 'LeafWetness']
    for col in required_cols:
        if col not in df.columns:
            raise ValueError(f"❌ Colonne manquante : {col}")

    return df['temperature'].values, df['RelativeHumidity'].values, df['LeafWetness'].values

# -----------------------------------
# 2. Calculs journaliers
# -----------------------------------

def calculate_daily_variables(T, RH, LW):
    days = len(T) // 24
    tavg, RHavg, LWsum = [], [], []

    for i in range(days):
        tavg.append(np.mean(T[i*24:(i+1)*24]))
        RHavg.append(np.mean(RH[i*24:(i+1)*24]))
        LWsum.append(np.sum(LW[i*24:(i+1)*24]))

    return list(zip(tavg, RHavg, LWsum))

# -----------------------------------
# 3. Classification du risque journalier
# -----------------------------------

def classify_day_risk(daily_vars):
    risk_percent = []

    for i, (t, rh, lw) in enumerate(daily_vars):
        if t < 10 or t > 35:
            risk_percent.append(0)
        elif rh < 70:
            risk_percent.append(0)
        elif lw < 4:
            risk_percent.append(10)
        elif lw >= 4 and lw <= 8:
            risk_percent.append(40)
        elif lw > 8 and lw <= 12:
            risk_percent.append(70)
        else:
            risk_percent.append(100)

    return risk_percent

# -----------------------------------
# 4. Fonction principale d'exécution
# -----------------------------------

def run_oidium_model(filepath):
    T, RH, LW = read_excel_data(filepath)
    variables = calculate_daily_variables(T, RH, LW)
    risk_percent = classify_day_risk(variables)

    result = pd.DataFrame({
        "Date": pd.date_range(start='2024-01-01', periods=len(risk_percent)),
        "Oidium Risk (%)": risk_percent
    })

    return result

# -----------------------------------
# 5. Exécution directe (facultatif)
# -----------------------------------

if __name__ == "__main__":
    fichier = "D:/model/test1.xlsx"
    df_oidium = run_oidium_model(fichier)
    print(df_oidium)
    df_oidium.to_excel("D:/model/resultats_oidium.xlsx", index=False)
    print("✅ Résultats Oïdium exportés avec succès.")


# In[6]:

'''
import sys
sys.path.append(r"D:/model")  # ajoute le chemin si besoin

import oidium
print(dir(oidium))  # Liste tout ce que contient oidium.py

'''
# In[ ]:




