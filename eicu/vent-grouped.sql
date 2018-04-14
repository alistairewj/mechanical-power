DROP TABLE IF EXISTS public.mp_vent_grouped CASCADE;
CREATE TABLE public.mp_vent_grouped as
with co as
(
  -- define the admission time
  -- 0 means use the administrative admission time
  select
    patientunitstayid
    , 0 as unitadmitoffset
  from patient
)
, vs as
(
  select p.patientunitstayid
    -- covert into integers representing the 6 hour block
    , FLOOR((chartoffset-unitadmitoffset)/60.0/6.0)::INT as block
    , meanairwaypressure
    , peakpressure
    , peakflow
    , plateaupressure
    , pressuresupportpressure
    , pressurecontrolpressure
    , rsbi
    , peep
    , tidalvolumeobserved
    , tidalvolumeestimated
    , tidalvolume
    , tidalvolumeset
    , tidalvolumespontaneous
    , fio2
    , respiratoryrate
    , respiratoryrateset
    , respiratoryratespontaneous
  from vent_unpivot_rc p
  -- only include settings before 8*6=48 hours
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset
    and p.chartoffset <= co.unitadmitoffset + (48*60)
  WHERE coalesce(tidalvolumeobserved,tidalvolumeestimated,tidalvolume,tidalvolumeset,tidalvolumespontaneous) IS NOT NULL
)
select vs.patientunitstayid
  , vs.block
  , min(meanairwaypressure) as meanairwaypressure_min
  , min(peakpressure) as peakpressure_min
  , min(peakflow) as peakflow_min
  , min(plateaupressure) as plateaupressure_min
  , min(pressuresupportpressure) as pressuresupportpressure_min
  , min(pressurecontrolpressure) as pressurecontrolpressure_min
  , min(rsbi) as rsbi_min
  , min(peep) as peep_min
  , min(coalesce(tidalvolumeobserved,tidalvolumeestimated,tidalvolume)) as tidalvolumeobserved_min
  , min(tidalvolumeset) as tidalvolumeset_min
  , min(tidalvolumespontaneous) as tidalvolumespontaneous_min
  , min(fio2) as fio2_min
  , min(respiratoryrate) as respiratoryrate_min
  , min(respiratoryrateset) as respiratoryrateset_min
  , min(respiratoryratespontaneous) as respiratoryratespontaneous_min

  , max(meanairwaypressure) as meanairwaypressure_max
  , max(peakpressure) as peakpressure_max
  , max(peakflow) as peakflow_max
  , max(plateaupressure) as plateaupressure_max
  , max(pressuresupportpressure) as pressuresupportpressure_max
  , max(pressurecontrolpressure) as pressurecontrolpressure_max
  , max(rsbi) as rsbi_max
  , max(peep) as peep_max
  , max(coalesce(tidalvolumeobserved,tidalvolumeestimated,tidalvolume)) as tidalvolumeobserved_max
  , max(tidalvolumeset) as tidalvolumeset_max
  , max(tidalvolumespontaneous) as tidalvolumespontaneous_max
  , max(fio2) as fio2_max
  , max(respiratoryrate) as respiratoryrate_max
  , max(respiratoryrateset) as respiratoryrateset_max
  , max(respiratoryratespontaneous) as respiratoryratespontaneous_max
from vs
GROUP BY vs.patientunitstayid, vs.block
order by vs.patientunitstayid, vs.block;
