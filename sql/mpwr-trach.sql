DROP TABLE IF EXISTS mpwr_trach CASCADE;
CREATE TABLE mpwr_trach AS
select a.icustay_id, min(ce.charttime) as charttime
, max(case when ce.icustay_id is not null then 1 else 0 end) as trach
from mimiciii.icustays a
left join mimiciii.chartevents ce
  on ce.icustay_id = a.icustay_id
  and ce.charttime between a.intime and a.intime + interval '3' day
  and ce.itemid in (687,688,690,691,692,224831,224829,224830,224864,225590,227130)
  and coalesce(error,0)=0
  and value is not null
group by a.icustay_id
order by a.icustay_id;
