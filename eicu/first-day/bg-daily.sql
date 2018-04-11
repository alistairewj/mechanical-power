-- This script extracts highest/lowest labs, as appropriate, for the first 24 hours of a patient's stay.

DROP TABLE IF EXISTS public.mp_bg CASCADE;
CREATE TABLE public.mp_bg as
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
  , min(pao2) as PaO2_min
  , max(pao2) as PaO2_max
  , min(paco2) as PaCO2_min
  , max(paco2) as PaCO2_max
  , min(ph) as ph_min
  , max(ph) as ph_max
  , min(pao2/fio2) as pao2fio2_min
  , max(pao2/fio2) as pao2fio2_max
  from pivoted_bg p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  WHERE pao2 IS NOT NULL
  OR paco2 IS NOT NULL
  OR ph IS NOT NULL
  group by p.patientunitstayid
)
-- day 2
, vw2 as
(
  select p.patientunitstayid
  , min(pao2) as PaO2_min
  , max(pao2) as PaO2_max
  , min(paco2) as PaCO2_min
  , max(paco2) as PaCO2_max
  , min(ph) as ph_min
  , max(ph) as ph_max
  , min(pao2/fio2) as pao2fio2_min
  , max(pao2/fio2) as pao2fio2_max
  from pivoted_bg p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (24*60)
    and p.chartoffset <= co.unitadmitoffset + (48*60)
  WHERE pao2 IS NOT NULL
  OR paco2 IS NOT NULL
  OR ph IS NOT NULL
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
  , vw1.PaO2_min as PaO2_min_day1
  , vw1.PaO2_max as PaO2_max_day1
  , vw1.PaCO2_min as PaCO2_min_day1
  , vw1.PaCO2_max as PaCO2_max_day1
  , vw1.pao2fio2_min as PaO2FiO2_min_day1
  , vw1.pao2fio2_max as PaO2FiO2_max_day1
  , vw1.ph_min as ph_min_day1
  , vw1.ph_max as ph_max_day1

  , vw2.PaO2_min as PaO2_min_day2
  , vw2.PaO2_max as PaO2_max_day2
  , vw2.PaCO2_min as PaCO2_min_day2
  , vw2.PaCO2_max as PaCO2_max_day2
  , vw2.pao2fio2_min as pao2fio2_min_day2
  , vw2.pao2fio2_max as pao2fio2_max_day2
  , vw2.ph_min as ph_min_day2
  , vw2.ph_max as ph_max_day2
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
