
DROP TABLE IF EXISTS mpwr_oxy_params CASCADE;
create table mpwr_oxy_params as
with pvt as
( -- begin query that extracts the data
  select co.icustay_id
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
      , case
        when itemid = 50800 then 'SPECIMEN'
        when itemid = 50801 then 'AADO2'
        when itemid = 50802 then 'BASEEXCESS'
        when itemid = 50803 then 'BICARBONATE'
        when itemid = 50804 then 'TOTALCO2'
        when itemid = 50805 then 'CARBOXYHEMOGLOBIN'
        when itemid = 50806 then 'CHLORIDE'
        when itemid = 50808 then 'CALCIUM'
        when itemid = 50809 then 'GLUCOSE'
        when itemid = 50810 then 'HEMATOCRIT'
        when itemid = 50811 then 'HEMOGLOBIN'
        when itemid = 50812 then 'INTUBATED'
        when itemid = 50813 then 'LACTATE'
        when itemid = 50814 then 'METHEMOGLOBIN'
        when itemid = 50815 then 'O2FLOW'
        when itemid = 50816 then 'FIO2'
        when itemid = 50817 then 'SO2' -- OXYGENSATURATION
        when itemid = 50818 then 'PCO2'
        when itemid = 50819 then 'PEEP'
        when itemid = 50820 then 'PH'
        when itemid = 50821 then 'PO2'
        when itemid = 50822 then 'POTASSIUM'
        when itemid = 50823 then 'REQUIREDO2'
        when itemid = 50824 then 'SODIUM'
        when itemid = 50825 then 'TEMPERATURE'
        when itemid = 50826 then 'TIDALVOLUME'
        when itemid = 50827 then 'VENTILATIONRATE'
        when itemid = 50828 then 'VENTILATOR'
        else null
        end as label
        , charttime
        , value
        -- add in some sanity checks on the values
        , case
          when valuenum <= 0 then null
          when itemid = 50810 and valuenum > 100 then null -- hematocrit
          when itemid = 50816 and valuenum > 100 then null -- FiO2
          when itemid = 50816 and valuenum <= 1 then valuenum * 100
          when itemid = 50817 and valuenum > 100 then null -- O2 sat
          when itemid = 50815 and valuenum >  70 then null -- O2 flow
          when itemid = 50821 and valuenum > 800 then null -- PO2
           -- conservative upper limit
        else valuenum
        end as valuenum

    from mpwr_cohort co
    left join labevents le
      on le.subject_id = co.subject_id
      and le.charttime between co.starttime_first_vent and co.starttime_first_vent + interval '2' day
      and le.ITEMID in
      -- blood gases
      (
        50800, 50801, 50802, 50803, 50804, 50805, 50806, 50807, 50808, 50809
        , 50810, 50811, 50812, 50813, 50814, 50815, 50816, 50817, 50818, 50819
        , 50820, 50821, 50822, 50823, 50824, 50825, 50826, 50827, 50828
        , 51545
      )
)
select pvt.ICUSTAY_ID, pvt.CHARTTIME
, max(case when label = 'SPECIMEN' then value else null end) as SPECIMEN
, max(case when label = 'AADO2' then valuenum else null end) as AADO2
, max(case when label = 'BASEEXCESS' then valuenum else null end) as BASEEXCESS
, max(case when label = 'BICARBONATE' then valuenum else null end) as BICARBONATE
, max(case when label = 'TOTALCO2' then valuenum else null end) as TOTALCO2
, max(case when label = 'CARBOXYHEMOGLOBIN' then valuenum else null end) as CARBOXYHEMOGLOBIN
, max(case when label = 'CHLORIDE' then valuenum else null end) as CHLORIDE
, max(case when label = 'CALCIUM' then valuenum else null end) as CALCIUM
, max(case when label = 'GLUCOSE' then valuenum else null end) as GLUCOSE
, max(case when label = 'HEMATOCRIT' then valuenum else null end) as HEMATOCRIT
, max(case when label = 'HEMOGLOBIN' then valuenum else null end) as HEMOGLOBIN
, max(case when label = 'INTUBATED' then valuenum else null end) as INTUBATED
, max(case when label = 'LACTATE' then valuenum else null end) as LACTATE
, max(case when label = 'METHEMOGLOBIN' then valuenum else null end) as METHEMOGLOBIN
, max(case when label = 'O2FLOW' then valuenum else null end) as O2FLOW
, max(case when label = 'FIO2' then valuenum else null end) as FIO2
, max(case when label = 'SO2' then valuenum else null end) as SO2 -- OXYGENSATURATION
, max(case when label = 'PCO2' then valuenum else null end) as PCO2
, max(case when label = 'PEEP' then valuenum else null end) as PEEP
, max(case when label = 'PH' then valuenum else null end) as PH
, max(case when label = 'PO2' then valuenum else null end) as PO2
, max(case when label = 'POTASSIUM' then valuenum else null end) as POTASSIUM
, max(case when label = 'REQUIREDO2' then valuenum else null end) as REQUIREDO2
, max(case when label = 'SODIUM' then valuenum else null end) as SODIUM
, max(case when label = 'TEMPERATURE' then valuenum else null end) as TEMPERATURE
, max(case when label = 'TIDALVOLUME' then valuenum else null end) as TIDALVOLUME
, max(case when label = 'VENTILATIONRATE' then valuenum else null end) as VENTILATIONRATE
, max(case when label = 'VENTILATOR' then valuenum else null end) as VENTILATOR
from pvt
group by pvt.icustay_id, pvt.CHARTTIME
having max(case when label = 'PO2' then valuenum else null end) is not null
and count(distinct case when label = 'PO2' then valuenum else null end)=1
order by pvt.icustay_id, pvt.CHARTTIME;



