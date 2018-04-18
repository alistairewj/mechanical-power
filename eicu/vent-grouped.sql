DROP TABLE IF EXISTS public.mp_vent_grouped CASCADE;
CREATE TABLE public.mp_vent_grouped as
with vs as
(
  select p.patientunitstayid
    -- covert into integers representing the 6 hour block
    , FLOOR((chartoffset-unitadmitoffset)/60.0/6.0)::INT as block
    , meanairwaypressure
    , peakpressure
    , plateaupressure
    , peep
    , CASE
        WHEN tidalvolumeobserved <= 0 THEN NULL
        WHEN tidalvolumeobserved < 30 THEN tidalvolumeobserved*htwt.ibw
      ELSE tidalvolumeobserved end as tidalvolumeobserved
    , CASE
        WHEN tidalvolume <= 0 THEN NULL
        WHEN tidalvolume < 30 THEN tidalvolume*htwt.ibw
      ELSE tidalvolume end as tidalvolume
    , CASE
        WHEN tidalvolumeestimated <= 0 THEN NULL
        WHEN tidalvolumeestimated < 30 THEN tidalvolumeestimated*htwt.ibw
      ELSE tidalvolumeestimated end as tidalvolumeestimated
    , CASE
        WHEN tidalvolume <= 0 THEN NULL
        WHEN tidalvolume < 30 THEN tidalvolume*htwt.ibw
      ELSE tidalvolume end as tidalvolume
    , CASE
        WHEN tidalvolumeset <= 0 THEN NULL
        WHEN tidalvolumeset < 30 THEN tidalvolumeset*htwt.ibw
      ELSE tidalvolumeset end as tidalvolumeset
    , CASE
        WHEN tidalvolumespontaneous <= 0 THEN NULL
        WHEN tidalvolumespontaneous < 30 THEN tidalvolumespontaneous*htwt.ibw
      ELSE tidalvolumespontaneous end as tidalvolumespontaneous
    , CASE
        WHEN fio2 <=   0.2 THEN NULL
        WHEN fio2 <=   1.0 THEN fio2*100.0
        WHEN fio2 <=  20.0 THEN NULL
        WHEN fio2 <= 100.0 THEN fio2
      ELSE NULL END AS fio2
    , respiratoryrate
    , respiratoryrateset
    , respiratoryratespontaneous
    , rsbi
  from vent_unpivot_rc p
  -- only include settings before 8*6=48 hours
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.startoffset
    and p.chartoffset <= co.startoffset + (48*60)
  -- get IBW from htwt table
  INNER JOIN mp_htwt htwt
    ON p.patientunitstayid = htwt.patientunitstayid
  -- filter to hospitals with peak pressure recorded
  INNER JOIN hospitals_with_vent_data ho
    ON  co.hospitalid = ho.hospitalid
)
select vs.patientunitstayid
  , vs.block
  , min(meanairwaypressure) as meanairwaypressure_min
  , min(peakpressure) as peakpressure_min
  , min(plateaupressure) as plateaupressure_min
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
  , max(plateaupressure) as plateaupressure_max
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
