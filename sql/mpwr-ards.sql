-- identifying ARDS in MIMIC-III patients
-- we follow the berlin definition:
--    1) onset of ARDS is acute - we assume this as our cohort is only recently mechanically ventilated patients (i.e. we exclude trach)
--    2) bilateral opacities - we parse the free-text radiology reports for mention of opacities/infiltrates
--    3) peep > 5 - we finally classify ARDS based off pao2/fio2 ratio
--              pao2/fio2 > 300 - None
--        300 > pao2/fio2 > 200 - Mild
--        200 > pao2/fio2 > 100 - Moderate
--        100 > pao2/fio2       - Severe
-- (TODO: figure out the exact >= or > rules)


-- look for reports with bilateral
select hadm_id, charttime, text, substring(text from position('bilateral' in lower(text)) for 30) p
from noteevents
where category = 'Radiology'
and lower(description) like '%chest%'
and lower(text) like '%bilateral opac%' limit 10;


-- look for reports with bilateral
select hadm_id, charttime, text, substring(text from position('bilaterally' in lower(text))-20 for 32) p
from noteevents
where category = 'Radiology'
and lower(description) like '%chest%'
and lower(text like '%air%infi%bilaterally%' limit 10;




-- group sentences containing bilateral
with t1 as
(
select regexp_replace(regexp_replace(case when position('bilateral' in lower(text)) > 20 then
    substring(text from position('bilateral' in lower(text))-20 for 50)
    else substring(text from 1 for 50) end,'\n',' '),'\r','') as sent
from noteevents
where category = 'Radiology'
and lower(description) like '%chest%'
and lower(text) like '%bilateral%'
)
select sent, count(*) as numobs
from t1
group by sent
order by numobs desc;

-- group sentences containing pulmonary infilt
with t1 as
(
select lower(regexp_replace(regexp_replace(case when position('pulmonary infiltrate' in lower(text)) > 20 then
    substring(text from position('pulmonary infiltrate' in lower(text))-20 for 40)
    else substring(text from 1 for 20) end,'\n',' '),'\r','')) as sent
from noteevents
where category = 'Radiology'
and lower(description) like '%chest%'
and lower(text) like '%pulmonary infiltrate%'
)
select sent, count(*) as numobs
from t1
group by sent
order by numobs desc;




-- group sentences bilaterally
with t1 as
(
select lower(regexp_replace(regexp_replace(case when position('bilaterally' in lower(text)) > 20 then
    substring(text from position('bilaterally' in lower(text))-20 for 20+11)
    else substring(text from 1 for 20+11) end,'\n',' '),'\r','')) as sent
from noteevents
where category = 'Radiology'
and lower(description) like '%chest%'
and lower(text) like '%bilaterally%'
)
select sent, count(*) as numobs
from t1
group by sent
order by numobs desc;



--
-- ?bilateral interstitial pattern
-- ?bilateral interstitial and alv
-- ?bilateral diffuse interstitial
-- ?bilateral pulmonary vascular c
-- ?bilateral interstitial opacit
-- ?bilateral interstitial pulmona
--
-- ?bilaterally
-- ?bilateral interstitial infiltr
-- ?bilateral pulmonary parenchyma
--
-- -- bilaterally
-- erstitial opacities bilaterally
-- airspace opacities bilaterally
-- alveolar opacities bilaterally
-- renchymal opacities bilaterally
--
--
-- -- list of "unique" ways of saying bilateral infiltrates
-- bilateral air space opacities
-- bilateral airspace opacities
-- bilateral alveolar opacities
-- bilateral alveolar infiltrates
-- bilateral pulmonary opacificat
-- bilateral pulmonary opacities
-- bilateral pulmonary infiltrate
-- bilateral parenchymal opacitie
-- bilateral perihilar opacities
-- bilateral perihilar haziness a
-- bilateral lower lobe opacities
-- bilateral ground-glass opacifi
-- bilateral alveolar and interst
