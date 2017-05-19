-- This query extracts:
--    i) a patient's first code status
--    ii) a patient's last code status
--    iii) the time of the first entry of DNR or CMO

DROP TABLE IF EXISTS mpwr_code_status CASCADE;
CREATE TABLE mpwr_code_status AS
with t1 as
(
  select icustay_id, charttime, value
  -- use row number to identify first and last code status
  , ROW_NUMBER() over (PARTITION BY icustay_id order by charttime desc) as rnLast

  -- coalesce the values
  , case
      when value in ('Full Code','Full code') then 1
    else 0 end as FullCode
  , case
      when value in ('Comfort Measures','Comfort measures only') then 1
    else 0 end as CMO
  , case
      when value = 'CPR Not Indicate' then 1
    else 0 end as DNCPR -- only in CareVue, i.e. only possible for ~60-70% of patients
  , case
      when value in ('Do Not Intubate','DNI (do not intubate)','DNR / DNI') then 1
    else 0 end as DNI
  , case
      when value in ('Do Not Resuscita','DNR (do not resuscitate)','DNR / DNI') then 1
    else 0 end as DNR
  from chartevents
  where itemid in (128, 223758)
  and value is not null
  and value != 'Other/Remarks'
  -- exclude rows marked as error
  AND error IS DISTINCT FROM 1
)
select ie.subject_id, ie.hadm_id, ie.icustay_id
  -- last recorded code status
  , t1.FullCode as FullCode_last
  , t1.CMO as CMO_last
  , t1.DNR as DNR_last
  , t1.DNI as DNI_last
  , t1.DNCPR as DNCPR_last

from icustays ie
left join t1
  on ie.icustay_id = t1.icustay_id
  and t1.rnLast = 1
order by ie.icustay_id;
