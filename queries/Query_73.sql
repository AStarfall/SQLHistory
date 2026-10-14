WITH
-- 1. 车辆档案字典：提取 VIN 对应的产品线 ID
vehicle_param AS (
    SELECT vin, product_line
    FROM (
             SELECT vin, product_line,
                    ROW_NUMBER() OVER(PARTITION BY vin ORDER BY create_time DESC) AS rn
             FROM c_oem_isscp_vehicle_db.tm_vehicle
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 2. 产品线/业务范围名称字典
product_line_dict AS (
    SELECT id, business_area_name
    FROM c_oem_isscp_vehicle_db.tm_business_area
    WHERE dr = 0
),

-- 3. 币种字典
currency_dict AS (
    SELECT id, code
    FROM iuap_apdoc_basedoc.bd_currency_tenant
    WHERE dr = 0
),

-- 4. 抽取财务终审通过的结算单【索赔明细】
settle_claim_details AS (
    SELECT
        s.id AS settlement_id,
        s.code AS settlement_code,
        s.dealer_code_ref,
        s.settle_month,
        s.audit_time AS settlement_audit_time,
        COALESCE(cur.code, s.currency_enum, 'UNKNOWN') AS currency_code,
        d.claim_code AS bill_code,
        d.vin_claim AS vin,
        d.total_amt_claim AS amount,
        '一般索赔' AS biz_type
    FROM c_oem_isscp_aftersvc_db.tm_claim_settlement s
             INNER JOIN c_oem_isscp_aftersvc_db.tm_claim_details d
                        ON s.id = d.foreignerKey AND d.dr = 0
             LEFT JOIN currency_dict cur
                       ON s.currency_enum = cur.id
    WHERE s.verifystate = 2
      AND s.dr = 0
      AND s.audit_time >= '2026-08-01 00:00:00'
      AND s.audit_time <= '2026-09-30 23:59:59'
),

-- 5. 抽取财务终审通过的结算单【服务活动明细】
settle_activity_details AS (
    SELECT
        s.id AS settlement_id,
        s.code AS settlement_code,
        s.dealer_code_ref,
        s.settle_month,
        s.audit_time AS settlement_audit_time,
        COALESCE(cur.code, s.currency_enum, 'UNKNOWN') AS currency_code,
        d.svc_act_code AS bill_code,
        d.vin_svc AS vin,
        d.total_amt_svc AS amount,
        '服务活动' AS biz_type
    FROM c_oem_isscp_aftersvc_db.tm_claim_settlement s
             INNER JOIN c_oem_isscp_aftersvc_db.tm_service_activity_detail d
                        ON s.id = d.foreignerKey AND d.dr = 0
             LEFT JOIN currency_dict cur
                       ON s.currency_enum = cur.id
    WHERE s.verifystate = 2
      AND s.dr = 0
      AND s.audit_time >= '2026-08-01 00:00:00'
      AND s.audit_time <= '2026-09-30 23:59:59'
),

-- 6. 抽取财务终审通过的结算单【主动整改明细】
settle_rectification_details AS (
    SELECT
        s.id AS settlement_id,
        s.code AS settlement_code,
        s.dealer_code_ref,
        s.settle_month,
        s.audit_time AS settlement_audit_time,
        COALESCE(cur.code, s.currency_enum, 'UNKNOWN') AS currency_code,
        d.proact_rect_code AS bill_code,
        d.vin_rect AS vin,
        d.total_amt_rect AS amount,
        '主动整改' AS biz_type
    FROM c_oem_isscp_aftersvc_db.tm_claim_settlement s
             INNER JOIN c_oem_isscp_aftersvc_db.tm_rectification_detail d
                        ON s.id = d.foreignerKey AND d.dr = 0
             LEFT JOIN currency_dict cur
                       ON s.currency_enum = cur.id
    WHERE s.verifystate = 2
      AND s.dr = 0
      AND s.audit_time >= '2026-08-01 00:00:00'
      AND s.audit_time <= '2026-09-30 23:59:59'
),

-- 7. 合并三大业务明细
all_settle_details AS (
    SELECT * FROM settle_claim_details
    UNION ALL
    SELECT * FROM settle_activity_details
    UNION ALL
    SELECT * FROM settle_rectification_details
)

-- 8. 最终输出：对齐业务老师指定的字段，按单车明细展开
SELECT
    a.settlement_audit_time                       AS `财务终审时间`,
    COALESCE(pl.business_area_name, '未知产品线') AS `产品线`,
    ROUND(a.amount, 2)                            AS `金额`,
    a.currency_code                               AS `币种`,
    a.vin                                         AS `车辆VIN`,
    a.biz_type                                    AS `业务类型`,
    a.bill_code                                   AS `业务单号`,
    a.settlement_code                             AS `结算单号`,
    a.dealer_code_ref                             AS `总代编码`,
    a.settle_month                                AS `结算月份`
FROM all_settle_details a
         LEFT JOIN vehicle_param v
                   ON a.vin = v.vin
         LEFT JOIN product_line_dict pl
                   ON v.product_line = pl.id
ORDER BY
    a.settlement_audit_time DESC,
    a.settlement_code,
    a.vin;