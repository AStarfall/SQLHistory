UPDATE tt_claim_order
SET audit_time = '2026-06-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND code = 'GJKZ19WO260700043'
  AND audit_time >= '2026-07-01 00:00:00';

UPDATE tt_service_activity_reports
SET audit_time = '2026-06-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND activity_code = '2580872829092233220'
  AND audit_time >= '2026-07-01 00:00:00';

UPDATE tt_claim_rectification_report
SET audit_time = '2026-06-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND rectification = '2580868285016834052'
  AND audit_time >= '2026-07-01 00:00:00';


select id from tt_service_activity_design where code = 'SAN2026071000028';

UPDATE tt_service_activity_reports
SET audit_time = '2026-07-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND activity_code = (select id from tt_service_activity_design where code = 'SAN2026082500054')
  AND audit_time >= '2026-08-01 00:00:00';


UPDATE tt_claim_rectification_report
SET audit_time = '2026-06-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND rectification = (select id from tt_claim_rectification where code = 'AMS2026071000053')
  AND audit_time >= '2026-07-01 00:00:00';