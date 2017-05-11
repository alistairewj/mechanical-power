create table public.mvpower as

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
WHERE adm.has_chartevents_data = 1
ORDER BY ie.subject_id, adm.admittime, ie.intime
)
select t1.subject_id, t1.hadm_id, t1.icustay_id, t1.gender, t1.los_hospital, t1.age, t1.hospstay_seq, t1.los_icu, t1.icustay_seq, v.ventnum, v.starttime, v.endtime, v.duration_hours
from t1, public.ventdurations v
where t1.hospstay_seq=1 and icustay_seq = 1 -- first hospital stay, first icu stay
and v.ventnum =1 and t1.age >=16 -- first ventilation and age >= 16
and v.duration_hours >= 48 -- mv duration >48h
and v.icustay_id = t1.icustay_id
and NOT EXISTS
 (with t2 as
 (select distinct c.icustay_id, c.charttime, c.value, rank()over (partition by c.icustay_id order by c.charttime) as sequence
from mimiciii.chartevents c, mimiciii.icustays a
where c.charttime between a.intime and a.intime +interval '3' day
and itemid  in (687,688,690,691,692,224831,224829,224830,224864,225590,227130)
and c.icustay_id = a.icustay_id
)
select t2.icustay_id
from t2
where t2.sequence = 1
and t2.icustay_id =t1.icustay_id
);
