-- 1. 查看索赔单主表 tt_claim_order 中与 里程、故障件 相关的列名
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'c_oem_isscp_aftersvc_db'
  AND TABLE_NAME = 'tt_claim_order'
  AND (
    COLUMN_NAME LIKE '%mileage%'
        OR COLUMN_NAME LIKE '%fault%'
        OR COLUMN_NAME LIKE '%part%'
    );

-- 2. 检索库中是否存在索赔配件子表（若主表无主故障件时排查）
SELECT TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'c_oem_isscp_aftersvc_db'
  AND (
    TABLE_NAME LIKE 'tt_claim%part%'
        OR TABLE_NAME LIKE 'tt_claim%material%'
    );