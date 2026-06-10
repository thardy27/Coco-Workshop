# Preppin' Data 2023 Week 02 - International Bank Account Numbers
# Steps:
#   - Remove dashes from Sort Code
#   - Join to SWIFT lookup to get SWIFT_CODE and CHECK_DIGITS
#   - Construct IBAN: Country Code (GB) + Check Digits + SWIFT Code + Sort Code + Account Number
# Output: TRANSACTION_ID, IBAN (100 rows)

import pandas as pd
import snowflake.connector

conn = snowflake.connector.connect(
    connection_name="default"
)

transactions = pd.read_sql(
    "SELECT * FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK02_TRANSACTIONS", conn
)
swift_codes = pd.read_sql(
    "SELECT * FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK02_SWIFT_CODES", conn
)

conn.close()

transactions["SORT_CODE"] = transactions["SORT_CODE"].str.replace("-", "", regex=False)

df = transactions.merge(swift_codes, on="BANK", how="inner")

df["IBAN"] = (
    "GB"
    + df["CHECK_DIGITS"]
    + df["SWIFT_CODE"]
    + df["SORT_CODE"]
    + df["ACCOUNT_NUMBER"].astype(str)
)

output = df[["TRANSACTION_ID", "IBAN"]].sort_values("TRANSACTION_ID").reset_index(drop=True)
print(output)
