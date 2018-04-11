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
-- only patients from 2010-2014
select vw1.PATIENTUNITSTAYID
, case when age < 16 then 1 else 0 end as exclusion_non_adult
, case when HOSP_NUM != 1 then 1 else 0 end as exclusion_secondary_hospital_stay
, case when ICUSTAY_NUM != 1 then 1 else 0 end as exclusion_secondary_icu_stay
, case when aiva.predictedhospitalmortality = '' then NULL
      when aiva.predictedhospitalmortality::NUMERIC > 0 then 0
    else 1 end as exclusion_by_apache
from vw1
-- check for apache values
left join (select patientunitstayid, apachescore, predictedhospitalmortality from APACHEPATIENTRESULT where apacheversion = 'IVa') aiva
  on vw1.patientunitstayid = aiva.patientunitstayid
order by vw1.patientunitstayid;
