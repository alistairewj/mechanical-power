DROP TABLE IF EXISTS mpwr_comorbid CASCADE;
CREATE TABLE mpwr_comorbid as
select hadm_id
  -- COPD - icd-9 - to be done
  , max(case when cast(icd9_code as char(5)) between '490' and '4928'
         and  cast(icd9_code as char(5)) between '494' and '4941'
        then 1
      else 0 end) as copd
  -- ASTHMA -icd-9 to be done
  , max(case when cast(icd9_code as char(5)) between '49300' and '49392'
        then 1
      else 0 end) as asthma
from diagnoses_icd
group by hadm_id
order by hadm_id;
