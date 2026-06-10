-- Preppin' Data 2023 Week 01
-- Source: TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK01
--
-- Base CTE:
--   - Extracts bank code from the transaction code prefix (before first hyphen)
--   - Renames Online_or_In_Person: 1 = 'Online', 2 = 'In-Person'
--   - Converts transaction date string to day of the week
--
-- Output 1: Total Values of Transactions by each bank
-- Output 2: Total Values by Bank, Day of the Week, and Type of Transaction (Online or In-Person)
-- Output 3: Total Values by Bank and Customer Code

-- Base transformation
WITH base AS (
    SELECT
        SPLIT_PART(TRANSACTION_CODE, '-', 1) AS Bank,
        VALUE,
        CASE ONLINE_OR_IN_PERSON
            WHEN 1 THEN 'Online'
            WHEN 2 THEN 'In-Person'
        END AS Online_or_In_Person,
        DAYNAME(TO_DATE(TRANSACTION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS Day_of_Week,
        CUSTOMER_CODE
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK01
)

-- Output 1: Total Values of Transactions by each bank
SELECT Bank, SUM(VALUE) AS Total_Value
FROM base
GROUP BY Bank;

-- Output 2: Total Values by Bank, Day of the Week, and Type of Transaction
WITH base AS (
    SELECT
        SPLIT_PART(TRANSACTION_CODE, '-', 1) AS Bank,
        VALUE,
        CASE ONLINE_OR_IN_PERSON
            WHEN 1 THEN 'Online'
            WHEN 2 THEN 'In-Person'
        END AS Online_or_In_Person,
        DAYNAME(TO_DATE(TRANSACTION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS Day_of_Week,
        CUSTOMER_CODE
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK01
)

SELECT Bank, Day_of_Week, Online_or_In_Person, SUM(VALUE) AS Total_Value
FROM base
GROUP BY Bank, Day_of_Week, Online_or_In_Person
ORDER BY Bank, Day_of_Week, Online_or_In_Person;

-- Output 3: Total Values by Bank and Customer Code
WITH base AS (
    SELECT
        SPLIT_PART(TRANSACTION_CODE, '-', 1) AS Bank,
        VALUE,
        CASE ONLINE_OR_IN_PERSON
            WHEN 1 THEN 'Online'
            WHEN 2 THEN 'In-Person'
        END AS Online_or_In_Person,
        DAYNAME(TO_DATE(TRANSACTION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS Day_of_Week,
        CUSTOMER_CODE
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK01
)

SELECT Bank, CUSTOMER_CODE, SUM(VALUE) AS Total_Value
FROM base
GROUP BY Bank, CUSTOMER_CODE
ORDER BY Bank, CUSTOMER_CODE;
