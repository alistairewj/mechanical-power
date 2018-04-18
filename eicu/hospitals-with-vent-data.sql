-- This query subselects hospitals with sufficient ventilation data
-- It cross-checks with APACHE IVa to ensure reliable recording
DROP TABLE IF EXISTS mp_hospitals_with_vent_data CASCADE;
CREATE TABLE mp_hospitals_with_vent_data AS
with co as
(
  select apr.patientunitstayid, pt.hospitalid
  from apachepatientresult apr
  INNER JOIN apachepredvar apv
  ON apr.patientunitstayid = apv.patientunitstayid
  INNER JOIN patient pt
  on apr.patientunitstayid = pt.patientunitstayid
  WHERE apr.apacheversion = 'IVa'
  AND apr.predictedhospitalmortality::NUMERIC > 0
  -- ventilated on first day
  AND apv.oobventday1 = 1
)
, grp as
(
  select
      co.hospitalid
      , co.patientunitstayid
  FROM vent_unpivot_rc p
  INNER JOIN co
  ON  p.patientunitstayid = co.patientunitstayid
  -- only include settings before 24 hours
  WHERE p.chartoffset <= 24*60
  AND peakpressure IS NOT NULL
)
, pt_in_hosp as
(
  select pt.hospitalid
  , count(distinct co.patientunitstayid) as num_pat_total
  from patient pt
  inner join co
  on pt.patientunitstayid = co.patientunitstayid
  group by pt.hospitalid
)
select
    grp.hospitalid
    , count(distinct grp.patientunitstayid) as num_pat
    , max(pt_in_hosp.num_pat_total) as num_pat_total
    , ROUND(100.0*count(distinct grp.patientunitstayid)::NUMERIC/max(pt_in_hosp.num_pat_total),2) as frac_pat
from grp
inner join pt_in_hosp
on grp.hospitalid = pt_in_hosp.hospitalid
group by grp.hospitalid
-- at least 10 patients in the hospital
HAVING count(distinct grp.patientunitstayid) >= 10
-- at least 10% of patients have documentation in respiratory charting
AND count(distinct grp.patientunitstayid)::NUMERIC/max(pt_in_hosp.num_pat_total) >= 0.10;
