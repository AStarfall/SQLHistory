WITH
-- 1. 总代默认参数（提取总代默认币种）
dealer_default_param AS (
    SELECT dealer_code, currency_id, currency_code
    FROM (
             SELECT
                 dealer_code,
                 currency_id,
                 currency_code,
                 ROW_NUMBER() OVER(PARTITION BY dealer_code ORDER BY modify_time DESC, pubts DESC) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 2. 索赔配件子表：提取标记为主故障件(is_main_fault_part='10041001')的换下件代码(remove_part_code)[cite: 1]
claim_main_part AS (
    SELECT foreignerKey, remove_part_code
    FROM (
             SELECT
                 foreignerKey,
                 remove_part_code,
                 ROW_NUMBER() OVER(PARTITION BY foreignerKey ORDER BY modify_time DESC, id DESC) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_claim_part
             WHERE is_main_fault_part = '10041001' AND dr = 0
         ) t WHERE rn = 1
)

-- 3. 索赔单明细抽取与输出
SELECT
    c.code AS `索赔单号`,
    c.claim_type AS `索赔类型`,
    c.warranty_start_date AS `销售日期`,
    c.fault_date AS `故障日期`,
    c.repair_complete_date AS `维修完成日期`,
    c.submission_date AS `索赔提交日期`,
    c.audit_time AS `索赔终审完成日期`,
    v.model_code AS `车型代码`,
    v.model_name AS `车型名称`,
    COALESCE(c.second_dealer_code, c.dealer_code) AS `二级经销商编码`,
    c.vin AS `VIN`,
    c.mileage_in AS `故障里程`,
    -- 关联配件子表获取换下件代码[cite: 1]
    COALESCE(mp.remove_part_code, '') AS `主故障件代码`,
    ROUND(COALESCE(c.work_hours_amount, 0), 2) AS `工时金额`,
    ROUND(COALESCE(c.part_amount, 0), 2) AS `配件金额`,
    ROUND(COALESCE(c.other_fee_amount, 0), 2) AS `其他费用金额`,
    ROUND(COALESCE(c.part_manage_fee, 0), 2) AS `配件管理金额`,
    ROUND(COALESCE(c.total_amount, 0), 2) AS `总金额`,
    COALESCE(cur.code, 'UNKNOWN') AS `币种`
FROM c_oem_isscp_aftersvc_db.tt_claim_order c
         LEFT JOIN dealer_default_param dp
                   ON c.dealer_code = dp.dealer_code
         LEFT JOIN claim_main_part mp
                   ON c.id = mp.foreignerKey
         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v
                   ON c.vin = v.vin AND v.dr = 0
         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                   ON COALESCE(c.currency_id, dp.currency_id) = cur.id AND cur.dr = 0
WHERE c.verifystate = 2
  AND c.audit_time >= '2026-08-01 00:00:00'
  AND c.audit_time <= '2026-08-31 23:59:59'
  AND c.dr = 0
ORDER BY c.audit_time DESC, c.code;
