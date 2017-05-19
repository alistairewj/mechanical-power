-- final query for all the data


select
  co.icustay_id

  -- demographics
  -- patient characteristics
  , de.height
  , de.weight
  , de.smoking
  , de.gender
  , de.age

  -- admission characteristics
  , de.admission_type
  , de.source_of_admission
  , de.insurance
  , de.marital_status
  , de.ethnicity
  , de.first_service

  -- outcomes
  , de.hospital_expire_flag
  , de.thirtyday_expire_flag
  , de.oneyear_expire_flag
  , de.ventduration_days

  , de.icu_los_days
  , de.hosp_los_days

  , de.icd9_code
  , de.short_title
  , de.long_title

  -- comorbidities
  , comorb.copd
  , comorb.asthma

  , case when vaso.icustay_id is not null then 1 else 0 end as vasopressorsfirstday

  , sa.sapsii, oa.oasis, so.sofa
  , rrt.rrt as rrtfirstday
from mpwr_cohort co
left join mpwr_demographics de
  on co.icustay_id = de.icustay_id
left join mpwr_comorbid comorb
  on co.hadm_id = comorb.hadm_id
left join mpwr_vasopressors vaso
  on co.icustay_id = vaso.icustay_id
left join sapsii sa
  on co.icustay_id = sa.icustay_id
left join oasis oa
  on co.icustay_id = oa.icustay_id
left join sofa so
  on co.icustay_id = so.icustay_id
left join rrtfirstday rrt
  on co.icustay_id = rrt.icustay_id

where co.exclusion_nonadult = 0
and co.exclusion_readmission = 0
and co.exclusion_trach = 0
and co.exclusion_not_vent = 0
and co.exclusion_bad_data = 0;
