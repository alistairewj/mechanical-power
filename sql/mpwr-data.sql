-- final query for all the data
DROP TABLE IF EXISTS mpwr_data CASCADE;
CREATE TABLE mpwr_data AS
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
  , de.duration_first_vent_days
  , de.duration_vent_total_days

  , de.icu_los_days
  , de.hosp_los_days

  , de.icd9_code
  , de.short_title
  , de.long_title

  -- comorbidities
  , comorb.copd
  , comorb.asthma
  , eli.elixhauser_vanwalraven
  , case when vaso.starttime is not null then 1 else 0 end as vasopressorsfirstday
  , ards.ards
  , ards.ards_severity

  -- scores
  , sa.sapsii, oa.oasis, so.sofa

  -- vitals
  , vi.HeartRate_Min_day1
  , vi.HeartRate_Max_day1
  , vi.HeartRate_Mean_day1
  , vi.MeanBP_Min_day1
  , vi.MeanBP_Max_day1
  , vi.MeanBP_Mean_day1
  , vi.TempC_Min_day1
  , vi.TempC_Max_day1
  , vi.TempC_Mean_day1
  , vi.SpO2_Min_day1
  , vi.SpO2_Max_day1
  , vi.SpO2_Mean_day1
  , vi.RASS_Min_day1
  , vi.RASS_Max_day1
  , vi.RASS_Mean_day1
  , vi.EtCO2_Min_day1
  , vi.EtCO2_Max_day1
  , vi.EtCO2_Mean_day1

  , vi.HeartRate_Min_day2
  , vi.HeartRate_Max_day2
  , vi.HeartRate_Mean_day2
  , vi.MeanBP_Min_day2
  , vi.MeanBP_Max_day2
  , vi.MeanBP_Mean_day2
  , vi.TempC_Min_day2
  , vi.TempC_Max_day2
  , vi.TempC_Mean_day2
  , vi.SpO2_Min_day2
  , vi.SpO2_Max_day2
  , vi.SpO2_Mean_day2
  , vi.RASS_Min_day2
  , vi.RASS_Max_day2
  , vi.RASS_Mean_day2
  , vi.EtCO2_Min_day2
  , vi.EtCO2_Max_day2
  , vi.EtCO2_Mean_day2

  -- labs
  , la.pao2_min_day1
  , la.pao2_max_day1
  , la.paco2_min_day1
  , la.paco2_max_day1
  , la.ph_min_day1
  , la.ph_max_day1
  , la.lactate_min_day1
  , la.lactate_max_day1

  , la.pao2_min_day2
  , la.pao2_max_day2
  , la.paco2_min_day2
  , la.paco2_max_day2
  , la.ph_min_day2
  , la.ph_max_day2
  , la.lactate_min_day2
  , la.lactate_max_day2

  -- ventilator parameters
  , mp.mechanical_power_min_day1
  , mp.mechanical_power_max_day1
  , mp.tidal_volume_min_day1
  , mp.tidal_volume_max_day1
  , mp.peep_min_day1
  , mp.peep_max_day1
  , mp.plateau_pressure_min_day1
  , mp.plateau_pressure_max_day1
  , mp.peak_insp_pressure_min_day1
  , mp.peak_insp_pressure_max_day1
  , mp.resp_rate_set_min_day1
  , mp.resp_rate_set_max_day1
  , mp.resp_rate_total_min_day1
  , mp.resp_rate_total_max_day1

  , mp.mechanical_power_min_day2
  , mp.mechanical_power_max_day2
  , mp.tidal_volume_min_day2
  , mp.tidal_volume_max_day2
  , mp.peep_min_day2
  , mp.peep_max_day2
  , mp.plateau_pressure_min_day2
  , mp.plateau_pressure_max_day2
  , mp.peak_insp_pressure_min_day2
  , mp.peak_insp_pressure_max_day2
  , mp.resp_rate_set_min_day2
  , mp.resp_rate_set_max_day2
  , mp.resp_rate_total_min_day2
  , mp.resp_rate_total_max_day2

  , rrt.rrt as rrtfirstday
  , de.ventfirstday

from mpwr_cohort co
left join mpwr_demographics de
  on co.icustay_id = de.icustay_id
left join mpwr_comorbid comorb
  on co.hadm_id = comorb.hadm_id
left join mpwr_vasopressors vaso
  on co.icustay_id = vaso.icustay_id
left join elixhauser_ahrq_score eli
  on co.hadm_id = eli.hadm_id
left join mpwr_ards ards
  on co.icustay_id = ards.icustay_id
left join mpwr_vitals vi
  on co.icustay_id = vi.icustay_id
left join mpwr_labs la
  on co.icustay_id = la.icustay_id
left join mpwr_mech_power mp
  on co.icustay_id = mp.icustay_id
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
