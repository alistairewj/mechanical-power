drop table if exists mpwr_vasopressors cascade;
create table mpwr_vasopressors as
SELECT
  ie.icustay_id
  , min(vd.starttime) as starttime

FROM icustays ie
left join vasopressordurations vd
  on ie.icustay_id = vd.icustay_id
  and vd.starttime >= ie.intime - interval '1' day
  and vd.starttime <= ie.intime + interval '1' day
group by ie.icustay_id
order by ie.icustay_id;
