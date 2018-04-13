-- This script extracts highest/lowest labs, as appropriate, for the first 24 hours of a patient's stay.
DROP TABLE IF EXISTS public.mp_labs CASCADE;
CREATE TABLE public.mp_labs as
with co as
(
  -- define the admission time
  -- 0 means use the administrative admission time
  select
    patientunitstayid
    , 0 as unitadmitoffset
  from patient
)
-- day 1
, vw1 as
(
  select p.patientunitstayid
  , min(bilirubin) as bilirubin_min
  , max(bilirubin) as bilirubin_max
  , min(creatinine) as creatinine_min
  , max(creatinine) as creatinine_max
  , min(platelets) as platelets_min
  , max(platelets) as platelets_max
  from pivoted_lab p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
    , vw1.bilirubin_min as bilirubin_min_day1
    , vw1.bilirubin_max as bilirubin_max_day1
    , vw1.creatinine_min as creatinine_min_day1
    , vw1.creatinine_max as creatinine_max_day1
    , vw1.platelets_min as platelets_min_day1
    , vw1.platelets_max as platelets_max_day1
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
order by pat.patientunitstayid;
