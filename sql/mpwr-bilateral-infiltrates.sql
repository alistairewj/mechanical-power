-- identifying bilateral opacities
-- we parse the free-text radiology reports for mention of opacities/infiltrates
-- this is needed for the definition of ARDS

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
