-- This script extracts "demographics" for each patientunitstayid
-- These include:
--  1. actual demographics, e.g. age
--  2. static features for patients, e.g. hospital bed size

DROP TABLE IF EXISTS public.mp_demographics CASCADE;
CREATE TABLE public.mp_demographics as
select
    pat.patientunitstayid -- ICU stay identifier
  , pat.patienthealthsystemstayid

  -- patient features
  , pat.gender
  , case
      when pat.age = '> 89' then 90
      when pat.age = '' then NULL
    else cast(pat.age as NUMERIC)
    end as age
  , pat.ethnicity

  -- patient hospital stay features
  -- hospital length of stay in days
  , (hospitaldischargeoffset - hospitaladmitoffset) / 60.0 / 24.0 as hospital_los

  -- hospital size
  -- hospital type
  , hospitaladmitsource as hospital_admit_source
  , case -- discharge disposition, stratify by ...
      -- home
      when hospitaldischargelocation = 'Home' then 'Home'
      -- discharge to other acute care hospital
      when hospitaldischargelocation = 'Other Hospital' then 'OtherHospital'

      -- discharge to skilled nursing facility
      when hospitaldischargelocation = 'Skilled Nursing Facility' then 'SNF'

      -- discharge to rehabilitation or chronic care facility
      when hospitaldischargelocation in ('Rehabilitation','Nursing Home') then 'NursingHome'


      -- cases not specified in document
      when hospitaldischargelocation = 'Other External' then 'OtherExternal'
      when hospitaldischargelocation = 'Other' then 'Other'
      when hospitaldischargelocation = 'Death' then 'Death'
      when hospitaldischargelocation = 'Death' then 'Death'

      when length(hospitaldischargelocation)<=1 then null
    else null end as hospital_disch_location

  , case -- dead/alive
      when hospitaldischargestatus = 'Expired' then 1
      when hospitaldischargestatus = 'Alive' then 0
    else null end as hospital_mortality

  -- unit admission is the reference for offsets, so no subtraction needed
  , unitdischargeoffset / 60.0 / 24.0 as icu_los

  -- ICU admission source: there are 14 possible values
  -- TODO: group these if desired
  , unitadmitsource as icu_admit_source
  , unitdischargelocation as icu_disch_location

  -- APACHE IVa
  , aiva.apachescore as apacheiva
  , aiva.predictedhospitalmortality::NUMERIC as apacheiva_pred

  -- apache comorbidities
  , apv.aids
  , apv.hepaticfailure
  , apv.cirrhosis -- TODO: merge these?
  , apv.diabetes
  , apv.immunosuppression
  , apv.leukemia
  , apv.lymphoma
  , apv.metastaticcancer

  , admissionheight -- height in cm
  , admissionweight -- weight in kg

  , case
      when unitdischargestatus like '%Expired%' then 1
      when unitdischargestatus = 'Alive' then 0
    else null
    end as icu_mortality


  ----------------------------------------
  -- BELOW COLUMNS AVAILABLE BUT UNUSED --
  ----------------------------------------
--  , hospitalid
--  , wardid
--
--  , apacheadmissiondx
--  , hospitaladmityear
--  , hospitaladmittime24
--
--  , hospitaladmitoffset
--  , hospitaladmitsource
--  , hospitaldischargeyear
--  , hospitaldischargetime24
--  , hospitaldischargeoffset
--
--
--  , unitadmityear
--  , unitadmittime24
--  , unitvisitnumber
--  , unitstaytype
--  , dischargeweight
--
--  , unitdischargeyear
--  , unitdischargetime24
--  , unitdischargelocation
--  , unitdischargestatus

from patient pat
-- apache score
left join (select patientunitstayid, apachescore, predictedhospitalmortality from APACHEPATIENTRESULT where apacheversion = 'IVa') aiva
  on pat.patientunitstayid = aiva.patientunitstayid

-- apache comorbidity components + diabetes flag
left join APACHEPREDVAR apv
  on pat.patientunitstayid = apv.patientunitstayid;