DROP TABLE IF EXISTS mpwr_pao2fio2 CASCADE;
create table mpwr_pao2fio2 as
with stg_spo2 as
(
  select ICUSTAY_ID, CHARTTIME
    -- max here is just used to group SpO2 by charttime
    , max(case when valuenum <= 0 or valuenum > 100 then null else valuenum end) as SpO2
  from CHARTEVENTS
  -- o2 sat
  where ITEMID in
  (
    646 -- SpO2
  , 220277 -- O2 saturation pulseoxymetry
  )
  group by ICUSTAY_ID, CHARTTIME
)
, stg_fio2 as
(
  select ICUSTAY_ID, CHARTTIME
    -- pre-process the FiO2s to ensure they are between 21-100%
    , max(
        case
          when itemid = 223835
            then case
              when valuenum > 0 and valuenum <= 1
                then valuenum * 100
              -- improperly input data - looks like O2 flow in litres
              when valuenum > 1 and valuenum < 21
                then null
              when valuenum >= 21 and valuenum <= 100
                then valuenum
              else null end -- unphysiological
        when itemid in (3420, 3422)
        -- all these values are well formatted
            then valuenum
        when itemid = 190 and valuenum > 0.20 and valuenum < 1
        -- well formatted but not in %
            then valuenum * 100
      else null end
    ) as fio2_chartevents
  from CHARTEVENTS
  where ITEMID in
  (
    3420 -- FiO2
  , 190 -- FiO2 set
  , 223835 -- Inspired O2 Fraction (FiO2)
  , 3422 -- FiO2 [measured]
  )
  -- exclude rows marked as error
  and error IS DISTINCT FROM 1
  group by ICUSTAY_ID, CHARTTIME
)
, stg2 as
(
select bg.*
  , ROW_NUMBER() OVER (partition by bg.icustay_id, bg.charttime order by s1.charttime DESC) as lastRowSpO2
  , s1.spo2
from mpwr_oxy_params bg
left join stg_spo2 s1
  -- same patient
  on  bg.icustay_id = s1.icustay_id
  -- spo2 occurred at most 2 hours before this blood gas
  and s1.charttime between bg.charttime - interval '2' hour and bg.charttime
)
, stg3 as
(
select bg.*
  , ROW_NUMBER() OVER (partition by bg.icustay_id, bg.charttime order by s2.charttime DESC) as lastRowFiO2
  , s2.fio2_chartevents

  -- create our specimen prediction
  ,  1/(1+exp(-(-0.02544
  +    0.04598 * po2
  + coalesce(-0.15356 * spo2             , -0.15356 *   97.49420 +    0.13429)
  + coalesce( 0.00621 * fio2_chartevents ,  0.00621 *   51.49550 +   -0.24958)
  + coalesce( 0.10559 * hemoglobin       ,  0.10559 *   10.32307 +    0.05954)
  + coalesce( 0.13251 * so2              ,  0.13251 *   93.66539 +   -0.23172)
  + coalesce(-0.01511 * pco2             , -0.01511 *   42.08866 +   -0.01630)
  + coalesce( 0.01480 * fio2             ,  0.01480 *   63.97836 +   -0.31142)
  + coalesce(-0.00200 * aado2            , -0.00200 *  442.21186 +   -0.01328)
  + coalesce(-0.03220 * bicarbonate      , -0.03220 *   22.96894 +   -0.06535)
  + coalesce( 0.05384 * totalco2         ,  0.05384 *   24.72632 +   -0.01405)
  + coalesce( 0.08202 * lactate          ,  0.08202 *    3.06436 +    0.06038)
  + coalesce( 0.10956 * ph               ,  0.10956 *    7.36233 +   -0.00617)
  + coalesce( 0.00848 * o2flow           ,  0.00848 *    7.59362 +   -0.35803)
  ))) as SPECIMEN_PROB
from stg2 bg
left join stg_fio2 s2
  -- same patient
  on  bg.icustay_id = s2.icustay_id
  -- fio2 occurred at most 4 hours before this blood gas
  and s2.charttime between bg.charttime - interval '4' hour and bg.charttime
where bg.lastRowSpO2 = 1 -- only the row with the most recent SpO2 (if no SpO2 found lastRowSpO2 = 1)
)
select icustay_id, charttime
, SPECIMEN -- raw data indicating sample type, only present 80% of the time

