DROP TABLE IF EXISTS mpwr_mech_power cascade;
CREATE TABLE mpwr_mech_power as

with vs_1day as
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
  , min(resp_rate_total) as resp_rate_total_min
  , max(resp_rate_total) as resp_rate_total_max

from icustays ie
left join ventsettings_ali vs
  on ie.icustay_id = vs.icustay_id
  and vs.charttime between ie.intime and ie.intime + interval '1' day
group by ie.subject_id, ie.hadm_id, ie.icustay_id
)
, vs_2day as
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
  , min(resp_rate_total) as resp_rate_total_min
  , max(resp_rate_total) as resp_rate_total_max

from icustays ie
left join ventsettings_ali vs
  on ie.icustay_id = vs.icustay_id
  and vs.charttime between ie.intime and ie.intime + interval '2' day
group by ie.subject_id, ie.hadm_id, ie.icustay_id
)
select
  ie.subject_id, ie.hadm_id, ie.icustay_id

  , vs_1day.mechanical_power_min as mechanical_power_min_1day
  , vs_1day.mechanical_power_max as mechanical_power_max_1day
  , vs_1day.tidal_volume_min as tidal_volume_min_1day
  , vs_1day.tidal_volume_max as tidal_volume_max_1day
  , vs_1day.peep_min as peep_min_1day
  , vs_1day.peep_max as peep_max_1day
  , vs_1day.plateau_pressure_min as plateau_pressure_min_1day
  , vs_1day.plateau_pressure_max as plateau_pressure_max_1day
  , vs_1day.peak_insp_pressure_min as peak_insp_pressure_min_1day
  , vs_1day.peak_insp_pressure_max as peak_insp_pressure_max_1day
  , vs_1day.resp_rate_total_min as resp_rate_total_min_1day
  , vs_1day.resp_rate_total_max as resp_rate_total_max_1day


  , vs_2day.mechanical_power_min as mechanical_power_min_2day
  , vs_2day.mechanical_power_max as mechanical_power_max_2day
  , vs_2day.tidal_volume_min as tidal_volume_min_2day
  , vs_2day.tidal_volume_max as tidal_volume_max_2day
  , vs_2day.peep_min as peep_min_2day
  , vs_2day.peep_max as peep_max_2day
  , vs_2day.plateau_pressure_min as plateau_pressure_min_2day
  , vs_2day.plateau_pressure_max as plateau_pressure_max_2day
  , vs_2day.peak_insp_pressure_min as peak_insp_pressure_min_2day
  , vs_2day.peak_insp_pressure_max as peak_insp_pressure_max_2day
  , vs_2day.resp_rate_total_min as resp_rate_total_min_2day
  , vs_2day.resp_rate_total_max as resp_rate_total_max_2day

from icustays ie
left join vs_2day
  on ie.icustay_id = vs_2day.icustay_id
left join vs_1day
  on ie.icustay_id = vs_1day.icustay_id
order by ie.icustay_id;
