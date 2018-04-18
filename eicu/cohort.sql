-- The script creates a TABLE with:
--  1. patientunitstayid
--  2. mechanical power cohort inclusion flags
-- .. which are:
--    age > 16 years
--    during the first ICU and hospital admission
--    receiving invasive ventilation for at least 48 hours
--    without tracheostomy in the first 48 hours
DROP TABLE IF EXISTS public.mp_cohort CASCADE;
CREATE TABLE public.mp_cohort as
with pt as
(
  select pt.patientunitstayid
  , pt.patienthealthsystemstayid
  , pt.uniquepid
  , pt.hospitalid
  , hospitaladmitoffset
  , hospitaladmityear, hospitaldischargeyear
  , case when pt.age = '' then null
      else REPLACE(age, '>','')
    end::INT as age
  from patient pt
  where
    -- only include ICUs
    lower(unittype) like '%icu%'
)
, vw1 as
(
  select
    pt.*
    , ROW_NUMBER() over
    (
      PARTITION BY uniquepid
      ORDER BY
        hospitaladmityear, hospitaldischargeyear
      , age
      , patienthealthsystemstayid -- this is temporally random but deterministic
      , hospitaladmitoffset
    ) as HOSP_NUM
    , ROW_NUMBER() over
    (
      PARTITION BY patienthealthsystemstayid
      ORDER BY hospitaladmitoffset
    ) as ICUSTAY_NUM
  from pt
)
-- extract the first heart rate time as the admission time
, adm as
(
  select
    patientunitstayid
    , min(chartoffset) as admitoffset
  from pivoted_vital p
  WHERE heartrate IS NOT NULL
  GROUP BY patientunitstayid
)
-- extract the start time for each patient using ventilation data
, st as
(
  select
    patientunitstayid
    , min(startoffset) as startoffset
  from ventdurations p
  GROUP BY patientunitstayid
)
-- get trach status from vent events, which sources care plan // treatment tables
, ve as
(
  SELECT
    patientunitstayid, min(chartoffset) as trachoffset
  FROM ventevents ve
  WHERE trach = 1
  group by patientunitstayid
)
select vw1.patientunitstayid
, vw1.hospitalid
-- starttime is the start time of mechanical ventilation
, st.startoffset
-- admit time is the first observed heart rate
, adm.admitoffset
, case when age < 16 then 1 else 0 end as exclusion_non_adult
, case when HOSP_NUM != 1 then 1 else 0 end as exclusion_secondary_hospital_stay
, case when ICUSTAY_NUM != 1 then 1 else 0 end as exclusion_secondary_icu_stay
, case when aiva.predictedhospitalmortality = '' then NULL
      when aiva.predictedhospitalmortality::NUMERIC > 0 then 0
    else 1 end as exclusion_by_apache
, case when st.patientunitstayid IS NULL THEN 1 ELSE 0 END as exclusion_no_rc_data
-- not trach
, case when ve.trachoffset <= st.startoffset THEN 1 ELSE 0 END AS exclusion_trach
-- ventilated at least 48 hours
, case when vd.ventilation_minutes >= 2880 THEN 0 ELSE 1 END as exclusion_not_vent_48hr
from vw1
-- check for apache values
left join (select patientunitstayid, apachescore, predictedhospitalmortality from APACHEPATIENTRESULT where apacheversion = 'IVa') aiva
  on vw1.patientunitstayid = aiva.patientunitstayid
left join st
  on vw1.patientunitstayid = st.patientunitstayid
left join adm
  on vw1.patientunitstayid = adm.patientunitstayid
left join ventdurations vd
  on vw1.patientunitstayid = vd.patientunitstayid
  and vd.ventseq = 1
left join ve
  on vw1.patientunitstayid = ve.patientunitstayid
order by vw1.patientunitstayid;