-- prediction of specimen for missing data
, case
      when SPECIMEN is not null then SPECIMEN
      when SPECIMEN_PROB > 0.75 then 'ART'
    else null end as SPECIMEN_PRED
, SPECIMEN_PROB

-- oxygen related parameters
, SO2, spo2 -- note spo2 is from chartevents
, PO2, PCO2
, fio2_chartevents, FIO2
, AADO2
-- also calculate AADO2
, case
    when  PO2 is not null
      and pco2 is not null
      and coalesce(FIO2, fio2_chartevents) is not null
     -- multiple by 100 because FiO2 is in a % but should be a fraction
      then (coalesce(FIO2, fio2_chartevents)/100) * (760 - 47) - (pco2/0.8) - po2
    else null
  end as AADO2_calc
, case
    when PO2 is not null and coalesce(FIO2, fio2_chartevents) is not null
     -- multiply by 100 because FiO2 is in a % but should be a fraction
      then 100*PO2/(coalesce(FIO2, fio2_chartevents))
    else null
  end as PaO2FiO2

-- other
, ph, lactate

-- ventilation stuff that's sometimes input
, INTUBATED, TIDALVOLUME, VENTILATIONRATE, VENTILATOR
, PEEP, O2Flow
, REQUIREDO2

from stg3
-- restrict it to *only* arterial samples
where (SPECIMEN = 'ART' or SPECIMEN_PROB > 0.75)
and lastRowFiO2 = 1 -- only the row with the most recent fio2
order by icustay_id, charttime;



