-- code status in first 48 hours
DROP TABLE IF EXISTS mp_codestatus CASCADE;
CREATE TABLE mp_codestatus AS
select
  pt.patientunitstayid
  , MAX(CASE
    WHEN cplitemvalue = 'Do not resuscitate'        THEN 1 --  27058
    WHEN cplitemvalue = 'Advance directives'        THEN 1 --     90
    WHEN cplitemvalue = 'No cardioversion'          THEN 1 --   2915
    WHEN cplitemvalue = 'No CPR'                    THEN 1 --   5960
    WHEN cplitemvalue = 'No intubation'             THEN 1 --   6179
    WHEN cplitemvalue = 'No vasopressors/inotropes' THEN 1 --   1348
    WHEN cplitemvalue IS NOT NULL THEN 0
    ELSE NULL
  END) AS DNR
  , MAX(CASE
    WHEN cplitemvalue = 'Comfort measures only'     THEN 1 --   4418
    WHEN cplitemvalue = 'No augmentation of care'   THEN 1 --   1468
    WHEN cplitemvalue = 'No blood draws'            THEN 1 --    117
    WHEN cplitemvalue = 'No blood products'         THEN 1 --    208
    WHEN cplitemvalue IS NOT NULL THEN 0
    ELSE NULL
  END) AS CMO
  , MAX(CASE
    WHEN cplitemvalue = 'Full therapy'              THEN 1 -- 172656
    WHEN cplitemvalue IS NOT NULL THEN 0
    ELSE NULL
  END) AS FullCode
from patient pt
LEFT JOIN careplangeneral cpg
  ON pt.patientunitstayid = cpg.patientunitstayid
  AND cpg.cplgroup = 'Care Limitation'
  AND cpg.cplitemvalue IS NOT NULL
  AND cpg.cplitemoffset >  (-1*60)
  AND cpg.cplitemoffset <= (48*60)
GROUP BY pt.patientunitstayid
ORDER BY pt.patientunitstayid
