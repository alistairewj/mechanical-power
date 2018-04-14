-- ------------------------------------------------------------------
-- Title: Oxford Acute Severity of Illness Score (OASIS)
-- This query extracts the Oxford acute severity of illness score in the eICU database.
-- This score is a measure of severity of illness for patients in the ICU.
-- The score is calculated on the first day of each ICU patients' stay.
-- ------------------------------------------------------------------

-- Reference for OASIS:
--    Johnson, Alistair EW, Andrew A. Kramer, and Gari D. Clifford.
--    "A new severity of illness scale using a subset of acute physiology and chronic health evaluation data elements shows comparable predictive accuracy*."
--    Critical care medicine 41, no. 7 (2013): 1711-1718.

-- Variables used in OASIS:
--  Heart rate, GCS, MAP, Temperature, Respiratory rate, Ventilation status
--  Urine output
--  Elective surgery
--  Pre-ICU in-hospital length of stay
--  Age

-- Note:
--  The score is calculated for *all* ICU patients, with the assumption that the user will subselect appropriate ICUSTAY_IDs.
--  For example, the score is calculated for neonates, but it is likely inappropriate to actually use the score values for these patients.

-- NOTE:
-- the current query relies only on variables recorded for the APACHE IV score
-- another approach would be to use values derived from routine care in other tables
-- e.g. some missing values in UO could be retrieved by extracting data from intakeoutput table

DROP TABLE IF EXISTS mp_oasis;
CREATE TABLE mp_oasis AS
with pt as
(
select pt.patientunitstayid
  -- hospital admit offset is negative, as it is time from hosp admit to ICU admit
  , -pt.hospitaladmitoffset/60.0 as preiculos
  -- convert age to numeric
  -- assume > 89 is 90 which gets max points in OASIS
  , CASE WHEN pt.age = '> 89' then 90
         WHEN pt.age = '' THEN NULL
      else pt.age::numeric end as age
  , CASE
      WHEN aav.verbal = -1 OR aav.motor = -1 OR aav.eyes = -1 THEN NULL
      ELSE aav.verbal + aav.motor + aav.eyes
    end as gcs
  -- vitals
  , CASE WHEN aav.respiratoryrate = -1 THEN NULL ELSE aav.respiratoryrate END AS resprate
  , CASE WHEN aav.temperature = -1 THEN NULL ELSE aav.temperature END AS tempc
  , CASE WHEN aav.heartrate = -1 THEN NULL ELSE aav.heartrate END AS heartrate
  , CASE WHEN aav.meanbp = -1 THEN NULL ELSE aav.meanbp END AS meanbp
  , CASE WHEN aav.urine = -1 THEN NULL ELSE aav.urine END AS UrineOutput
  -- binary flags
  , apv.oOBVentDay1 as mechvent
  , apv.electivesurgery
from patient pt
LEFT JOIN apacheapsvar aav
  ON pt.patientunitstayid = aav.patientunitstayid
LEFT JOIN apachepredvar apv
  ON pt.patientunitstayid = apv.patientunitstayid
)
, oasiscomp as
(
select pt.*
  , case when preiculos is null then null
       when preiculos < 0.17 then 5
       when preiculos < 4.94 then 3
       when preiculos < 24 then 0
       when preiculos > 311.8  then 1
       else 2 end as preiculos_score
  ,  case when age is null then null
        when age < 24 then 0
        when age <= 53 then 3
        when age <= 77 then 6
        when age <= 89 then 9
        when age >= 90 then 7
        else 0 end as age_score
  ,  case when gcs is null then null
        when gcs <= 7 then 10
        when gcs < 14 then 4
        when gcs = 14 then 3
        else 0 end as gcs_score
  ,  case when heartrate is null then null
        when heartrate > 125 then 6
        when heartrate < 33 then 4
        when heartrate >= 107 and heartrate <= 125 then 3
        when heartrate >= 89 and heartrate <= 106 then 1
        else 0 end as heartrate_score
  ,  case when meanbp is null then null
        when meanbp < 20.65 then 4
        when meanbp < 51 then 3
        when meanbp > 143.44 then 3
        when meanbp >= 51 and meanbp < 61.33 then 2
        else 0 end as meanbp_score
  ,  case when resprate is null then null
        when resprate <   6 then 10
        when resprate >  44 then  9
        when resprate >  30 then  6
        when resprate >  22 then  1
        when resprate <  13 then 1 else 0
        end as resprate_score
  ,  case when tempc is null then null
        when tempc > 39.88 then 6
        when tempc >= 33.22 and tempc <= 35.93 then 4
        when tempc >= 33.22 and tempc <= 35.93 then 4
        when tempc < 33.22 then 3
        when tempc > 35.93 and tempc <= 36.39 then 2
        when tempc >= 36.89 and tempc <= 39.88 then 2
        else 0 end as temp_score
  ,  case when UrineOutput is null then null
        when UrineOutput < 671.09 then 10
        when UrineOutput > 6896.80 then 8
        when UrineOutput >= 671.09
         and UrineOutput <= 1426.99 then 5
        when UrineOutput >= 1427.00
         and UrineOutput <= 2544.14 then 1
        else 0 end as UrineOutput_score
  ,  case when mechvent is null then null
        when mechvent = 1 then 9
        else 0 end as mechvent_score
  ,  case when electivesurgery is null then null
        when electivesurgery = 1 then 0
        else 6 end as electivesurgery_score
from pt
)
select oc.*
    -- impute 0 for missing values
    , coalesce(age_score,0)
    + coalesce(preiculos_score,0)
    + coalesce(gcs_score,0)
    + coalesce(heartrate_score,0)
    + coalesce(meanbp_score,0)
    + coalesce(resprate_score,0)
    + coalesce(temp_score,0)
    + coalesce(urineoutput_score,0)
    + coalesce(mechvent_score,0)
    + coalesce(electivesurgery_score,0)
    AS oasis
from oasiscomp oc;