-- add peep_chartevents
DROP TABLE IF EXISTS mpwr_pao2fio2peep CASCADE;
create table mpwr_pao2fio2peep as
with stg_peep as
(
  select ie.icustay_id, ce.charttime
  , max(valuenum) as peep_chartevents
  from icustays ie
  left join chartevents ce
    on ie.icustay_id = ce.icustay_id
    and ce.charttime between (ie.intime - interval '1' day) and (ie.intime + interval '2' day)
    and ce.ITEMID in
    (
      505, -- PEEP
      506, -- PEEP Set
      220339, -- PEEP set
      224700  -- Total PEEP Level
    )
    -- exclude rows marked as error
    and error IS DISTINCT FROM 1
  group by ie.icustay_id, ce.charttime
)
, stg1 as
(
  select bg.icustay_id, bg.charttime
    , bg.SPECIMEN_PRED
    , bg.PaO2FiO2
    , bg.peep
    , s2.peep_chartevents
    , ROW_NUMBER() OVER (partition by bg.icustay_id, bg.charttime order by s2.charttime DESC) as lastRowPeep
  from mpwr_pao2fio2 bg
  left join stg_peep s2
    -- same patient
    on  bg.icustay_id = s2.icustay_id
    -- fio2 occurred at most 4 hours before this blood gas
    and s2.charttime between bg.charttime - interval '4' hour and bg.charttime
)
select icustay_id, charttime
, SPECIMEN_PRED
, PaO2FiO2
, coalesce(PEEP, peep_chartevents) as peep
from stg1
-- restrict it to *only* arterial samples
where lastRowPeep = 1 -- only the row with the most recent fio2
order by icustay_id, charttime;


-- create a table with pH, lactate, and PaCO2
DROP TABLE IF EXISTS mpwr_labs CASCADE;
CREATE TABLE mpwr_labs AS
with l1 as
(
  select
    co.icustay_id
    , min(coalesce(FIO2, fio2_chartevents)) as fio2_min_day1
    , max(coalesce(FIO2, fio2_chartevents)) as fio2_max_day1
    , min(vs.PO2) as pao2_min_day1
    , max(vs.PO2) as pao2_max_day1
    , min(vs.PCO2) as paco2_min_day1
    , max(vs.PCO2) as paco2_max_day1
    , min(vs.ph) as ph_min_day1
    , max(vs.ph) as ph_max_day1
    , min(vs.lactate) as lactate_min_day1
    , max(vs.lactate) as lactate_max_day1
  from mpwr_cohort co
  left join mpwr_pao2fio2 vs
    on co.icustay_id = vs.icustay_id
    and vs.charttime between co.starttime_first_vent and co.starttime_first_vent + interval '1' day
  group by co.icustay_id
)
, l2 as
(
  select
    co.icustay_id
    , min(coalesce(FIO2, fio2_chartevents)) as fio2_min_day2
    , max(coalesce(FIO2, fio2_chartevents)) as fio2_max_day2
    , min(vs.PO2) as pao2_min_day2
    , max(vs.PO2) as pao2_max_day2
    , min(vs.PCO2) as paco2_min_day2
    , max(vs.PCO2) as paco2_max_day2
    , min(vs.ph) as ph_min_day2
    , max(vs.ph) as ph_max_day2
    , min(vs.lactate) as lactate_min_day2
    , max(vs.lactate) as lactate_max_day2
  from mpwr_cohort co
  left join mpwr_pao2fio2 vs
    on co.icustay_id = vs.icustay_id
    and vs.charttime between co.starttime_first_vent + interval '1' day and co.starttime_first_vent + interval '2' day
  group by co.icustay_id
)
select
  co.icustay_id
  , fio2_min_day1
  , fio2_max_day1
  , pao2_min_day1
  , pao2_max_day1
  , paco2_min_day1
  , paco2_max_day1
  , ph_min_day1
  , ph_max_day1
  , lactate_min_day1
  , lactate_max_day1

  , fio2_min_day2
  , fio2_max_day2
  , pao2_min_day2
  , pao2_max_day2
  , paco2_min_day2
  , paco2_max_day2
  , ph_min_day2
  , ph_max_day2
  , lactate_min_day2
  , lactate_max_day2
from mpwr_cohort co
left join l1
  on co.icustay_id = l1.icustay_id
left join l2
  on co.icustay_id = l2.icustay_id
order by co.icustay_id;
