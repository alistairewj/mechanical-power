DROP TABLE IF EXISTS mpwr_cohort CASCADE;
CREATE TABLE mpwr_cohort AS
with t1 as
(
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id

-- patient level factors
, pat.gender

-- hospital level factors
, adm.admittime, adm.dischtime
, ROUND( (CAST(adm.dischtime AS DATE) - CAST(adm.admittime AS DATE)) , 4) AS los_hospital
, ROUND( (CAST(adm.admittime AS DATE) - CAST(pat.dob AS DATE))  / 365.242, 4) AS age
, adm.ethnicity, adm.ADMISSION_TYPE
, adm.hospital_expire_flag
, DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime) AS hospstay_seq
, CASE
    WHEN DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime) = 1 THEN 'Y'
    ELSE 'N' END AS first_hosp_stay
, adm.has_chartevents_data

-- icu level factors
, ie.intime, ie.outtime
, ROUND( (CAST(ie.outtime AS DATE) - CAST(ie.intime AS DATE)) , 4) AS los_icu
, DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime) AS icustay_seq

-- first ICU stay *for the current hospitalization*
, CASE
    WHEN DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime) = 1 THEN 'Y'
    ELSE 'N' END AS first_icu_stay

FROM icustays ie
INNER JOIN admissions adm
    ON ie.hadm_id = adm.hadm_id
INNER JOIN patients pat
    ON ie.subject_id = pat.subject_id
ORDER BY ie.subject_id, adm.admittime, ie.intime
)
select t1.subject_id, t1.hadm_id, t1.icustay_id
  , t1.intime, t1.outtime

  , t1.gender, t1.los_hospital, t1.age, t1.hospstay_seq
  , t1.los_icu, t1.icustay_seq, v.ventnum
  , v.starttime, v.endtime, v.duration_hours

  -- exclusions
  , case when t1.age < 16 then 1 else 0 end as exclusion_nonadult
  , case when t1.hospstay_seq>1 or t1.icustay_seq>1 then 1 else 0 end as exclusion_readmission
  , case when tr.trach = 1 then 1 else 0 end as exclusion_trach
  , case when v.icustay_id is null then 1 else 0 end as exclusion_not_vent
  , case when has_chartevents_data = 0 then 1 else 0 end as exclusion_bad_data

from t1
left join public.ventdurations v
  on v.icustay_id = t1.icustay_id
  and v.ventnum = 1 -- first ventilation and age >= 16
  and v.duration_hours >= 48 -- mv duration >48h
left join mpwr_trach tr
  on t1.icustay_id = tr.icustay_id
order by t1.icustay_id;
