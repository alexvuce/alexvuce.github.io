
/*
Title: Current Ratio
Description: Calculates the Current Ratio using synthetic data.
License: This code is intended for educational purposes only.
*/

WITH fc AS (
    SELECT 
        organization_sector_id,
        health_facility_desc
    FROM dim_facility
), fp AS (
    SELECT 
        fiscal_period_id,
        accounting_period
    FROM dim_fiscal_period
), pa AS (
    SELECT 
        pa_id,
        pa_code,
        pa_group_2_code
    FROM dim_primary_acct
    WHERE SUBSTRING(pa_code, 1, 1) IN ('1', '4')
), fact AS (
    SELECT 
        organization_sector_id,
        fiscal_period_id,
        pa_id,
        amt
    FROM fact
), base AS (
    SELECT 
        health_facility_desc,
        accounting_period,
        pa_group_2_code,
        CASE 
            WHEN SUBSTRING(pa_code, 1, 1) = '1' AND SUBSTRING(pa_code, 3, 3) <> '355' THEN 'balance in 1*'
            WHEN SUBSTRING(pa_code, 1, 1) = '1' AND SUBSTRING(pa_code, 3, 3) = '355' THEN 'balance in 1~355'
            WHEN SUBSTRING(pa_code, 1, 1) = '4' AND SUBSTRING(pa_code, 3, 1) <> '8' THEN 'balance in 4* (excl. 4~8*)'
        END AS cr_grouping,
        SUM(amt) AS amt
    FROM fact
    INNER JOIN fc ON fact.organization_sector_id = fc.organization_sector_id
    INNER JOIN fp ON fact.fiscal_period_id = fp.fiscal_period_id
    INNER JOIN pa ON fact.pa_id = pa.pa_id
    GROUP BY 
        health_facility_desc,
        accounting_period,
        pa_group_2_code,
        CASE 
            WHEN SUBSTRING(pa_code, 1, 1) = '1' AND SUBSTRING(pa_code, 3, 3) <> '355' THEN 'balance in 1*'
            WHEN SUBSTRING(pa_code, 1, 1) = '1' AND SUBSTRING(pa_code, 3, 3) = '355' THEN 'balance in 1~355'
            WHEN SUBSTRING(pa_code, 1, 1) = '4' AND SUBSTRING(pa_code, 3, 1) <> '8' THEN 'balance in 4* (excl. 4~8*)'
        END
)
SELECT 
    health_facility_desc,
    accounting_period,
    SUM(
        CASE 
            WHEN (amt > 0 AND cr_grouping = 'balance in 1*')
              OR (amt > 0 AND cr_grouping = 'balance in 4* (excl. 4~8*)')
              OR (amt < 0 AND cr_grouping = 'balance in 1~355') THEN amt
            ELSE 0 
        END
    ) / NULLIF(
        SUM(
            CASE 
                WHEN (amt < 0 AND cr_grouping = 'balance in 1*') 
                  OR (amt < 0 AND cr_grouping = 'balance in 4* (excl. 4~8*)') THEN -1.0 * amt
                ELSE 0 
            END
        ), 0
    ) AS amt
FROM base
GROUP BY 
    health_facility_desc,
    accounting_period;
