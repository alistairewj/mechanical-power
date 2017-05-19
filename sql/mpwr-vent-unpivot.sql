


-- This query extracts the duration of mechanical ventilation
DROP TABLE IF EXISTS mpwr_vent_unpivot cascade;
CREATE TABLE mpwr_vent_unpivot as
select
  icustay_id, charttime
  -- case statement determining whether it is an instance of mech vent

  -- , max(case when itemid in (445, 448, 449, 450, 1340, 1486, 1600, 224687) then valuenum else null end) as minute_volume -- minute volume
  , max(case when itemid in (639, 654, 681, 682, 683, 684,224685,224684,224686) then valuenum else null end) as tidal_volume -- tidal volume
  -- , max(case when itemid in (218,436,535,444,459,224697,224695,224746,224747) then valuenum else null end) as pressure_misc -- High/Low/Peak/Mean/Neg insp force ("RespPressure")
  -- , max(case when itemid in (221,1,1211,1655,2000,226873,224738,224419,224750,227187) then valuenum else null end) as insp_pressure -- Insp pressure
  , max(case when itemid in (543,224696) then valuenum else null end) as plateau_pressure -- PlateauPressure
  -- , max(case when itemid in (5865,5866,224707,224709,224705,224706) then valuenum else null end) as aprv_pressure -- APRV pressure
  , max(case when itemid in (60,437,505,506,686,220339,224700) then valuenum else null end) as peep -- PEEP
  -- , max(case when itemid in (3459) then valuenum else null end) as high_pressure_relief -- high pressure relief
  -- , max(case when itemid in (501,502,503,224702) then valuenum else null end) as pcv -- PCV
  -- , max(case when itemid in (223,667,668,669,670,671,672) then valuenum else null end) as tcpcv -- TCPCV
  -- , max(case when itemid in (224701) then valuenum else null end) as psv_level -- PSVlevel

  , max(case when itemid in (535, 224695) then valuenum else null end) as peak_insp_pressure

  , max(case when itemid in (619, 224688) then valuenum else null end) as resp_rate_set
  , max(case when itemid in (615, 618, 224690, 220210) then valuenum else null end) as resp_rate_total

  --
  -- , max(
  --   case
  --     when itemid is null or value is null then 0 -- can't have null values
  --     when itemid = 720 and value != 'Other/Remarks' THEN 1  -- VentTypeRecorded
  --     when itemid = 223848 and value != 'Other' THEN 1
  --     when itemid = 223849 then 1 -- ventilator mode
  --     when itemid = 467 and value = 'Ventilator' THEN 1 -- O2 delivery device == ventilator
  --     when itemid in
  --       (
  --       445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
  --       , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
  --       , 218,436,535,444,459,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean/Neg insp force ("RespPressure")
  --       , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
  --       , 543 -- PlateauPressure
  --       , 5865,5866,224707,224709,224705,224706 -- APRV pressure
  --       , 60,437,505,506,686,220339,224700 -- PEEP
  --       , 3459 -- high pressure relief
  --       , 501,502,503,224702 -- PCV
  --       , 223,667,668,669,670,671,672 -- TCPCV
  --       -- ETT information alone are insufficient to deem patient as ventilated
  --       -- , 8382, 157 , 158,1852,3398,3399,3400,3401,3402,3403,3404,227809,227810 -- ETT
  --       , 224701 -- PSVlevel
  --       )
  --       THEN 1
  --     else 0
  --   end
  --   ) as MechVent
  --
  --   , max(
  --     case
  --       -- initiation of oxygen therapy indicates the ventilation has ended
  --       when itemid = 226732 and value in
  --       (
  --         'Nasal cannula', -- 153714 observations
  --         'Face tent', -- 24601 observations
  --         'Aerosol-cool', -- 24560 observations
  --         'Trach mask ', -- 16435 observations
  --         'High flow neb', -- 10785 observations
  --         'Non-rebreather', -- 5182 observations
  --         'Venti mask ', -- 1947 observations
  --         'Medium conc mask ', -- 1888 observations
  --         'T-piece', -- 1135 observations
  --         'High flow nasal cannula', -- 925 observations
  --         'Ultrasonic neb', -- 9 observations
  --         'Vapomist' -- 3 observations
  --       ) then 1
  --       when itemid = 467 and value in
  --       (
  --         'Cannula', -- 278252 observations
  --         'Nasal Cannula', -- 248299 observations
  --         'None', -- 95498 observations
  --         'Face Tent', -- 35766 observations
  --         'Aerosol-Cool', -- 33919 observations
  --         'Trach Mask', -- 32655 observations
  --         'Hi Flow Neb', -- 14070 observations
  --         'Non-Rebreather', -- 10856 observations
  --         'Venti Mask', -- 4279 observations
  --         'Medium Conc Mask', -- 2114 observations
  --         'Vapotherm', -- 1655 observations
  --         'T-Piece', -- 779 observations
  --         'Hood', -- 670 observations
  --         'Hut', -- 150 observations
  --         'TranstrachealCat', -- 78 observations
  --         'Heated Neb', -- 37 observations
  --         'Ultrasonic Neb' -- 2 observations
  --       ) then 1
  --     else 0
  --     end
  --   ) as OxygenTherapy
    , max(
      case when itemid is null or value is null then 0
        -- extubated indicates ventilation event has ended
        when itemid = 640 and value = 'Extubated' then 1
        when itemid = 640 and value = 'Self Extubation' then 1
      else 0
      end
      )
      as Extubated
    -- , max(
    --   case when itemid is null or value is null then 0
    --     when itemid = 640 and value = 'Self Extubation' then 1
    --   else 0
    --   end
    --   )
    --   as SelfExtubated
from mpwr_chartevents_vent ce
group by icustay_id, charttime;
