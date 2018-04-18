DROP TABLE IF EXISTS public.mp_vitals CASCADE;
CREATE TABLE public.mp_vitals as
with co as
(
  -- define the start time for data extraction
  select
    patientunitstayid
    , starttime as unitadmitoffset
  from mp_cohort
)
-- day 1
, vw1 as
(
  select p.patientunitstayid
  , min(heartrate) as heartrate_min
  , max(heartrate) as heartrate_max
  , min(map) as map_min
  , max(map) as map_max
  , min(temperature) as temperature_min
  , max(temperature) as temperature_max
  , min(o2saturation) as spo2_min
  , max(o2saturation) as spo2_max
  from pivoted_vital p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  WHERE heartrate IS NOT NULL
  OR map IS NOT NULL
  OR temperature IS NOT NULL
  OR o2saturation IS NOT NULL
  group by p.patientunitstayid
)
-- day 2
, vw2 as
(
  select p.patientunitstayid
  , min(heartrate) as heartrate_min
  , max(heartrate) as heartrate_max
  , min(map) as map_min
  , max(map) as map_max
  , min(temperature) as temperature_min
  , max(temperature) as temperature_max
  , min(o2saturation) as spo2_min
  , max(o2saturation) as spo2_max
  from pivoted_vital p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (24*60)
    and p.chartoffset <= co.unitadmitoffset + (48*60)
  WHERE heartrate IS NOT NULL
  OR map IS NOT NULL
  OR temperature IS NOT NULL
  OR o2saturation IS NOT NULL
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
  , vw1.heartrate_min as heartrate_min_day1
  , vw1.heartrate_max as heartrate_max_day1
  , vw1.map_min as map_min_day1
  , vw1.map_max as map_max_day1
  , vw1.temperature_min as temperature_min_day1
  , vw1.temperature_max as temperature_max_day1
  , vw1.spo2_min as spo2_min_day1
  , vw1.spo2_max as spo2_max_day1

  , vw2.heartrate_min as heartrate_min_day2
  , vw2.heartrate_max as heartrate_max_day2
  , vw2.map_min as map_min_day2
  , vw2.map_max as map_max_day2
  , vw2.temperature_min as temperature_min_day2
  , vw2.temperature_max as temperature_max_day2
  , vw2.spo2_min as spo2_min_day2
  , vw2.spo2_max as spo2_max_day2
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
