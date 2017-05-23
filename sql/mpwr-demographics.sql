DROP TABLE IF EXISTS mpwr_demographics CASCADE;
CREATE TABLE mpwr_demographics as
with serv as
(
  select ie.icustay_id
    , se.curr_service as first_service
    , ROW_NUMBER() over (partition by ie.icustay_id order by se.transfertime desc) as rn
  from icustays ie
  left join services se
    on ie.hadm_id = se.hadm_id
    and se.transfertime < ie.intime + interval '6' hour
)
-- primary icd-9 code
, primary_dx as
(
  select di.hadm_id, di.icd9_code
    , dicd.short_title, dicd.long_title
  from diagnoses_icd di
  inner join d_icd_diagnoses dicd
    on di.icd9_code = dicd.icd9_code
  where di.seq_num = 1
)
, totalventdur as
(
  select icustay_id
    , sum(extract(epoch from endtime - starttime))/60.0/60.0/24.0 as duration_vent_total_days
    , min(starttime) as starttime
  from ventdurations
  group by icustay_id
)
select co.icustay_id
  -- patient characteristics
  , hw.height_first as height
  , hw.weight_first as weight
  , smk.smoking
  , pt.gender
  , case when extract(year from co.intime - pt.dob) > 250 then 91.4
      else extract(epoch from co.intime - pt.dob)/60.0/60.0/24.0/365.242 end
    as age

  -- admission characteristics
  , a.admission_type
  , a.admission_location as source_of_admission
  , a.insurance
  , a.marital_status
  , a.ethnicity as ethnicity_raw

  -- ethnicity flags
  , case
  when a.ethnicity in
  (
      'WHITE' --  40996
    , 'WHITE - RUSSIAN' --    164
    , 'WHITE - OTHER EUROPEAN' --     81
    , 'WHITE - BRAZILIAN' --     59
    , 'WHITE - EASTERN EUROPEAN' --     25
  ) then 'white'
  when a.ethnicity in
  (
      'BLACK/AFRICAN AMERICAN' --   5440
    , 'BLACK/CAPE VERDEAN' --    200
    , 'BLACK/HAITIAN' --    101
    , 'BLACK/AFRICAN' --     44
    , 'CARIBBEAN ISLAND' --      9
  ) then 'black'
  when a.ethnicity in
  (
      'HISPANIC OR LATINO' --   1696
    , 'HISPANIC/LATINO - PUERTO RICAN' --    232
    , 'HISPANIC/LATINO - DOMINICAN' --     78
    , 'HISPANIC/LATINO - GUATEMALAN' --     40
    , 'HISPANIC/LATINO - CUBAN' --     24
    , 'HISPANIC/LATINO - SALVADORAN' --     19
    , 'HISPANIC/LATINO - CENTRAL AMERICAN (OTHER)' --     13
    , 'HISPANIC/LATINO - MEXICAN' --     13
    , 'HISPANIC/LATINO - COLOMBIAN' --      9
    , 'HISPANIC/LATINO - HONDURAN' --      4
  ) then 'hispanic'
  else 'other' end as ethnicity

  , se.first_service

  -- outcomes
  , a.hospital_expire_flag
  , case
      when pt.dod <= a.admittime + interval '30' day then 1
    else 0 end as thirtyday_expire_flag
  , case
      when pt.dod <= a.admittime + interval '1' year then 1
    else 0 end as oneyear_expire_flag
  , co.duration_first_vent_days
  , tvd.duration_vent_total_days

  -- ventilator free days
  , case when a.deathttime < (starttime_first_vent + interval '28' day) then 0
         when pt.dod < (starttime_first_vent + interval '28' day) then 0
         when tvd.duration_first_vent_days > 28 then 0
        else 28-tvd.duration_first_vent_days end
      as ventilator_free_days

  , extract(epoch from ie.outtime - ie.intime)/60.0/60.0/24.0 as icu_los_days
  , extract(epoch from a.dischtime - a.admittime)/60.0/60.0/24.0 as hosp_los_days

  , primary_dx.icd9_code
  , primary_dx.short_title
  , primary_dx.long_title

  -- ventilation time`
  , case when tvd.starttime < ie.intime + interval '24' hour then 1 else 0 end
      as ventfirstday

from mpwr_cohort co
inner join icustays ie
  on co.icustay_id = ie.icustay_id
inner join admissions a
  on co.hadm_id = a.hadm_id
inner join patients pt
  on co.subject_id = pt.subject_id
left join heightweight hw
  on co.icustay_id = hw.icustay_id
left join serv se
  on co.icustay_id = se.icustay_id
  and se.rn = 1
left join primary_dx
  on co.hadm_id = primary_dx.hadm_id
left join mpwr_smoker smk
  on co.subject_id = smk.subject_id
left join totalventdur tvd
  on co.icustay_id = tvd.icustay_id
order by co.icustay_id;
