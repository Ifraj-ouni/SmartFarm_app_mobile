#!/usr/bin/env python
# coding: utf-8

import pandas as pd

# === 1. Calcul de l'IPI ===
def calculate_ipi(tavg, tmin, rh_avg, rain_48h):
    if pd.isna(tavg) or pd.isna(tmin) or pd.isna(rh_avg) or pd.isna(rain_48h):
        return None
    if tmin <= 7 or tavg < 9 or tavg > 25:
        return None
    if rain_48h <= 0.2 and rh_avg <= 80:
        return None
    return tavg + tmin + rh_avg + rain_48h  # Formule simplifiée

# === 2. Interprétation ===
def interpret_ipi(ipi):
    if ipi is None:
        return ("0%", "Aucun risque")
    elif ipi < 50:
        return ("25%", "Faible")
    elif ipi < 100:
        return ("50%", "Modéré")
    elif ipi < 150:
        return ("75%", "Élevé")
    else:
        return ("100%", "Très élevé")

# === 3. Modèle principal ===
def run_ipi_model(filepath, sheet=0):
    df = pd.read_excel(filepath, sheet_name=sheet)

    # Vérifie les colonnes requises
    for col in ['datetime', 'Temperature_Avg', 'Temperature_Min', 'RH_Avg', 'Rainfall']:
        if col not in df.columns:
            raise ValueError(f"Colonne manquante : {col}")

    df['datetime'] = pd.to_datetime(df['datetime'])
    df['Date'] = df['datetime'].dt.date

    # Groupe par jour
    grouped = df.groupby('Date').agg({
        'Temperature_Avg': 'mean',
        'Temperature_Min': 'min',
        'RH_Avg': 'mean',
        'Rainfall': 'sum'
    }).reset_index()

    # Calcul IPI
    grouped['IPI'] = grouped.apply(lambda row: calculate_ipi(
        row['Temperature_Avg'], row['Temperature_Min'], row['RH_Avg'], row['Rainfall']
    ), axis=1)

    # Interprétation du risque
    grouped[['Risque (%)', 'Interprétation']] = grouped['IPI'].apply(
        lambda x: pd.Series(interpret_ipi(x))
    )

    return grouped

# === Exécution directe ===
if __name__ == "__main__":
    try:
        EXCEL_FILE = 'D:/model/test1.xlsx'
        results = run_ipi_model(EXCEL_FILE)
        print(results)
        results.to_excel("D:/model/resultats_mildiou_par_jour.xlsx", index=False)
        print("✅ Résultats exportés avec succès.")

        # --- Interprétation finale sur le dernier jour ---
        dernier_jour = results.iloc[-1]

        ipi_val = dernier_jour['IPI']
        interpretation = dernier_jour['Interprétation']
        date = dernier_jour['Date']

        print(f"\n📅 Dernier jour analysé : {date}")
        if pd.notna(ipi_val):
            print(f"🧪 IPI = {ipi_val:.2f}")
        else:
            print("🧪 IPI non calculable")

        print(f"🔎 Risque détecté : {interpretation}")

        if interpretation == "Très élevé":
            print("⚠️ Résultat : Plante possiblement infectée par le mildiou.")
        else:
            print("✅ Résultat : Aucun signe de mildiou détecté selon les données météo.")

    except Exception as e:
        print(f"❌ Erreur lors de l'exécution : {e}")










# === TEST ===
'''EXCEL_FILE = 'D:/model/test1.xlsx'  # adapte le chemin à ton fichier
df_result = run_ipi_model(EXCEL_FILE)

# Affichage des résultats (tu peux aussi sauvegarder)
print(df_result[['datetime', 'Temperature_Avg', 'Temperature_Min', 'RH_Avg', 'Rainfall', 'IPI']])

# Sauvegarde facultative
df_result.to_excel("D:/model/resultats_ipi.xlsx", index=False)
print("✅ Résultats IPI exportés avec succès.")'''


# In[ ]:




#grouper les donénes par jour 
'''import pandas as pd
import numpy as np

# 1. Calcul de l'IPI (Indice de Pression d'Infection)
def calculate_ipi(tavg, tmin, rh_avg, rain_48h):
    if pd.isna(tavg) or pd.isna(tmin) or pd.isna(rh_avg) or pd.isna(rain_48h):
        return None
    if tmin <= 7 or tavg < 9 or tavg > 25:
        return None
    if rain_48h <= 0.2 and rh_avg <= 80:
        return None
    return tavg + tmin + rh_avg + rain_48h  # Formule simple (à adapter si besoin)

# 2. Interprétation du risque
def interpret_ipi(ipi):
    if ipi is None:
        return ("0%", "Aucun risque")
    elif ipi < 50:
        return ("25%", "Faible")
    elif ipi < 100:
        return ("50%", "Modéré")
    elif ipi < 150:
        return ("75%", "Élevé")
    else:
        return ("100%", "Très élevé")

# 3. Fonction principale
def run_ipi_model(filepath, sheet=0):
    df = pd.read_excel(filepath, sheet_name=sheet)

    # Vérifie les colonnes nécessaires
    for col in ['datetime', 'Temperature_Avg', 'Temperature_Min', 'RH_Avg', 'Rainfall']:
        if col not in df.columns:
            raise ValueError(f"Colonne manquante : {col}")

    # Conversion en datetime si nécessaire
    df['datetime'] = pd.to_datetime(df['datetime'])

    # Groupe par jour 
    #groupe par semaine df.groupby(df['datetime'].dt.to_period('W')).agg(...)
    df['Date'] = df['datetime'].dt.date
    grouped = df.groupby('Date').agg({
        'Temperature_Avg': 'mean',
        'Temperature_Min': 'min',
        'RH_Avg': 'mean',
        'Rainfall': 'sum'
    }).reset_index()

    # Calcul IPI
    grouped['IPI'] = grouped.apply(lambda row: calculate_ipi(
        row['Temperature_Avg'], row['Temperature_Min'], row['RH_Avg'], row['Rainfall']
    ), axis=1)

    # Interprétation
    grouped[['Risque (%)', 'Interprétation']] = grouped['IPI'].apply(
        lambda x: pd.Series(interpret_ipi(x))
    )

    return grouped

# === Test local ===
if __name__ == "__main__":
    EXCEL_FILE = 'D:/model/test1.xlsx'  # mets ton chemin ici
    results = run_ipi_model(EXCEL_FILE)
    print(results)
    results.to_excel("D:/model/resultats_mildiou_par_jour.xlsx", index=False)
    print("✅ Résultats exportés avec succès.")
'''