# Import libraries
from __future__ import print_function

import pandas as pd
import psycopg2
import getpass
import argparse

from collections import OrderedDict

# define the queries used to get neuromuscular blocks
queries = {"eicu": """
set search_path to public,eicu_crd;
with has_vent as
(
  select
        distinct p.patientunitstayid
  FROM vent_unpivot_rc p
  -- only include settings before 24 hours
  WHERE p.chartoffset <= 24*60
  AND p.peakpressure IS NOT NULL
)
, pt_in_hosp as
(
  select pt.hospitalid
  , sum(neuroblock_day1) as num_neurblock
  , sum(case when v.patientunitstayid is not null then 1 else 0 end) as num_vent
  , sum(case when v.patientunitstayid is not null and neuroblock_day1 = 1 then 1 else 0 end) as num_vent_and_nb
  , count(pt.patientunitstayid) as num_pat_total
  from patient pt
  inner join mp_neuroblock nb
    on pt.patientunitstayid = nb.patientunitstayid
  left join has_vent v
    on pt.patientunitstayid = v.patientunitstayid
  group by pt.hospitalid
)
, hosp_in_cohort as
(
  select distinct hospitalid
  from mp_cohort
  where exclusion_no_peak_pressure = 0
)
-- define what hospitals we keep:
--  1) at least 10 patients admitted
--  2) have good vent data (defined by hosp_in_cohort)
--  3) at least 3% of patients are on neuromuscular blockade
, hosp_keep as
(
    select
        h.hospitalid
        , ROUND(100.0*num_neurblock::NUMERIC/num_pat_total,2) as percent_nb
    from pt_in_hosp h
    LEFT JOIN hosp_in_cohort co
      ON h.hospitalid = co.hospitalid
    WHERE num_pat_total >= 10
    AND co.hospitalid is not null
    AND ROUND(100.0*num_neurblock::NUMERIC/num_pat_total,2) >= 3
)
select
    d.patientunitstayid
  , d.hospitalid
  , d.neuroblock_day1
  , d.neuroblock_day2
FROM mp_data d
INNER JOIN hosp_keep h
    ON d.hospitalid = h.hospitalid
WHERE patientunitstayid in
(
    select patientunitstayid
    from mp_cohort
    where GREATEST(exclusion_non_adult, exclusion_secondary_hospital_stay, exclusion_secondary_icu_stay, exclusion_by_apache, exclusion_no_rc_data, exclusion_trach, exclusion_not_vent_48hr, exclusion_no_peak_pressure) = 0
)
ORDER BY patientunitstayid
""",
'mimic': """
set search_path to public,mimiciii;
with vw1 as
(
  select co.icustay_id
  , max(CASE WHEN coalesce(nb1.icustay_id, nb2.icustay_id) IS NOT NULL THEN 1 ELSE 0 END) as neuroblock_day1
  from mpwr_cohort co
  LEFT JOIN neuroblock_dose nb1
    ON  nb1.icustay_id = co.icustay_id
    and nb1.starttime >  co.starttime_first_vent - interval '1' hour
    and nb1.starttime <= co.starttime_first_vent + interval '24' hour
  LEFT JOIN neuroblock_dose nb2
    ON  nb2.icustay_id = co.icustay_id
    and nb2.starttime <  co.starttime_first_vent - interval '1' hour
    and nb2.endtime   >= co.starttime_first_vent - interval '1' hour
  GROUP BY co.icustay_id
)
-- day 2
, vw2 as
(
  select co.icustay_id
  , max(CASE WHEN coalesce(nb1.icustay_id, nb2.icustay_id) IS NOT NULL THEN 1 ELSE 0 END) as neuroblock_day2
  from mpwr_cohort co
  LEFT JOIN neuroblock_dose nb1
    ON  nb1.icustay_id = co.icustay_id
    and nb1.starttime >  co.starttime_first_vent + interval '24' hour
    and nb1.starttime <= co.starttime_first_vent + interval '48' hour
  LEFT JOIN neuroblock_dose nb2
    ON  nb2.icustay_id = co.icustay_id
    and nb2.starttime <  co.starttime_first_vent + interval '24' hour
    and nb2.endtime   >= co.starttime_first_vent + interval '24' hour
  GROUP BY co.icustay_id
)
-- data has exclusions applied
select
      d.icustay_id
    , neuroblock_day1
    , neuroblock_day2
from mpwr_data d
LEFT JOIN vw1
  on d.icustay_id = vw1.icustay_id
LEFT JOIN vw2
  on d.icustay_id = vw2.icustay_id
"""
}

parser = argparse.ArgumentParser(description='Add year to a dataset')
parser.add_argument('data', default='mimic',
                    help='filename of data that needs to have year')

args = parser.parse_args()

if args.data in ('mimic', 'data_mimic', 'data_mimic.csv'):
    join_id = 'icustay_id'
    dbname = 'mimic'
    fn = '../data/pin_mimic.csv'
    fn_out = '../data/mimic_neuroblock.csv'
    query = queries['mimic']

elif args.data in ('eicu', 'pin_eicu', 'pin_eicu.csv', 'data_eicu', 'data_eicu.csv'):
    join_id = 'patientunitstayid'
    dbname = 'eicu'
    fn = '../data/pin_eicu.csv'
    fn_out = '../data/eicu_neuroblock.csv'
    query = queries['eicu']

# Connect to local postgres version of mimic
sqluser = getpass.getuser()
con = psycopg2.connect(dbname=dbname, user=sqluser)
print('Connected to postgres {}.{}.{}!'.format(int(con.server_version/10000),
                                              int((con.server_version - int(con.server_version/10000)*10000)/100),
                                              int(con.server_version - int(con.server_version/100)*100)))

df = pd.read_csv(fn, header=0)
nb = pd.read_sql_query(query, con)

print('{} patients in original cohort.'.format(df.shape[0]))

df = df.merge(nb, how='inner', on=join_id)
for c in df.columns:
    if c[-3:] == '_nb':
        df.drop(c, axis=1, inplace=True)

print('{} patients kept after exclusions.'.format(df.shape[0]))
print('{} patients have neuroblock on day1.'.format(df['neuroblock_day1'].sum()))
print('{} patients have neuroblock on day2.'.format(df['neuroblock_day2'].sum()))
df.to_csv(fn_out, index=False)
