DROP TABLE IF EXISTS mp_sofa CASCADE;
CREATE TABLE mp_sofa AS
-- day 1 labs
with la as
(
  select p.patientunitstayid
  , min(bilirubin) as bilirubin_min_day1
  , max(bilirubin) as bilirubin_max_day1
  , min(creatinine) as creatinine_min_day1
  , max(creatinine) as creatinine_max_day1
  , min(platelets) as platelets_min_day1
  , max(platelets) as platelets_max_day1
  from pivoted_lab p
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.admitoffset + (-1*60)
    and p.chartoffset <= co.admitoffset + (24*60)
  group by p.patientunitstayid
)
-- day 1 for medication interface
, mi as
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
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.admitoffset + (-1*60)
    and p.chartoffset <= co.admitoffset + (24*60)
  group by p.patientunitstayid
)
-- day 1 for infusions
, inf as
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
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.admitoffset + (-1*60)
    and p.chartoffset <= co.admitoffset + (24*60)
  group by p.patientunitstayid
)
-- combine medication + infusion tables
, med as
(
  select
      pat.patientunitstayid
    , GREATEST(mi.norepinephrine, inf.norepinephrine) as norepinephrine_day1
    , GREATEST(mi.epinephrine, inf.epinephrine) as epinephrine_day1
    , GREATEST(mi.dopamine, inf.dopamine) as dopamine_day1
    , GREATEST(mi.dobutamine, inf.dobutamine) as dobutamine_day1
    , GREATEST(mi.phenylephrine, inf.phenylephrine) as phenylephrine_day1
    , GREATEST(mi.vasopressin, inf.vasopressin) as vasopressin_day1
    , GREATEST(mi.milrinone, inf.milrinone) as milrinone_day1
  from patient pat
  left join mi
    on pat.patientunitstayid = mi.patientunitstayid
  left join inf
    on pat.patientunitstayid = inf.patientunitstayid
)
-- get vital signs
, vi as
(
  select p.patientunitstayid
  , min(heartrate) as heartrate_min_day1
  , max(heartrate) as heartrate_max_day1
  , min(map) as map_min_day1
  , max(map) as map_max_day1
  , min(temperature) as temperature_min_day1
  , max(temperature) as temperature_max_day1
  , min(o2saturation) as spo2_min_day1
  , max(o2saturation) as spo2_max_day1
  from pivoted_vital p
  INNER JOIN mp_cohort co
    ON  p.patientunitstayid = co.patientunitstayid
    and p.chartoffset >  co.admitoffset + (-1*60)
    and p.chartoffset <= co.admitoffset + (24*60)
  WHERE heartrate IS NOT NULL
  OR map IS NOT NULL
  OR temperature IS NOT NULL
  OR o2saturation IS NOT NULL
  group by p.patientunitstayid
)
-- calculate SOFA
, sf as
(
  SELECT
    pt.patientunitstayid
    , case
        when aav.pao2 = -1 then 0
        when aav.fio2 = -1 then 0
        -- ventilated
        when apv.VENTDAY1 = 1
          then
          case
            when (aav.pao2 / aav.fio2 * 100) < 100 then 4
            when (aav.pao2 / aav.fio2 * 100) < 200 then 3
          else 0 end
        when (aav.pao2 / aav.fio2 * 100) < 300 then 2
        when (aav.pao2 / aav.fio2 * 100) < 400 then 1
      else 0
    end as sofa_respiration

    -- Coagulation
    , case
        when la.platelets_min_day1 < 20  then 4
        when la.platelets_min_day1 < 50  then 3
        when la.platelets_min_day1 < 100 then 2
        when la.platelets_min_day1 < 150 then 1
        else 0
    end as sofa_coagulation

    -- Liver
    , case
        -- Bilirubin checks in mg/dL
        when la.bilirubin_max_day1 >= 12.0 then 4
        when la.bilirubin_max_day1 >= 6.0  then 3
        when la.bilirubin_max_day1 >= 2.0  then 2
        when la.bilirubin_max_day1 >= 1.2  then 1
        else 0
      end as sofa_liver

    -- Cardiovascular
    , case
        when med.epinephrine_day1 > 0
             or med.norepinephrine_day1 > 0
             or med.dopamine_day1 > 0
             or med.dobutamine_day1 > 0 then 3
        -- when rate_dopamine >  5 or rate_epinephrine <= 0.1 or rate_norepinephrine <= 0.1 then 3
        when vi.map_min_day1 < 70 then 1
        else 0
      end as sofa_cardiovascular

    -- Neurological failure (GCS)
    , case
        when aav.meds = -1 or aav.eyes = -1 or aav.motor = -1 or aav.verbal = -1 then 0
        when aav.meds = 1 then 0
        when (aav.eyes + aav.motor + aav.verbal >= 13 and aav.eyes + aav.motor + aav.verbal <= 14) then 1
        when (aav.eyes + aav.motor + aav.verbal >= 10 and aav.eyes + aav.motor + aav.verbal <= 12) then 2
        when (aav.eyes + aav.motor + aav.verbal >=  6 and aav.eyes + aav.motor + aav.verbal <=  9) then 3
        when  aav.eyes + aav.motor + aav.verbal <   6 then 4
        -- when coalesce(aav.eyes,aav.motor,aav.verbal) is null then null
        else 0
      end as sofa_cns

    -- Renal failure - high creatinine or low urine output
    , case
        when (la.creatinine_max_day1 >= 5.0) then 4
        when  aav.urine >= 0   and aav.urine < 200 then 4
        when (la.creatinine_max_day1 >= 3.5 and la.creatinine_max_day1 < 5.0) then 3
        when  aav.urine >= 200 and aav.urine < 500 then 3
        when (la.creatinine_max_day1 >= 2.0 and la.creatinine_max_day1 < 3.5) then 2
        when (la.creatinine_max_day1 >= 1.2 and la.creatinine_max_day1 < 2.0) then 1
        -- when coalesce(UrineOutput, creatinine_max_day1) is null then null
        else 0
      end as sofa_renal
  from patient pt
  left join la
    on pt.patientunitstayid = la.patientunitstayid
  left join med
    on pt.patientunitstayid = med.patientunitstayid
  left join vi
    on pt.patientunitstayid = vi.patientunitstayid
  left join apacheapsvar aav
    on pt.patientunitstayid = aav.patientunitstayid
  left join apachepredvar apv
    on pt.patientunitstayid = apv.patientunitstayid
)
select
  sf.patientunitstayid
  , sf.sofa_cardiovascular
  , sf.sofa_renal
  , sf.sofa_cns
  , sf.sofa_coagulation
  , sf.sofa_liver
  , sf.sofa_respiration
  -- calculate total
  , sf.sofa_cardiovascular
    + sf.sofa_renal
    + sf.sofa_cns
    + sf.sofa_coagulation
    + sf.sofa_liver
    + sf.sofa_respiration
    AS sofa
from sf
order by sf.patientunitstayid;
