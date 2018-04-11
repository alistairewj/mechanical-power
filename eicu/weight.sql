DROP TABLE IF EXISTS public.mp_weight CASCADE;
CREATE TABLE public.mp_weight AS
with t1 as
(
  select
    patientunitstayid
    -- all of the below weights are measured in kg
    , cast(nursingchartvalue as double precision) as weight
  from nursecharting
  where nursingchartcelltypecat = 'Other Vital Signs and Infusions'
  and nursingchartcelltypevallabel in
  ( 'Admission Weight'
  , 'Admit weight'
  , 'WEIGHT in Kg'
  )
  -- ensure that nursingchartvalue is numeric
  and nursingchartvalue~'^([0-9]+\.?[0-9]*|\.[0-9]+)$'
  and NURSINGCHARTOFFSET >= -60 and NURSINGCHARTOFFSET < 60*24
)
-- weight from intake/output table
, t2 as
(
  select
    patientunitstayid
    , case when CELLPATH = 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)'
        then CELLVALUENUMERIC
      else CELLVALUENUMERIC*0.453592
    end as weight
  from intakeoutput
  -- there are ~300 extra (lb) measurements, so we include both
  -- worth considering that this biases the median of all three tables towards these values..
  where CELLPATH in
  ( 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (kg)'
  , 'flowsheet|Flowsheet Cell Labels|I&O|Weight|Bodyweight (lb)'
  )
  and INTAKEOUTPUTOFFSET >= -60 and INTAKEOUTPUTOFFSET < 60*24
)
-- weight from infusiondrug
, t3 as
(
  select
    patientunitstayid
    , cast(PATIENTWEIGHT as double precision) as weight
  from infusiondrug
  where PATIENTWEIGHT is not null
  and INFUSIONOFFSET >= -60 and INFUSIONOFFSET < 60*24
  and PATIENTWEIGHT~'^([0-9]+\.?[0-9]*|\.[0-9]+)$'
)
select
  pt.patientunitstayid
  , percentile_disc(0.5) WITHIN GROUP
  ( ORDER BY coalesce(t1.weight, t2.weight, t3.weight) )
  as weight
from patient pt
left join t1
  on pt.patientunitstayid = t1.patientunitstayid
  and t1.weight >= 30 and t1.weight <= 300
left join t2
  on pt.patientunitstayid = t2.patientunitstayid
  and t2.weight >= 30 and t2.weight <= 300
left join t3
  on pt.patientunitstayid = t3.patientunitstayid
  and t3.weight >= 30 and t3.weight <= 300
group by pt.patientunitstayid
order by pt.patientunitstayid;
