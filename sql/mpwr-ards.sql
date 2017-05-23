-- identifying ARDS in MIMIC-III patients
-- we follow the berlin definition:
--    1) onset of ARDS is acute - we assume this as our cohort is only recently mechanically ventilated patients (i.e. we exclude trach)
--    2) bilateral opacities - we parse the free-text radiology reports for mention of opacities/infiltrates
--    3) peep > 5 - we finally classify ARDS based off pao2/fio2 ratio
--              pao2/fio2 > 300 - None
--        300 > pao2/fio2 > 200 - Mild
--        200 > pao2/fio2 > 100 - Moderate
--        100 > pao2/fio2       - Severe

DROP TABLE IF EXISTS mpwr_ards CASCADE;
CREATE TABLE mpwr_ards as
with bl as
(
  select co.icustay_id
    , max(case when nbl.bilateral_infiltrates is null then 0 else nbl.bilateral_infiltrates end) as bilateral_infiltrates
  from mpwr_cohort co
  left join notes_bilateral_infiltrates nbl
    on co.hadm_id = nbl.hadm_id
    and nbl.charttime >= co.intime - interval '1' day
    and nbl.charttime <= co.intime + interval '1' day
  group by co.icustay_id
)
, ards_stg0 as
(
  SELECT pf.icustay_id, pf.charttime
    , case
        when pf.pao2fio2 is null then null
        when pf.peep is null then null
        -- non-acute is not ARDS
        when tr.trach = 1 then 0
        -- no bilateral infiltrates is not ARDS
        when bl.bilateral_infiltrates = 0 then 0
        when pf.peep >= 5 and pf.pao2fio2 > 300 then 0
        when pf.peep >= 5 and pf.pao2fio2 > 200 then 1
        when pf.peep >= 5 and pf.pao2fio2 > 100 then 2
        when pf.peep >= 5 and pf.pao2fio2 > 0 then 3
      else null end
    as ards_severity
    , pf.pao2fio2, pf.peep, bl.bilateral_infiltrates, tr.trach
  from mpwr_pao2fio2peep pf
  -- trach in the first 3 days
  left join mpwr_trach tr
    on pf.icustay_id = tr.icustay_id
  left join bl
    on pf.icustay_id = bl.icustay_id
)
, ards_stg1 as
(
  select icustay_id, charttime
    , ards_severity
    , bilateral_infiltrates, trach
    , pao2fio2, peep
    , ROW_NUMBER() over (PARTITION BY icustay_id ORDER BY ards_severity desc, pao2fio2, charttime) as rn
  from ards_stg0
)
select ie.icustay_id
  , ar.charttime
  , case
        when ar.icustay_id is null then 0
        when ar.ards_severity is null then 0
        when ar.ards_severity = 0 then 0
    else 1 end as ards
  , ar.ards_severity
  , ar.bilateral_infiltrates
  , ar.trach
  , ar.pao2fio2
  , ar.peep
from icustays ie
left join ards_stg1 ar
  on ie.icustay_id = ar.icustay_id
  and ar.rn = 1
order by ie.icustay_id;
