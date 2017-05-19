-- Extract only ventilation related ITEMIDs
-- This creates a "mini" chartevents, with only the vent settings
-- Speeds up subsequent queries using the data

-- This query extracts the duration of mechanical ventilation
DROP TABLE IF EXISTS mpwr_chartevents_vent cascade;
CREATE TABLE mpwr_chartevents_vent as
select
  icustay_id, charttime
  , itemid
  , value, valuenum, valueuom
  , storetime
from chartevents ce
where ce.value is not null
-- exclude rows marked as error
and ce.error IS DISTINCT FROM 1
and itemid in
(
    -- the below are settings used to indicate ventilation
      720, 223849 -- vent mode
    , 223848 -- vent type
    , 445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
    , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
    , 218,436,535,444,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean ("RespPressure")
    , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
    , 543 -- PlateauPressure
    , 5865,5866,224707,224709,224705,224706 -- APRV pressure
    , 60,437,505,506,686,220339,224700 -- PEEP
    , 3459 -- high pressure relief
    , 501,502,503,224702 -- PCV
    , 223,667,668,669,670,671,672 -- TCPCV
    , 224701 -- PSVlevel

    , 619 -- Respiratory Rate Set
    , 224688 -- Respiratory Rate (Set)
    , 615 --  Resp Rate (Total)
    , 224690 -- Respiratory Rate (Total)
    , 618 --  Respiratory Rate
    , 220210 -- Respiratory Rate

    -- the below are settings used to indicate extubation
    , 640 -- extubated

    -- the below indicate oxygen/NIV, i.e. the end of a mechanical vent event
    , 468 -- O2 Delivery Device#2
    , 469 -- O2 Delivery Mode
    , 470 -- O2 Flow (lpm)
    , 471 -- O2 Flow (lpm) #2
    , 227287 -- O2 Flow (additional cannula)
    , 226732 -- O2 Delivery Device(s)
    , 223834 -- O2 Flow

    -- used in both oxygen + vent calculation
    , 467 -- O2 Delivery Device
);
