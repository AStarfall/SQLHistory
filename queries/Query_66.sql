-- 1. 对比两个整改主表的状态（主键、审核状态、终止状态、删除标记）
SELECT id, code, name, verifystate, is_stop, dr, start_date, end_date
FROM tt_claim_rectification
WHERE code IN ('AMS2026090700048', 'SAN20250924006252');

-- 2. 查该店是否在这两个项目的经销商适用子表里
SELECT d.id, d.foreignerKey, d.code, d.name, d.dr, r.code AS rec_code
FROM tt_claim_rectification_dealers d
         JOIN tt_claim_rectification r ON d.foreignerKey = r.id
WHERE r.code IN ('AMS2026090700048', 'SAN20250924006252')
  AND d.code = 'GJPE02PV001';

SELECT code, name, dr, create_time
FROM tt_claim_rectification_dealers
WHERE code like '/n';




SELECT
    id,
    foreignerKey,
    code,
    name,
    LENGTH(code) AS code_len,
    CHAR_LENGTH(code) AS code_char_len,
    create_time
FROM tt_claim_rectification_dealers
WHERE code REGEXP '[\r\n]'
   OR name REGEXP '[\r\n]'
   OR code LIKE CONCAT('%', CHAR(10), '%')
   OR code LIKE CONCAT('%', CHAR(13), '%')
   OR name LIKE CONCAT('%', CHAR(10), '%')
   OR name LIKE CONCAT('%', CHAR(13), '%');


UPDATE tt_claim_rectification_dealers
SET code = TRIM(REPLACE(REPLACE(code, CHAR(13), ''), CHAR(10), '')),
    name = TRIM(REPLACE(REPLACE(name, CHAR(13), ''), CHAR(10), ''))
WHERE code REGEXP '[\r\n]'
   OR name REGEXP '[\r\n]';