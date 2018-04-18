DROP TABLE IF EXISTS public.mp_vent CASCADE;
CREATE TABLE public.mp_vent as
-- convert vent settings into numeric
with vs as
(
  select p.patientunitstayid
  , p.chartoffset
  , CASE
    -- data is not numeric
    WHEN meanairwaypressure in ('-','.') THEN NULL
    WHEN NOT meanairwaypressure ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN meanairwaypressure::numeric < 0 THEN NULL
    ELSE meanairwaypressure::numeric end as meanairwaypressure
  , CASE
    -- data is not numeric
    WHEN peakpressure in ('-','.') THEN NULL
    WHEN NOT peakpressure ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN peakpressure::numeric < 0 THEN NULL
    ELSE peakpressure::numeric end as peakpressure
  , CASE
    -- data is not numeric
    WHEN plateaupressure in ('-','.') THEN NULL
    WHEN NOT plateaupressure ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN plateaupressure::numeric < 0 THEN NULL
    ELSE plateaupressure::numeric end as plateaupressure
  , CASE
    -- data is not numeric
    WHEN peep in ('-','.') THEN NULL
    WHEN NOT peep ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN peep::numeric < 0 THEN NULL
    ELSE peep::numeric end as peep
  , CASE
      -- data is not numeric
      WHEN tidalvolumeobserved in ('-','.') THEN NULL
      WHEN NOT tidalvolumeobserved ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      -- filter out fractional numbers
      WHEN tidalvolumeobserved::numeric <= 1 THEN NULL
      WHEN tidalvolumeobserved::numeric < 30 THEN tidalvolumeobserved::numeric*htwt.ibw
    ELSE tidalvolumeobserved::numeric end as tidalvolumeobserved
  , CASE
      -- data is not numeric
      WHEN tidalvolume in ('-','.') THEN NULL
      WHEN NOT tidalvolume ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      -- filter out fractional numbers
      WHEN tidalvolume::numeric <= 1 THEN NULL
      WHEN tidalvolume::numeric < 30 THEN tidalvolume::numeric*htwt.ibw
    ELSE tidalvolume::numeric end as tidalvolume
  , CASE
      -- data is not numeric
      WHEN tidalvolumeestimated in ('-','.') THEN NULL
      WHEN NOT tidalvolumeestimated ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      -- filter out fractional numbers
      WHEN tidalvolumeestimated::numeric <= 1 THEN NULL
      WHEN tidalvolumeestimated::numeric < 30 THEN tidalvolumeestimated::numeric*htwt.ibw
    ELSE tidalvolumeestimated::numeric end as tidalvolumeestimated
  , CASE
      -- data is not numeric
      WHEN tidalvolumeset in ('-','.') THEN NULL
      WHEN NOT tidalvolumeset ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      -- filter out fractional numbers
      WHEN tidalvolumeset::numeric <= 1 THEN NULL
      WHEN tidalvolumeset::numeric < 30 THEN tidalvolumeset::numeric*htwt.ibw
    ELSE tidalvolumeset::numeric end as tidalvolumeset
  , CASE
      -- data is not numeric
      WHEN tidalvolumespontaneous in ('-','.') THEN NULL
      WHEN NOT tidalvolumespontaneous ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      -- filter out fractional numbers
      WHEN tidalvolumespontaneous::numeric <= 1 THEN NULL
      WHEN tidalvolumespontaneous::numeric < 30 THEN tidalvolumespontaneous::numeric*htwt.ibw
    ELSE tidalvolumespontaneous::numeric end as tidalvolumespontaneous
  , CASE
      WHEN fio2 in ('-','.') THEN NULL
      WHEN NOT fio2 ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
      WHEN fio2::numeric <=   0.2 THEN NULL
      WHEN fio2::numeric <=   1.0 THEN fio2::numeric*100.0
      WHEN fio2::numeric <=  20.0 THEN NULL
      WHEN fio2::numeric <= 100.0 THEN fio2::numeric
    ELSE NULL END AS fio2
  , CASE
    -- data is not numeric
    WHEN respiratoryrate in ('-','.') THEN NULL
    WHEN NOT respiratoryrate ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN respiratoryrate::numeric < 0 THEN NULL
    ELSE respiratoryrate::numeric end as respiratoryrate
  , CASE
    -- data is not numeric
    WHEN respiratoryrateset in ('-','.') THEN NULL
    WHEN NOT respiratoryrateset ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN respiratoryrateset::numeric < 0 THEN NULL
    ELSE respiratoryrateset::numeric end as respiratoryrateset
  , CASE
    -- data is not numeric
    WHEN respiratoryratespontaneous in ('-','.') THEN NULL
    WHEN NOT respiratoryratespontaneous ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN respiratoryratespontaneous::numeric < 0 THEN NULL
    ELSE respiratoryratespontaneous::numeric end as respiratoryratespontaneous
  , CASE
    -- data is not numeric
    WHEN rsbi in ('-','.') THEN NULL
    WHEN NOT rsbi ~ '^[-]?[0-9]+[.]?[0-9]*$' THEN NULL
    WHEN rsbi::numeric < 0 THEN NULL
    ELSE rsbi::numeric end as rsbi
  from vent_unpivot_rc p
  -- get IBW from htwt table
  INNER JOIN mp_htwt htwt
    ON p.patientunitstayid = htwt.patientunitstayid
)
-- day 1
, vw1 as
(
  select p.patientunitstayid
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
  from vs p
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.startoffset + (-1*60)
    and p.chartoffset <= co.startoffset + (24*60)
  group by p.patientunitstayid
)
-- day 2
, vw2 as
(
  select p.patientunitstayid
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
  from vs p
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.startoffset + (24*60)
    and p.chartoffset <= co.startoffset + (48*60)
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
    , vw1.meanairwaypressure_min as meanairwaypressure_min_day1
    , vw1.peakpressure_min as peakpressure_min_day1
    , vw1.plateaupressure_min as plateaupressure_min_day1
    , vw1.rsbi_min as rsbi_min_day1
    , vw1.peep_min as peep_min_day1
    , vw1.tidalvolumeobserved_min as tidalvolumeobserved_min_day1
    , vw1.tidalvolumeset_min as tidalvolumeset_min_day1
    , vw1.tidalvolumespontaneous_min as tidalvolumespontaneous_min_day1
    , vw1.meanairwaypressure_max as meanairwaypressure_max_day1
    , vw1.peakpressure_max as peakpressure_max_day1
    , vw1.plateaupressure_max as plateaupressure_max_day1
    , vw1.rsbi_max as rsbi_max_day1
    , vw1.peep_max as peep_max_day1
    , vw1.tidalvolumeobserved_max as tidalvolumeobserved_max_day1
    , vw1.tidalvolumeset_max as tidalvolumeset_max_day1
    , vw1.tidalvolumespontaneous_max as tidalvolumespontaneous_max_day1
    , vw1.fio2_min as fio2_min_day1
    , vw1.fio2_max as fio2_max_day1
    , vw1.respiratoryrate_min as respiratoryrate_min_day1
    , vw1.respiratoryrate_max as respiratoryrate_max_day1
    , vw1.respiratoryrateset_min as respiratoryrateset_min_day1
    , vw1.respiratoryrateset_max as respiratoryrateset_max_day1
    , vw1.respiratoryratespontaneous_min as respiratoryratespontaneous_min_day1
    , vw1.respiratoryratespontaneous_max as respiratoryratespontaneous_max_day1

    , vw2.meanairwaypressure_min as meanairwaypressure_min_day2
    , vw2.peakpressure_min as peakpressure_min_day2
    , vw2.plateaupressure_min as plateaupressure_min_day2
    , vw2.rsbi_min as rsbi_min_day2
    , vw2.peep_min as peep_min_day2
    , vw2.tidalvolumeobserved_min as tidalvolumeobserved_min_day2
    , vw2.tidalvolumeset_min as tidalvolumeset_min_day2
    , vw2.tidalvolumespontaneous_min as tidalvolumespontaneous_min_day2
    , vw2.meanairwaypressure_max as meanairwaypressure_max_day2
    , vw2.peakpressure_max as peakpressure_max_day2
    , vw2.plateaupressure_max as plateaupressure_max_day2
    , vw2.rsbi_max as rsbi_max_day2
    , vw2.peep_max as peep_max_day2
    , vw2.tidalvolumeobserved_max as tidalvolumeobserved_max_day2
    , vw2.tidalvolumeset_max as tidalvolumeset_max_day2
    , vw2.tidalvolumespontaneous_max as tidalvolumespontaneous_max_day2
    , vw2.fio2_min as fio2_min_day2
    , vw2.fio2_max as fio2_max_day2
    , vw2.respiratoryrate_min as respiratoryrate_min_day2
    , vw2.respiratoryrate_max as respiratoryrate_max_day2
    , vw2.respiratoryrateset_min as respiratoryrateset_min_day2
    , vw2.respiratoryrateset_max as respiratoryrateset_max_day2
    , vw2.respiratoryratespontaneous_min as respiratoryratespontaneous_min_day2
    , vw2.respiratoryratespontaneous_max as respiratoryratespontaneous_max_day2
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
