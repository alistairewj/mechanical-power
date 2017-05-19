DROP TABLE IF EXISTS mpwr_mech_power cascade;
CREATE TABLE mpwr_mech_power as

with vs_day1 as
(
  select
  ie.subject_id, ie.hadm_id, ie.icustay_id


  , min(0.098*resp_rate_total*(tidal_volume/1000)* ( peak_insp_pressure - (plateau_pressure-peep)/2 )) as mechanical_power_min
  , max(0.098*resp_rate_total*(tidal_volume/1000)* ( peak_insp_pressure - (plateau_pressure-peep)/2 )) as mechanical_power_max
  , min(tidal_volume) as tidal_volume_min
  , max(tidal_volume) as tidal_volume_max
  , min(peep) as peep_min
  , max(peep) as peep_max
  , min(plateau_pressure) as plateau_pressure_min
  , max(plateau_pressure) as plateau_pressure_max
  , min(peak_insp_pressure) as peak_insp_pressure_min
  , max(peak_insp_pressure) as peak_insp_pressure_max
  -- TODO: split set/total
  , min(resp_rate_set) as resp_rate_set_min
  , max(resp_rate_set) as resp_rate_set_max
  , min(resp_rate_total) as resp_rate_total_min
  , max(resp_rate_total) as resp_rate_total_max

from icustays ie
left join mpwr_vent_unpivot vs
  on ie.icustay_id = vs.icustay_id
  and vs.charttime between ie.intime and ie.intime + interval '1' day
group by ie.subject_id, ie.hadm_id, ie.icustay_id
)
, vs_day2 as
(
select
  ie.subject_id, ie.hadm_id, ie.icustay_id

  , min(0.098*resp_rate_total*(tidal_volume/1000)* ( peak_insp_pressure - (plateau_pressure-peep)/2 )) as mechanical_power_min
  , max(0.098*resp_rate_total*(tidal_volume/1000)* ( peak_insp_pressure - (plateau_pressure-peep)/2 )) as mechanical_power_max
  , min(tidal_volume) as tidal_volume_min
  , max(tidal_volume) as tidal_volume_max
  , min(peep) as peep_min
  , max(peep) as peep_max
  , min(plateau_pressure) as plateau_pressure_min
  , max(plateau_pressure) as plateau_pressure_max
  , min(peak_insp_pressure) as peak_insp_pressure_min
  , max(peak_insp_pressure) as peak_insp_pressure_max
  , min(resp_rate_set) as resp_rate_set_min
  , max(resp_rate_set) as resp_rate_set_max
  , min(resp_rate_total) as resp_rate_total_min
  , max(resp_rate_total) as resp_rate_total_max

from icustays ie
left join mpwr_vent_unpivot vs
  on ie.icustay_id = vs.icustay_id
  and vs.charttime between ie.intime + interval '1' day and ie.intime + interval '2' day
group by ie.subject_id, ie.hadm_id, ie.icustay_id
)
, vs_mode as
(
  select
    vs.icustay_id, vs.value as ventmode
    , ROW_NUMBER() over (partition by ie.icustay_id order by vs.charttime) rn_first
    , ROW_NUMBER() over (partition by ie.icustay_id order by vs.charttime desc) rn_last
  from icustays ie
  inner join mpwr_chartevents_vent vs
    on ie.icustay_id = vs.icustay_id
  where vs.value is not null and vs.value != 'Other/Remarks'
  and vs.charttime <= ie.intime + interval '2' day
  and vs.charttime >= ie.intime - interval '1' day
)
select
  ie.subject_id, ie.hadm_id, ie.icustay_id

  , vs_day1.mechanical_power_min as mechanical_power_min_day1
  , vs_day1.mechanical_power_max as mechanical_power_max_day1
  , vs_day1.tidal_volume_min as tidal_volume_min_day1
  , vs_day1.tidal_volume_max as tidal_volume_max_day1
  , vs_day1.peep_min as peep_min_day1
  , vs_day1.peep_max as peep_max_day1
  , vs_day1.plateau_pressure_min as plateau_pressure_min_day1
  , vs_day1.plateau_pressure_max as plateau_pressure_max_day1
  , vs_day1.peak_insp_pressure_min as peak_insp_pressure_min_day1
  , vs_day1.peak_insp_pressure_max as peak_insp_pressure_max_day1
  , vs_day1.resp_rate_set_min as resp_rate_set_min_day1
  , vs_day1.resp_rate_set_max as resp_rate_set_max_day1
  , vs_day1.resp_rate_total_min as resp_rate_total_min_day1
  , vs_day1.resp_rate_total_max as resp_rate_total_max_day1


  , vs_day2.mechanical_power_min as mechanical_power_min_day2
  , vs_day2.mechanical_power_max as mechanical_power_max_day2
  , vs_day2.tidal_volume_min as tidal_volume_min_day2
  , vs_day2.tidal_volume_max as tidal_volume_max_day2
  , vs_day2.peep_min as peep_min_day2
  , vs_day2.peep_max as peep_max_day2
  , vs_day2.plateau_pressure_min as plateau_pressure_min_day2
  , vs_day2.plateau_pressure_max as plateau_pressure_max_day2
  , vs_day2.peak_insp_pressure_min as peak_insp_pressure_min_day2
  , vs_day2.peak_insp_pressure_max as peak_insp_pressure_max_day2
  , vs_day2.resp_rate_set_min as resp_rate_set_min_day2
  , vs_day2.resp_rate_set_max as resp_rate_set_max_day2
  , vs_day2.resp_rate_total_min as resp_rate_total_min_day2
  , vs_day2.resp_rate_total_max as resp_rate_total_max_day2

  -- ventilator modes
  , vs1.ventmode as ventmode_first
  , vs2.ventmode as ventmode_last
from icustays ie
left join vs_day2
  on ie.icustay_id = vs_day2.icustay_id
left join vs_day1
  on ie.icustay_id = vs_day1.icustay_id
left join vs_mode vs1
  on ie.icustay_id = vs1.icustay_id
  and vs1.rn_first = 1
left join vs_mode vs2
  on ie.icustay_id = vs2.icustay_id
  and vs2.rn_last = 1
order by ie.icustay_id;
