-- TABLES NEEDED FOR THIS SCRIPT TO WORK:
--  heightweight
--  ventdurations
--  vasopressordurations
--  elixhauser_ahrq_score

-- need trach data for cohort
\i mpwr-trach.sql

-- create cohort
\i mpwr-cohort.sql

-- demographics
\i mpwr-smoker.sql
\i mpwr-demographics.sql

-- settings (takes a while)
\i mpwr-vent-settings.sql
\i mpwr-vent-unpivot.sql
\i mpwr-vent-mech-power.sql

-- ARDS
\i mpwr-bilateral-infiltrates.sql
\i mpwr-pao2fio2.sql
\i mpwr-ards.sql

-- other
\i mpwr-code-status.sql
\i mpwr-comorbid.sql
\i mpwr-vasopressors.sql
\i mpwr-vitals.sql


-- finally, create the data
\i mpwr-data.sql
