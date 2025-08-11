import sys
sys.path.append(r"D:/model")

from oidium import run_oidium_model
from alternariose import run_dew_model
from mildiou import run_ipi_model  # adapte le nom si besoin

def test_all():
    excel_path = "D:/model/test1.xlsx"

    # Test Oidium
    df_oidium = run_oidium_model(excel_path)
    print("Oïdium:")
    print(df_oidium.head())
    df_oidium.to_excel("D:/model/resultats_oidium.xlsx", index=False)

    # Test Alternariose
    df_alt = run_dew_model(excel_path)
    print("Alternariose:")
    print(df_alt.head())
    df_alt.to_excel("D:/model/resultats_alternariose.xlsx", index=False)

    # Test Mildiou
    df_mildiou = run_ipi_model(excel_path)
    print("Mildiou:")
    print(df_mildiou.head())
    df_mildiou.to_excel("D:/model/resultats_mildiou.xlsx", index=False)

if __name__ == "__main__":
    test_all()
    print("✅ Tests terminés, résultats exportés.")
