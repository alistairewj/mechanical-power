See eicu-sepsis-prompt for queries to get pivoted tables.
See eicu-northwell for ventilation queries.

Afterwards, run:

```sql
\i vent-durations.sql
\i hospitals-with-vent-data.sql
\i cohort.sql
\i demographics.sql
\i weight.sql
\i during-vent/bg-daily.sql
\i during-vent/labs-daily.sql
\i during-vent/meds-daily.sql
\i during-vent/vitals-daily.sql
\i during-vent/vent-daily.sql
\i data.sql
```

Summarize exclusions:

```sql
SELECT
  COUNT(*) AS num_pat_start
, SUM(exclusion_non_adult) AS exclusion_non_adult
, SUM(exclusion_secondary_hospital_stay) AS exclusion_secondary_hospital_stay
, SUM(exclusion_secondary_icu_stay) AS exclusion_secondary_icu_stay
, SUM(exclusion_by_apache) AS exclusion_by_apache
, SUM(exclusion_no_rc_data) AS exclusion_no_rc_data
, SUM(exclusion_trach) AS exclusion_trach
, SUM(exclusion_not_vent_48hr) AS exclusion_not_vent_48hr
, SUM(exclusion_no_peak_pressure) AS exclusion_no_peak_pressure
-- final
, COUNT(*) - SUM(GREATEST(
      exclusion_non_adult
    , exclusion_secondary_hospital_stay
    , exclusion_secondary_icu_stay
    , exclusion_by_apache
    , exclusion_no_rc_data
    , exclusion_trach
    , exclusion_not_vent_48hr
    , exclusion_no_peak_pressure
)) as num_final_cohort
, COUNT(DISTINCT CASE WHEN GREATEST(
            exclusion_non_adult
          , exclusion_secondary_hospital_stay
          , exclusion_secondary_icu_stay
          , exclusion_by_apache
          , exclusion_no_rc_data
          , exclusion_trach
          , exclusion_not_vent_48hr
          , exclusion_no_peak_pressure) = 0 THEN hospitalid ELSE NULL END
        ) as num_hospitals_considered
FROM mp_cohort;
```
