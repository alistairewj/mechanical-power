with sf as
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
        when med.epinephrine > 0
             or med.norepinephrine > 0
             or med.dopamine > 0
             or med.dobutamine > 0 then 3
        -- when rate_dopamine >  5 or rate_epinephrine <= 0.1 or rate_norepinephrine <= 0.1 then 3
        when vi.mbp_min < 70 then 1
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
  left join mp_labs la
    on pt.patientunitstayid = la.patientunitstayid
  left join mp_meds med
    on pt.patientunitstayid = med.patientunitstayid
  left join apacheapsvar aav
    on pt.patientunitstayid = aav.patientunitstayid
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
