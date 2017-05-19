-- final query for all the data


select
  co.icustay_id

  , sa.sapsii, oa.oasis, so.sofa
from mpwr_cohort co
left join sapsii sa
  on co.icustay_id = sa.icustay_id
left join oasis oa
  on co.icustay_id = oa.icustay_id
left join sofa so
  on co.icustay_id = so.icustay_id
