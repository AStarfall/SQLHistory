UPDATE c_oem_isscp_aftersvc_db.tt_service_activity_reports
SET audit_time = '2026-07-15 10:00:00'
WHERE dr = 0
  AND verifystate = 2
  AND activity_code = (select id from c_oem_isscp_aftersvc_db.tt_service_activity_design where code = 'SAN2026082500054')
  AND audit_time >= '2026-08-01 00:00:00';

