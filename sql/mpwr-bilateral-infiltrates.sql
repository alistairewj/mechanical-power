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
DROP TABLE IF EXISTS notes_bilateral_infiltrates CASCADE;
CREATE TABLE notes_bilateral_infiltrates AS
with notes as
(
select hadm_id, charttime, text, regexp_replace(regexp_replace(text,'\n',' '),'\r', '') as text_fix
from noteevents
where category = 'Radiology'
and description ilike '%chest%'
)
select hadm_id, charttime, 1::smallint as bilateral_infiltrates
--, substring(text from position('bilateral' in lower(text)) for 30) p
from notes
where text_fix ~ 'bilateral (\w)* ?(\w)* ?(opaci|infil|haziness)'
OR text_fix ~* '\.?([\w ]*)^(no )(opaci|infil|hazy|haziness)([\w ]+)bilaterally'
order by hadm_id, charttime;

-- create ARDS TABLE
DROP TABLE IF EXISTS ards CASCADE;
CREATE TABLE ards AS
select
  ie.icustay_id
  , case
      when tr.trach = 0 -- must be acute
       and bi.bilateral_infiltrates = 1 -- require bilateral infiltrates
       and bo.bad_oxygenation = 1  -- low pao2/fio2
      then 1
    else 0 end as ards
  -- staging
  , case
      when tr.trach = 0 -- must be acute
       and bi.bilateral_infiltrates = 1 -- require bilateral infiltrates
      then bo.ards_stage
    else null end as ards_stage
from icustays ie
left join mpwr_trach tr
  on ie.icustay_id = tr.icustay_id

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
