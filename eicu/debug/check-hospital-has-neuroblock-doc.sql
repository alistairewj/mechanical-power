-- This query subselects hospitals with sufficient ventilation data
-- It cross-checks with APACHE IVa to ensure reliable recording
-- DROP TABLE IF EXISTS mp_hospitals_with_vent_data CASCADE;
-- CREATE TABLE mp_hospitals_with_vent_data AS
with has_vent as
(
  select
        distinct p.patientunitstayid
  FROM vent_unpivot_rc p
  -- only include settings before 24 hours
  WHERE p.chartoffset <= 24*60
  AND p.peakpressure IS NOT NULL
)
, pt_in_hosp as
(
  select pt.hospitalid
  , sum(neuroblock_day1) as num_neurblock
  , sum(case when v.patientunitstayid is not null then 1 else 0 end) as num_vent
  , sum(case when v.patientunitstayid is not null and neuroblock_day1 = 1 then 1 else 0 end) as num_vent_and_nb
  , count(pt.patientunitstayid) as num_pat_total
  from patient pt
  inner join mp_neuroblock nb
    on pt.patientunitstayid = nb.patientunitstayid
  left join has_vent v
    on pt.patientunitstayid = v.patientunitstayid
  group by pt.hospitalid
)
, hosp_in_cohort as
(
  select distinct hospitalid
  from mp_cohort
  where exclusion_no_peak_pressure = 0
)
select
    h.*
  , ROUND(100.0*num_vent::NUMERIC/num_pat_total,2) as frac_vent
  , ROUND(100.0*num_neurblock::NUMERIC/num_pat_total,2) as frac_nb
  , ROUND(100.0*num_vent_and_nb::NUMERIC/num_pat_total,2) as frac_vent_and_nb
  , ROUND(100.0*num_vent_and_nb::NUMERIC/num_vent,2) as frac_vent_with_nb
  , case when co.hospitalid is not null then 1 else 0 end as hospital_included
from pt_in_hosp h
LEFT JOIN hosp_in_cohort co
  ON h.hospitalid = co.hospitalid
-- at least 10 patients in the hospital
WHERE num_pat_total >= 10
AND co.hospitalid is not null
ORDER BY frac_nb DESC;
