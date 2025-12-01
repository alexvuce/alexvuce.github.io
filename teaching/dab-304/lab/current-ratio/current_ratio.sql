-- Purpose of code:

with fact as (
  select fiscal_periodi_id
        ,organization_sector_id
        ,pa_id
        ,sa_id
        ,amt
  from ohfs_r.fact_fin
)
select top 1000 * from fact
