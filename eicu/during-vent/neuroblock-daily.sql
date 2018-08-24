DROP TABLE IF EXISTS public.mp_neuroblock CASCADE;
CREATE TABLE public.mp_neuroblock as
-- day 1
with vw1 as
(
  select p.patientunitstayid
  , 1 as neuroblock
  from neuroblock p
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
  , 1 as neuroblock
  from neuroblock p
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.startoffset + (24*60)
    and p.chartoffset <= co.startoffset + (48*60)
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
  , COALESCE(vw1.neuroblock,0) as neuroblock_day1
  , COALESCE(vw2.neuroblock,0) as neuroblock_day2
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
