DROP TABLE IF EXISTS public.mp_htwt CASCADE;
CREATE TABLE public.mp_htwt AS
-- extract weight from the charted data
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
  and NURSINGCHARTOFFSET < 60*24
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
  and INTAKEOUTPUTOFFSET < 60*24
)
-- weight from infusiondrug
, t3 as
(
  select
    patientunitstayid
    , cast(PATIENTWEIGHT as double precision) as weight
  from infusiondrug
  where PATIENTWEIGHT is not null
  and INFUSIONOFFSET < 60*24
  and PATIENTWEIGHT~'^([0-9]+\.?[0-9]*|\.[0-9]+)$'
)
-- combine together all weights
, wt as
(
  SELECT patientunitstayid, weight
  FROM t1
  UNION ALL
  SELECT patientunitstayid, weight
  FROM t2
  UNION ALL
  SELECT patientunitstayid, weight
  FROM t3
)
, wt_median as
(
  select
    wt.patientunitstayid
    , percentile_disc(0.5) WITHIN GROUP ( ORDER BY wt.weight ) as weight
  from wt
  group by wt.patientunitstayid
)
-- NOTE: we do not extract height from charted data, but it's feasible
-- valid height labels in nursecharting:
-- , 'Height Measurement Type'
-- , 'Height (Feet)'
-- , 'Height/Length'
-- , 'Height Method'
-- , 'Height CM'
-- , 'Height/Length Estimated'
-- , 'Height'
-- , 'Height (Calculated Centimeters)'
-- , 'Last Documented Height/Weight/BMI'
-- , 'HEIGHT/LENGTH CM'
-- , 'Patient Height for Calculated IBW/ABW/BEE'
-- , 'Height in Inches'
-- , 'Height in cm'
-- , 'Height (Inches)'
-- , 'Calculated Height in cm'
-- get data from patient table and check for swapped height/weight
, htwt as
(
SELECT
  patientunitstayid
  , admissionheight as height
  , admissionweight as weight
  , CASE
    -- CHECK weight vs. height are swapped
    WHEN  admissionweight >= 100
      AND admissionheight >  25 AND admissionheight <= 100
      AND abs(admissionheight-admissionweight) >= 20
    THEN 'swap'
    END AS method
  FROM patient
)
, htwt_fixed as
(
  SELECT
    patientunitstayid
    , CASE
      WHEN method = 'swap' THEN weight
      WHEN height <= 0.30 THEN NULL
      WHEN height <= 2.5 THEN height*100
      WHEN height <= 10 THEN NULL
      WHEN height <= 25 THEN height*10
      -- CHECK weight in both columns
      WHEN height <= 100 AND abs(height-weight) < 20 THEN NULL
      WHEN height  > 250 THEN NULL
      ELSE height END as height_fixed
    , CASE
      WHEN method = 'swap' THEN height
      WHEN weight <= 20 THEN NULL
      WHEN weight  > 300 THEN NULL
      ELSE weight
      END as weight_fixed
    from htwt
)
select
    pt.patientunitstayid
  , htwtf.height_fixed as height
  , wtm.weight as chartedweight
  , htwtf.weight_fixed as weight
from patient pt
left join wt_median wtm
  on pt.patientunitstayid = wtm.patientunitstayid
left join htwt_fixed htwtf
  on pt.patientunitstayid = htwtf.patientunitstayid
order by pt.patientunitstayid;
