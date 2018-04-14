-- This query brings together data from the following materialized views:
--  1.  - cohort.sql
--  2.  - demographics.sql
--  3.  - labs.sql
--  4.  - meds.sql
--  5.  - vitals.sql
--  5.  - diagnosis.sql

DROP TABLE IF EXISTS public.mp_data;
CREATE TABLE public.mp_data AS
select
  pt.PATIENTUNITSTAYID
  , pt.hospitalid

  -- outcomes
  , de.icu_los
  , de.hospital_los
  , de.icu_mortality
  , de.hospital_mortality -- binary, 1 or 0
  , apv.diedinhospital as hospital_mortality_ultimate

  -- **************************** --
  -- ******* DEMOGRAPHICS ******* --
  -- **************************** --
  -- patient features
  , de.gender
  , de.age
  , de.ethnicity

  , de.admissionheight -- height in cm
  , de.admissionweight -- weight in kg
  , wt.weight as chartedweight -- weight in kg

  -- source of admission
  , de.hospital_admit_source
  , de.icu_admit_source
  , de.icu_disch_location
  , de.hospital_disch_location

  -- patient hospital stay features
  -- hospital length of stay in days
  , hp.numbedscategory as hospital_size
  , cast(NULL as VARCHAR(10)) as hospital_type
  , hp.teachingstatus as hospital_teaching_status
  , hp.region as hospital_region
  , pt.hospitaldischargeyear


  -- APACHE covariates for discharge location, etc
  , apv.admitsource as apache_admit_source
  , apv.dischargelocation as apache_disch_location

  -- APACHE IVa
  , de.apacheiva
  , de.apacheiva_pred
  , pt.apacheadmissiondx
  , apv.electivesurgery

  -- apache comorbidities
  , aav.dialysis
  , de.aids
  , de.hepaticfailure
  , de.cirrhosis
  , de.diabetes
  , de.immunosuppression
  , de.leukemia
  , de.lymphoma
  , de.metastaticcancer

  -- *********************** --
  -- *** APACHE PRED VAR *** --
  -- *********************** --

  -- Mechanical ventilation start and stop times are interfaced into
  -- or documented directly into the respiratory flow sheet
  -- or by updating the care plan in eCareManager.
  -- however, we decided not to use flow sheet, but to use APACHE vent variable.

  , aav.intubated as intubated_apache
  , apv.oobIntubDay1 as oobIntubDay1_apache
  , apv.oobVentDay1 as oobVentDay1_apache
  , apv.VENTDAY1 as VentDay1_apache


  -- ********************* --
  -- ******* OTHER ******* --
  -- ********************* --

  , rf.ARDS
  , rf.respfailure
  , rf.copd
  -- Smoking status
  -- Other scores - OASIS? SOFA? SAPS II?
  , sf.sofa_cardiovascular
  , sf.sofa_renal
  , sf.sofa_cns
  , sf.sofa_coagulation
  , sf.sofa_liver
  , sf.sofa_respiration
  , sf.sofa
  -- RRT anytime
  -- code status

  -- from table 8 charlson
  , ch.mets6
  , ch.aids6
  , ch.liver3
  , ch.stroke2
  , ch.renal2
  , ch.dm
  , ch.cancer2
  , ch.leukemia2
  , ch.lymphoma2
  , ch.mi1
  , ch.chf1
  , ch.pvd1
  , ch.tia1
  , ch.dementia1
  , ch.copd1
  , ch.ctd1
  , ch.pud1
  , ch.liver1
  -- ********************** --
  -- ******* VITALS ******* --
  -- ********************** --

  , vi.heartrate_min_day1
  , vi.heartrate_max_day1
  , vi.map_min_day1
  , vi.map_max_day1
  , vi.temperature_min_day1
  , vi.temperature_max_day1
  , vi.spo2_min_day1
  , vi.spo2_max_day1

  , vi.heartrate_min_day2
  , vi.heartrate_max_day2
  , vi.map_min_day2
  , vi.map_max_day2
  , vi.temperature_min_day2
  , vi.temperature_max_day2
  , vi.spo2_min_day2
  , vi.spo2_max_day2

  -- ***************************** --
  -- ******** BLOOD GASES ******** --
  -- ***************************** --
  , bg.PaO2_min_day1
  , bg.PaO2_max_day1
  , bg.PaCO2_min_day1
  , bg.PaCO2_max_day1
  , bg.ph_min_day1
  , bg.ph_max_day1
  , bg.PaO2FiO2_min_day1
  , bg.PaO2FiO2_max_day1

  , bg.PaO2_min_day2
  , bg.PaO2_max_day2
  , bg.PaCO2_min_day2
  , bg.PaCO2_max_day2
  , bg.ph_min_day2
  , bg.ph_max_day2
  , bg.PaO2FiO2_min_day2
  , bg.PaO2FiO2_max_day2

  -- *************************** --
  -- ******** MEDICATIONS ******** --
  -- *************************** --

  -- Binary flags indicating existence of any non-zero dose
  , med.dopamine_day1
  , med.dobutamine_day1
  , med.epinephrine_day1
  , med.norepinephrine_day1
  , med.phenylephrine_day1
  , med.vasopressin_day1
  , med.milrinone_day1
  , GREATEST(med.dopamine_day1
    , med.dobutamine_day1
    , med.epinephrine_day1
    , med.norepinephrine_day1
    , med.phenylephrine_day1
    , med.vasopressin_day1
    , med.milrinone_day1) as vasopressor_day1

  -- VENT DATA
  , v.meanairwaypressure_min_day1
  , v.peakpressure_min_day1
  , v.peakflow_min_day1
  , v.plateaupressure_min_day1
  , v.pressuresupportpressure_min_day1
  , v.pressurecontrolpressure_min_day1
  , v.rsbi_min_day1
  , v.peep_min_day1
  , v.tidalvolumeobserved_min_day1
  , v.tidalvolumeset_min_day1
  , v.tidalvolumespontaneous_min_day1
  , v.meanairwaypressure_max_day1
  , v.peakpressure_max_day1
  , v.peakflow_max_day1
  , v.plateaupressure_max_day1
  , v.pressuresupportpressure_max_day1
  , v.pressurecontrolpressure_max_day1
  , v.rsbi_max_day1
  , v.peep_max_day1
  , v.tidalvolumeobserved_max_day1
  , v.tidalvolumeset_max_day1
  , v.tidalvolumespontaneous_max_day1
  , v.fio2_min_day1
  , v.fio2_max_day1
  , v.respiratoryrate_min_day1
  , v.respiratoryrate_max_day1
  , v.respiratoryrateset_min_day1
  , v.respiratoryrateset_max_day1
  , v.respiratoryratespontaneous_min_day1
  , v.respiratoryratespontaneous_max_day1

  , v.meanairwaypressure_min_day2
  , v.peakpressure_min_day2
  , v.peakflow_min_day2
  , v.plateaupressure_min_day2
  , v.pressuresupportpressure_min_day2
  , v.pressurecontrolpressure_min_day2
  , v.rsbi_min_day2
  , v.peep_min_day2
  , v.tidalvolumeobserved_min_day2
  , v.tidalvolumeset_min_day2
  , v.tidalvolumespontaneous_min_day2
  , v.meanairwaypressure_max_day2
  , v.peakpressure_max_day2
  , v.peakflow_max_day2
  , v.plateaupressure_max_day2
  , v.pressuresupportpressure_max_day2
  , v.pressurecontrolpressure_max_day2
  , v.rsbi_max_day2
  , v.peep_max_day2
  , v.tidalvolumeobserved_max_day2
  , v.tidalvolumeset_max_day2
  , v.tidalvolumespontaneous_max_day2
  , v.fio2_min_day2
  , v.fio2_max_day2
  , v.respiratoryrate_min_day2
  , v.respiratoryrate_max_day2
  , v.respiratoryrateset_min_day2
  , v.respiratoryrateset_max_day2
  , v.respiratoryratespontaneous_min_day2
  , v.respiratoryratespontaneous_max_day2

