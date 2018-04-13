DROP TABLE IF EXISTS public.mp_vent CASCADE;
CREATE TABLE public.mp_vent as
with co as
(
  -- define the admission time
  -- 0 means use the administrative admission time
  select
    patientunitstayid
    , 0 as unitadmitoffset
  from patient
)
-- day 1
, vw1 as
(
  select p.patientunitstayid
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
  from vent_unpivot_rc p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  WHERE coalesce(tidalvolumeobserved,tidalvolumeestimated,tidalvolume,tidalvolumeset,tidalvolumespontaneous) IS NOT NULL
  group by p.patientunitstayid
)
-- day 2
, vw2 as
(
  select p.patientunitstayid
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
  from vent_unpivot_rc p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (24*60)
    and p.chartoffset <= co.unitadmitoffset + (48*60)
  WHERE coalesce(tidalvolumeobserved,tidalvolumeestimated,tidalvolume,tidalvolumeset,tidalvolumespontaneous) IS NOT NULL
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
    , vw1.meanairwaypressure_min as meanairwaypressure_min_day1
    , vw1.peakpressure_min as peakpressure_min_day1
    , vw1.peakflow_min as peakflow_min_day1
    , vw1.plateaupressure_min as plateaupressure_min_day1
    , vw1.pressuresupportpressure_min as pressuresupportpressure_min_day1
    , vw1.pressurecontrolpressure_min as pressurecontrolpressure_min_day1
    , vw1.rsbi_min as rsbi_min_day1
    , vw1.peep_min as peep_min_day1
    , vw1.tidalvolumeobserved_min as tidalvolumeobserved_min_day1
    , vw1.tidalvolumeset_min as tidalvolumeset_min_day1
    , vw1.tidalvolumespontaneous_min as tidalvolumespontaneous_min_day1
    , vw1.meanairwaypressure_max as meanairwaypressure_max_day1
    , vw1.peakpressure_max as peakpressure_max_day1
    , vw1.peakflow_max as peakflow_max_day1
    , vw1.plateaupressure_max as plateaupressure_max_day1
    , vw1.pressuresupportpressure_max as pressuresupportpressure_max_day1
    , vw1.pressurecontrolpressure_max as pressurecontrolpressure_max_day1
    , vw1.rsbi_max as rsbi_max_day1
    , vw1.peep_max as peep_max_day1
    , vw1.tidalvolumeobserved_max as tidalvolumeobserved_max_day1
    , vw1.tidalvolumeset_max as tidalvolumeset_max_day1
    , vw1.tidalvolumespontaneous_max as tidalvolumespontaneous_max_day1
    , vw1.fio2_min as fio2_min_day1
    , vw1.fio2_max as fio2_max_day1

    , vw2.meanairwaypressure_min as meanairwaypressure_min_day2
    , vw2.peakpressure_min as peakpressure_min_day2
    , vw2.peakflow_min as peakflow_min_day2
    , vw2.plateaupressure_min as plateaupressure_min_day2
    , vw2.pressuresupportpressure_min as pressuresupportpressure_min_day2
    , vw2.pressurecontrolpressure_min as pressurecontrolpressure_min_day2
    , vw2.rsbi_min as rsbi_min_day2
    , vw2.peep_min as peep_min_day2
    , vw2.tidalvolumeobserved_min as tidalvolumeobserved_min_day2
    , vw2.tidalvolumeset_min as tidalvolumeset_min_day2
    , vw2.tidalvolumespontaneous_min as tidalvolumespontaneous_min_day2
    , vw2.meanairwaypressure_max as meanairwaypressure_max_day2
    , vw2.peakpressure_max as peakpressure_max_day2
    , vw2.peakflow_max as peakflow_max_day2
    , vw2.plateaupressure_max as plateaupressure_max_day2
    , vw2.pressuresupportpressure_max as pressuresupportpressure_max_day2
    , vw2.pressurecontrolpressure_max as pressurecontrolpressure_max_day2
    , vw2.rsbi_max as rsbi_max_day2
    , vw2.peep_max as peep_max_day2
    , vw2.tidalvolumeobserved_max as tidalvolumeobserved_max_day2
    , vw2.tidalvolumeset_max as tidalvolumeset_max_day2
    , vw2.tidalvolumespontaneous_max as tidalvolumespontaneous_max_day2
    , vw2.fio2_min as fio2_min_day2
    , vw2.fio2_max as fio2_max_day2
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
