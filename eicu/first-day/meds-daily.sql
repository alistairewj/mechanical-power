

DROP TABLE IF EXISTS public.mp_meds CASCADE;
CREATE TABLE public.mp_meds as
with co as
(
  -- define the admission time
  -- 0 means use the administrative admission time
  select
    patientunitstayid
    , 0 as unitadmitoffset
  from patient
)
-- day 1 for medication interface
, vw1 as
(
  select p.patientunitstayid
  , max(norepinephrine) as norepinephrine
  , max(epinephrine) as epinephrine
  , max(dopamine) as dopamine
  , max(dobutamine) as dobutamine
  , max(phenylephrine) as phenylephrine
  , max(vasopressin) as vasopressin
  , max(milrinone) as milrinone
  from pivoted_med p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  group by p.patientunitstayid
)
-- day 1 for infusions
, vw2 as
(
  select p.patientunitstayid
  , max(norepinephrine) as norepinephrine
  , max(epinephrine) as epinephrine
  , max(dopamine) as dopamine
  , max(dobutamine) as dobutamine
  , max(phenylephrine) as phenylephrine
  , max(vasopressin) as vasopressin
  , max(milrinone) as milrinone
  from pivoted_infusion p
  INNER JOIN co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.unitadmitoffset + (-1*60)
    and p.chartoffset <= co.unitadmitoffset + (24*60)
  group by p.patientunitstayid
)
select
    pat.patientunitstayid
  , GREATEST(vw1.norepinephrine, vw2.norepinephrine) as norepinephrine_day1
  , GREATEST(vw1.epinephrine, vw2.epinephrine) as epinephrine_day1
  , GREATEST(vw1.dopamine, vw2.dopamine) as dopamine_day1
  , GREATEST(vw1.dobutamine, vw2.dobutamine) as dobutamine_day1
  , GREATEST(vw1.phenylephrine, vw2.phenylephrine) as phenylephrine_day1
  , GREATEST(vw1.vasopressin, vw2.vasopressin) as vasopressin_day1
  , GREATEST(vw1.milrinone, vw2.milrinone) as milrinone_day1
from patient pat
left join vw1
  on pat.patientunitstayid = vw1.patientunitstayid
left join vw2
  on pat.patientunitstayid = vw2.patientunitstayid
order by pat.patientunitstayid;