from patient pt
-- Sub-select to cohort - this filters patients using our inclusion criteria
inner join mp_cohort co
  on pt.patientunitstayid = co.patientunitstayid
left join hospital hp
  on pt.hospitalid = hp.hospitalid
left join apachepredvar apv
  on pt.patientunitstayid = apv.patientunitstayid
left join apacheapsvar aav
  on pt.patientunitstayid = aav.patientunitstayid
left join apachepatientresult apr
  on pt.patientunitstayid = apr.patientunitstayid
  and apr.apacheversion = 'IVa'
left join mp_demographics de
  on pt.patientunitstayid = de.patientunitstayid
left join mp_vitals vi
  on pt.patientunitstayid = vi.patientunitstayid
left join mp_bg bg
  on pt.patientunitstayid = bg.patientunitstayid
-- left join rs_diagnosis dx
--   on pt.patientunitstayid = dx.patientunitstayid
left join mp_meds med
  on pt.patientunitstayid = med.patientunitstayid
left join mp_vent v
  on pt.patientunitstayid = v.patientunitstayid
left join mp_weight wt
  on pt.patientunitstayid = wt.patientunitstayid
left join mp_sofa sf
  on pt.patientunitstayid = sf.patientunitstayid
left join mp_respfailure rf
  on pt.patientunitstayid = rf.patientunitstayid
left join mp_charlson ch
  on pt.patientunitstayid = ch.patientunitstayid;
