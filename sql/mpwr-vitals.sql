DROP TABLE IF EXISTS mpwr_vitals cascade;
CREATE TABLE mpwr_vitals as

with pvt as
(
  select co.icustay_id
  , case
    when itemid in (211,220045) and valuenum > 0 and valuenum < 300 then 'HR' -- HeartRate
    when itemid in (456,52,6702,443,220052,220181,225312) and valuenum > 0 and valuenum < 300 then 'MeanBP' -- MeanBP
    when itemid in (223761,678) and valuenum > 70 and valuenum < 120  then 'Temp' -- TempF, converted to degC in valuenum call
    when itemid in (223762,676) and valuenum > 10 and valuenum < 50  then 'Temp' -- TempC
    when itemid in (646,220277) and valuenum > 0 and valuenum <= 100 then 'SpO2' -- SpO2
    when itemid in (1337, 223753) and value is not null then 'RASS'
    when itemid in (1817, 228640) and valuenum > 0 then 'EtCO2' -- end tidal co2
  else null end as vital

  , case
      -- convert F to C
      when itemid in (223761,678) then (valuenum-32)/1.8
      -- map rass to numbers
      when itemid = 1337 and value is not null then
        case when value = 'Agitated' then 5
             when value = 'Calm/Cooperative' then 4
             when value = 'Danger Agitation' then 7
             when value = 'Sedated' then 3
             when value = 'Unarousable' then 1
             when value = 'Very Agitated' then 6
             when value = 'Very Sedated'  then 2
          else null
        end
    else valuenum end
  as valuenum

  -- used to split data into day 1 and day 2
  , case when ce.charttime < co.starttime_first_vent + interval '1' day then 1 else 0 end as firstday

  from mpwr_cohort co
  left join chartevents ce
    on co.icustay_id = ce.icustay_id
    and ce.charttime between co.starttime_first_vent and co.starttime_first_vent + interval '2' day
    -- exclude rows marked as error
    and ce.error IS DISTINCT FROM 1
    and ce.itemid in
    (
    -- HEART RATE
    211, --"Heart Rate"
    220045, --"Heart Rate"

    -- MEAN ARTERIAL PRESSURE
    456, --"NBP Mean"
    52, --"Arterial BP Mean"
    6702, --	Arterial BP Mean #2
    443, --	Manual BP Mean(calc)
    220052, --"Arterial Blood Pressure mean"
    220181, --"Non Invasive Blood Pressure mean"
    225312, --"ART BP mean"

    -- SPO2, peripheral
    646, 220277,

    -- end tidal co2 (etco2)
    1817, 228640,

    -- RASS (richmond agitation sedation scale, though mislabeled as riker)
    1337, 223753,

    -- TEMPERATURE
    223762, -- "Temperature Celsius"
    676,	-- "Temperature C"
    223761, -- "Temperature Fahrenheit"
    678 --	"Temperature F"
    )
)
-- first day
, vd1 as
(
  SELECT pvt.icustay_id
  -- Easier names
  , min(case when vital = 'HR' then valuenum else null end) as HeartRate_Min
  , max(case when vital = 'HR' then valuenum else null end) as HeartRate_Max
  , avg(case when vital = 'HR' then valuenum else null end) as HeartRate_Mean
  , min(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Min
  , max(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Max
  , avg(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Mean
  , min(case when vital = 'Temp' then valuenum else null end) as TempC_Min
  , max(case when vital = 'Temp' then valuenum else null end) as TempC_Max
  , avg(case when vital = 'Temp' then valuenum else null end) as TempC_Mean
  , min(case when vital = 'SpO2' then valuenum else null end) as SpO2_Min
  , max(case when vital = 'SpO2' then valuenum else null end) as SpO2_Max
  , avg(case when vital = 'SpO2' then valuenum else null end) as SpO2_Mean
  , min(case when vital = 'RASS' then valuenum else null end) as RASS_Min
  , max(case when vital = 'RASS' then valuenum else null end) as RASS_Max
  , avg(case when vital = 'RASS' then valuenum else null end) as RASS_Mean
  , min(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Min
  , max(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Max
  , avg(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Mean
  FROM  pvt
  where pvt.firstday = 1
  group by pvt.icustay_id
)
-- second day
, vd2 as
(
  SELECT pvt.icustay_id
  -- Easier names
  , min(case when vital = 'HR' then valuenum else null end) as HeartRate_Min
  , max(case when vital = 'HR' then valuenum else null end) as HeartRate_Max
  , avg(case when vital = 'HR' then valuenum else null end) as HeartRate_Mean
  , min(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Min
  , max(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Max
  , avg(case when vital = 'MeanBP' then valuenum else null end) as MeanBP_Mean
  , min(case when vital = 'Temp' then valuenum else null end) as TempC_Min
  , max(case when vital = 'Temp' then valuenum else null end) as TempC_Max
  , avg(case when vital = 'Temp' then valuenum else null end) as TempC_Mean
  , min(case when vital = 'SpO2' then valuenum else null end) as SpO2_Min
  , max(case when vital = 'SpO2' then valuenum else null end) as SpO2_Max
  , avg(case when vital = 'SpO2' then valuenum else null end) as SpO2_Mean
  , min(case when vital = 'RASS' then valuenum else null end) as RASS_Min
  , max(case when vital = 'RASS' then valuenum else null end) as RASS_Max
  , avg(case when vital = 'RASS' then valuenum else null end) as RASS_Mean
  , min(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Min
  , max(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Max
  , avg(case when vital = 'EtCO2' then valuenum else null end) as EtCO2_Mean
  FROM  pvt
  where pvt.firstday = 0
  group by pvt.icustay_id
)
select
    co.icustay_id
  , vd1.HeartRate_Min as HeartRate_Min_day1
  , vd1.HeartRate_Max as HeartRate_Max_day1
  , vd1.HeartRate_Mean as HeartRate_Mean_day1
  , vd1.MeanBP_Min as MeanBP_Min_day1
  , vd1.MeanBP_Max as MeanBP_Max_day1
  , vd1.MeanBP_Mean as MeanBP_Mean_day1
  , vd1.TempC_Min as TempC_Min_day1
  , vd1.TempC_Max as TempC_Max_day1
  , vd1.TempC_Mean as TempC_Mean_day1
  , vd1.SpO2_Min as SpO2_Min_day1
  , vd1.SpO2_Max as SpO2_Max_day1
  , vd1.SpO2_Mean as SpO2_Mean_day1
  , vd1.RASS_Min as RASS_Min_day1
  , vd1.RASS_Max as RASS_Max_day1
  , vd1.RASS_Mean as RASS_Mean_day1
  , vd1.EtCO2_Min as EtCO2_Min_day1
  , vd1.EtCO2_Max as EtCO2_Max_day1
  , vd1.EtCO2_Mean as EtCO2_Mean_day1

  , vd2.HeartRate_Min as HeartRate_Min_day2
  , vd2.HeartRate_Max as HeartRate_Max_day2
  , vd2.HeartRate_Mean as HeartRate_Mean_day2
  , vd2.MeanBP_Min as MeanBP_Min_day2
  , vd2.MeanBP_Max as MeanBP_Max_day2
  , vd2.MeanBP_Mean as MeanBP_Mean_day2
  , vd2.TempC_Min as TempC_Min_day2
  , vd2.TempC_Max as TempC_Max_day2
  , vd2.TempC_Mean as TempC_Mean_day2
  , vd2.SpO2_Min as SpO2_Min_day2
  , vd2.SpO2_Max as SpO2_Max_day2
  , vd2.SpO2_Mean as SpO2_Mean_day2
  , vd2.RASS_Min as RASS_Min_day2
  , vd2.RASS_Max as RASS_Max_day2
  , vd2.RASS_Mean as RASS_Mean_day2
  , vd2.EtCO2_Min as EtCO2_Min_day2
  , vd2.EtCO2_Max as EtCO2_Max_day2
  , vd2.EtCO2_Mean as EtCO2_Mean_day2
from mpwr_cohort co
left join vd1
  on co.icustay_id = vd1.icustay_id
left join vd2
  on co.icustay_id = vd2.icustay_id
order by ie.icustay_id;
