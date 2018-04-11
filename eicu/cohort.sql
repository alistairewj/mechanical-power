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
with vw1 as
(
  select
    pt.*
    , ROW_NUMBER() over
    (
      PARTITION BY uniquepid
      ORDER BY
        hospitaladmityear, hospitaldischargeyear
      , REPLACE(age, '>','')::INT
      , patienthealthsystemstayid -- this is temporally random but deterministic
      , hospitaladmitoffset
    ) as HOSP_NUM
    , ROW_NUMBER() over
    (
      PARTITION BY patienthealthsystemstayid
      ORDER BY hospitaladmitoffset
    ) as ICUSTAY_NUM
  from patient pt
  where
    -- only include ICUs
    lower(unittype) like '%icu%'
    -- patients over 18
    -- note: because age is a string (contains '> 89'), we do string comparisons
    --and (substr(age,1,1) != '1' OR substr(age,1,2) in ('18','19'))
)
-- only patients from 2010-2014
select vw1.PATIENTUNITSTAYID
, case when age = '> 89' then 0
      when age = '' then 0
      when cast(age as numeric) < 16 then 1
    else 0 end as exclusion_Over18
, case when HOSP_NUM!=
, case when ICUSTAY_NUM != 1 then 1 else 0 end as exclusion_FirstAdmission
, case when vw1.unitdischargeyear >= 2010 and vw1.unitdischargeyear <= 2015 then 0 else 1 end as exclusion_YearFilter
, case when aiva.apachepredictedmortality::NUMERIC > 0 then 0 else 1 end as exclusion_apache
, case when vit.numobs > 0 then 0 else 1 end as exclusion_VitalObservations
, case when lab.numobs > 0 then 0 else 1 end as exclusion_LabObservations
, case when med.numobs > 0 then 0 else 1 end as exclusion_MedObservations
from vw1
-- check for apache values
left join (select patientunitstayid, max(apachescore) as apachescore from APACHEPATIENTRESULT where apacheversion = 'IV' group by patientunitstayid) aiv
  on vw1.patientunitstayid = aiv.patientunitstayid
left join (select patientunitstayid, max(apachescore) as apachescore from APACHEPATIENTRESULT where apacheversion = 'IVa' group by patientunitstayid) aiva
  on vw1.patientunitstayid = aiva.patientunitstayid
-- check for the patient having any vitals
left join (select patientunitstayid, count(observationoffset) as numobs from vitalperiodic group by patientunitstayid) vit
  on vw1.patientunitstayid = vit.patientunitstayid


-- check for the patient having any labs
left join (select patientunitstayid, count(labname) as numobs from lab group by patientunitstayid) lab
  on vw1.patientunitstayid = lab.patientunitstayid

-- check for the patient having any meds
left join (select patientunitstayid, count(drughiclseqno) as numobs from medication group by patientunitstayid) med
  on vw1.patientunitstayid = med.patientunitstayid

-- check for the hospital having a meds interface - done by looking for unmatched entries for the year
left join
(
  select hospitalid, unitadmityear
    , sum(case when med.gtc = 0 then 1 else 0 end) as UnmappedMed
  from patient pat
  inner join medication med
    on pat.patientunitstayid = med.patientunitstayid
  group by hospitalid, unitadmityear
) medint
  on vw1.hospitalid = medint.hospitalid and vw1.unitadmityear = medint.unitadmityear

-- patients with continuous IO information
-- see infusion-query.sql
-- left join C_PATIENTS_WITH_INFUSIONS inf
--  on vw1.patientunitstayid = inf.patientunitstayid
order by vw1.patientunitstayid;
