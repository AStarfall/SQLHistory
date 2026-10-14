-- 1. 查看这 3 个项目下 GJIQ14 的现状
SELECT
    r.id AS rec_id,
    r.code AS rec_code,
    r.name AS rec_name,
    d.id AS dealer_sub_id,
    d.code AS dealer_code,
    d.name AS dealer_name
FROM tt_claim_rectification r
         JOIN tt_claim_rectification_dealers d ON d.foreignerKey = r.id AND d.dr = 0
WHERE r.code IN ('SAN20260106006488', 'SAN20260622006722', 'AMS2026090400046')
  AND TRIM(REPLACE(REPLACE(d.code, CHAR(13), ''), CHAR(10), '')) = 'GJIQ14'
  AND r.dr = 0;

-- 2. 检查这 3 个项目中是否已经提前录入过 GJIQ16
SELECT r.code AS rec_code, d.code AS dealer_code, d.id
FROM tt_claim_rectification r
         JOIN tt_claim_rectification_dealers d ON d.foreignerKey = r.id AND d.dr = 0
WHERE r.code IN ('SAN20260106006488', 'SAN20260622006722', 'AMS2026090400046')
  AND TRIM(REPLACE(REPLACE(d.code, CHAR(13), ''), CHAR(10), '')) = 'GJIQ16';



UPDATE tt_claim_rectification_dealers
SET
    code = 'GJIQ16',
    name = 'Madar Al-Mia for Trading Cars, Spare Parts and Accessories Ltd'
WHERE id IN (
             '2026010893936354',
             '2026062202106567',
             '2622566318617919495'
    );


SELECT
    r.code AS rec_code,
    r.name AS rec_name,
    d.id AS dealer_sub_id,
    d.code AS dealer_code,
    d.name AS dealer_name,
    d.country,
    d.modify_time
FROM tt_claim_rectification r
         JOIN tt_claim_rectification_dealers d ON d.foreignerKey = r.id
WHERE r.code IN ('SAN20260106006488', 'SAN20260622006722', 'AMS2026090400046')
  AND d.dr = 0
  AND d.code IN ('GJIQ14', 'GJIQ16');