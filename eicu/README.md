Run pivot queries:

```sql
\i ../eicu-code/concepts/pivoted/pivoted-bg.sql
\i ../eicu-code/concepts/pivoted/pivoted-infusion.sql
\i ../eicu-code/concepts/pivoted/pivoted-lab.sql
\i ../eicu-code/concepts/pivoted/pivoted-med.sql
\i ../eicu-code/concepts/pivoted/pivoted-o2.sql
\i ../eicu-code/concepts/pivoted/pivoted-score.sql
\i ../eicu-code/concepts/pivoted/pivoted-treatment-vasopressor.sql
\i ../eicu-code/concepts/pivoted/pivoted-uo.sql
\i ../eicu-code/concepts/pivoted/pivoted-vital-other.sql
\i ../eicu-code/concepts/pivoted/pivoted-vital.sql
\i ../eicu-code/concepts/neuroblock.sql
```

Run ventilation queries:

```sql
\cd ../eicu-northwell/vent
\i pivoted-vent-rc.sql
\i pivoted-vent-nc.sql
\i load-labels-od.sql
\i load-labels-vm.sql
\cd ../ventduration
\i vent-events.sql
\i ventilation-durations.sql
\cd ../../mechanical-power/eicu
```

Above generates the needed `ventevents` and `ventdurations` tables.

Afterwards, run:

```sql
\i hospitals-with-vent-data.sql
\i cohort.sql
\i demographics.sql
\i height-weight.sql
-- these tables extract data from vent start to vent start + 48 hr
\i during-vent/bg-daily.sql
\i during-vent/labs-daily.sql
\i during-vent/meds-daily.sql
\i during-vent/vitals-daily.sql
\i during-vent/vent-daily.sql
\i during-vent/neuroblock-daily.sql
-- other queries
\i sofa.sql
\i oasis.sql
\i resp-failure.sql
\i charlson.sql
\i code-status.sql
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

Extract data for only non-excluded patients:

```sql
\copy (select * from mp_data where patientunitstayid in (select patientunitstayid from mp_cohort where GREATEST(exclusion_non_adult, exclusion_secondary_hospital_stay, exclusion_secondary_icu_stay, exclusion_by_apache, exclusion_no_rc_data, exclusion_trach, exclusion_not_vent_48hr, exclusion_no_peak_pressure) = 0) ORDER BY patientunitstayid) to 'eicu-mechanical-power.csv' CSV HEADER;
```

Extract block data

```sql
\copy (select * from mp_vent_grouped where patientunitstayid in (select patientunitstayid from mp_cohort where GREATEST(exclusion_non_adult, exclusion_secondary_hospital_stay, exclusion_secondary_icu_stay, exclusion_by_apache, exclusion_no_rc_data, exclusion_trach, exclusion_not_vent_48hr, exclusion_no_peak_pressure) = 0) ORDER BY patientunitstayid, block) to 'eicu-mechanical-power-vent-grouped.csv' CSV HEADER;
```

Extract duration data

```sql
\copy (select * from ventdurations where ventseq = 1 and patientunitstayid in (select patientunitstayid from mp_cohort where GREATEST(exclusion_non_adult, exclusion_secondary_hospital_stay, exclusion_secondary_icu_stay, exclusion_by_apache, exclusion_no_rc_data, exclusion_trach, exclusion_not_vent_48hr, exclusion_no_peak_pressure) = 0) ORDER BY patientunitstayid) to 'eicu-vent-durations.csv' CSV HEADER;
```
