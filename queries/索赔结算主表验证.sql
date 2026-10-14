WITH
-- 1. 基础单价参数：按 (总代代码 + 产品线) 提取最新启用的有效工时单价，对齐 Java 覆盖逻辑
base_price_param AS (
    SELECT dealer_code, business_area_id, labor_unit_price
    FROM (
             SELECT
                 dealer_code,
                 business_area_id,
                 labor_unit_price,
                 ROW_NUMBER() OVER(
                     PARTITION BY dealer_code, business_area_id
                     ORDER BY modify_time DESC, pubts DESC, labor_unit_price DESC
                     ) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
             WHERE enable = 1 AND dr = 0
         ) t WHERE rn = 1
),

-- 2. 总代默认参数：提取总代基本信息与默认结算币种
dealer_default_param AS (
    SELECT dealer_code, dealer_id, dealer_name, currency_id, currency_code
    FROM (
             SELECT
                 dealer_code,
                 dealer_id,
                 dealer_name,
                 currency_id,
                 currency_code,
                 ROW_NUMBER() OVER(PARTITION BY dealer_code ORDER BY modify_time DESC, pubts DESC) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 3. 车辆档案字典：按 vehicle_id 唯一性去重并提取产品线
vehicle_param AS (
    SELECT vehicle_id, vin, product_line
    FROM (
             SELECT
                 vehicle_id,
                 vin,
                 product_line,
                 ROW_NUMBER() OVER(PARTITION BY vehicle_id ORDER BY create_time DESC) AS rn
             FROM c_oem_isscp_vehicle_db.tm_vehicle
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 4. 服务活动设计定义子表币种映射
act_dealer_currency AS (
    SELECT foreignerKey, dealer, currency
    FROM (
             SELECT foreignerKey, dealer, currency,
                    ROW_NUMBER() OVER(PARTITION BY foreignerKey, dealer ORDER BY id) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_activity_dealer
             WHERE dr = 0
         ) t WHERE rn = 1
),
act_default_currency AS (
    SELECT foreignerKey, currency
    FROM (
             SELECT foreignerKey, currency,
                    ROW_NUMBER() OVER(PARTITION BY foreignerKey ORDER BY id) AS rn
             FROM c_oem_isscp_aftersvc_db.tm_activity_dealer
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 5. 主动整改定义子表币种映射
rect_dealer_currency AS (
    SELECT foreignerKey, code, currency
    FROM (
             SELECT foreignerKey, code, currency,
                    ROW_NUMBER() OVER(PARTITION BY foreignerKey, code ORDER BY id) AS rn
             FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
             WHERE dr = 0
         ) t WHERE rn = 1
),
rect_default_currency AS (
    SELECT foreignerKey, currency
    FROM (
             SELECT foreignerKey, currency,
                    ROW_NUMBER() OVER(PARTITION BY foreignerKey ORDER BY id) AS rn
             FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
             WHERE dr = 0
         ) t WHERE rn = 1
),

-- 6. 索赔单数据抽取与聚合
claims_agg AS (
    SELECT
        c.dealer_code,
        COALESCE(c.currency_id, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        COUNT(c.id) AS claim_count,
        ROUND(SUM(COALESCE(c.total_amount, 0)), 2) AS claim_settle_amt
    FROM c_oem_isscp_aftersvc_db.tt_claim_order c
             LEFT JOIN dealer_default_param dp
                       ON c.dealer_code = dp.dealer_code
    WHERE c.verifystate = 2
      AND c.audit_time >= '2026-08-01 00:00:00'
      AND c.audit_time <= '2026-08-31 23:59:59'
      AND c.dr = 0
    GROUP BY c.dealer_code, COALESCE(c.currency_id, dp.currency_id, 'UNKNOWN_CURRENCY')
),

-- 7. 服务活动数据抽取与金额计算 (明细 -> 上报单 -> 设计单 -> 二级网点穿透总代)
activities_calc AS (
    SELECT
        COALESCE(parent_d.dealer_code, direct_d.dealer_code) AS dealer_code,
        COALESCE(ad_parent.currency, ad_sec.currency, ad_def.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                ROUND(COALESCE(act.hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(act.other_costs, 0),
                2
        ) AS calc_amount
    FROM c_oem_isscp_aftersvc_db.tm_vin_imports vi
             INNER JOIN c_oem_isscp_aftersvc_db.tt_service_activity_reports rep
                        ON vi.foreignerKey = rep.id AND rep.verifystate = 2 AND rep.dr = 0
             LEFT JOIN c_oem_isscp_aftersvc_db.tt_service_activity_design act
                       ON rep.activity_code = act.id AND act.dr = 0
             LEFT JOIN c_oem_isscp_common_db.tm_secondary_outlet sec
                       ON vi.dealer = sec.id AND sec.dr = 0
             LEFT JOIN c_oem_isscp_common_db.tm_dealer parent_d
                       ON sec.parent_dealer = parent_d.id AND parent_d.dr = 0
             LEFT JOIN c_oem_isscp_common_db.tm_dealer direct_d
                       ON vi.dealer = direct_d.id AND direct_d.dr = 0
             LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v
                       ON vi.vin = v.vin AND v.dr = 0
             LEFT JOIN base_price_param bp
                       ON COALESCE(parent_d.dealer_code, direct_d.dealer_code) = bp.dealer_code
                           AND v.product_line = bp.business_area_id
             LEFT JOIN act_dealer_currency ad_parent
                       ON act.id = ad_parent.foreignerKey AND parent_d.id = ad_parent.dealer
             LEFT JOIN act_dealer_currency ad_sec
                       ON act.id = ad_sec.foreignerKey AND sec.id = ad_sec.dealer
             LEFT JOIN act_default_currency ad_def
                       ON act.id = ad_def.foreignerKey
             LEFT JOIN dealer_default_param dp
                       ON COALESCE(parent_d.dealer_code, direct_d.dealer_code) = dp.dealer_code
    WHERE rep.audit_time >= '2026-08-01 00:00:00'
      AND rep.audit_time <= '2026-08-31 23:59:59'
      AND vi.dr = 0
),
activities_agg AS (
    SELECT
        dealer_code,
        currency_id,
        COUNT(1) AS activity_count,
        ROUND(SUM(calc_amount), 2) AS svc_act_settle_amt
    FROM activities_calc
    WHERE dealer_code IS NOT NULL
    GROUP BY dealer_code, currency_id
),

-- 8. 主动整改数据抽取与金额计算 (明细 -> 上报单 -> 定义单 -> 直连总代)
rectifications_calc AS (
    SELECT
        d.dealer_code AS dealer_code,
        COALESCE(rd_code.currency, rd_def.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                ROUND(COALESCE(rect.work_hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(rect.other_cost, 0),
                2
        ) AS calc_amount
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
             INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report rep
                        ON rv.foreignerKey = rep.id AND rep.verifystate = 2 AND rep.dr = 0
             LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification rect
                       ON rep.rectification = rect.id AND rect.dr = 0
             LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                       ON rep.dealer = d.id AND d.dr = 0
             LEFT JOIN vehicle_param v
                       ON rv.vehicle = v.vehicle_id
             LEFT JOIN base_price_param bp
                       ON d.dealer_code = bp.dealer_code
                           AND v.product_line = bp.business_area_id
             LEFT JOIN rect_dealer_currency rd_code
                       ON rect.id = rd_code.foreignerKey AND d.dealer_code = rd_code.code
             LEFT JOIN rect_default_currency rd_def
                       ON rect.id = rd_def.foreignerKey
             LEFT JOIN dealer_default_param dp
                       ON d.dealer_code = dp.dealer_code
    WHERE rep.audit_time >= '2026-08-01 00:00:00'
      AND rep.audit_time <= '2026-08-31 23:59:59'
      AND rv.dr = 0
),
rectifications_agg AS (
    SELECT
        dealer_code,
        currency_id,
        COUNT(1) AS rectification_count,
        ROUND(SUM(calc_amount), 2) AS proact_rect_settle_amt
    FROM rectifications_calc
    WHERE dealer_code IS NOT NULL
    GROUP BY dealer_code, currency_id
),

-- 9. 组合全量业务分组 Key
all_groups AS (
    SELECT dealer_code, currency_id FROM claims_agg
    UNION
    SELECT dealer_code, currency_id FROM activities_agg
    UNION
    SELECT dealer_code, currency_id FROM rectifications_agg
)

-- 10. 最终主表聚合输出
SELECT
    '2026-08' AS `结算月份`,
    g.dealer_code AS `经销商代码`,
    COALESCE(dp.dealer_name, g.dealer_code) AS `经销商名称`,
    COALESCE(cur.code, 'UNKNOWN') AS `币种代码`,
    COALESCE(c.claim_count, 0) AS `索赔单数量`,
    COALESCE(c.claim_settle_amt, 0.00) AS `索赔结算金额`,
    COALESCE(a.activity_count, 0) AS `服务活动数量`,
    COALESCE(a.svc_act_settle_amt, 0.00) AS `服务活动结算金额`,
    COALESCE(r.rectification_count, 0) AS `主动整改数量`,
    COALESCE(r.proact_rect_settle_amt, 0.00) AS `主动整改结算金额`,
    ROUND(
            COALESCE(c.claim_settle_amt, 0.00) +
            COALESCE(a.svc_act_settle_amt, 0.00) +
            COALESCE(r.proact_rect_settle_amt, 0.00),
            2
    ) AS `合计金额`
FROM all_groups g
         LEFT JOIN dealer_default_param dp
                   ON g.dealer_code = dp.dealer_code
         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                   ON g.currency_id = cur.id AND cur.dr = 0
         LEFT JOIN claims_agg c
                   ON g.dealer_code = c.dealer_code AND g.currency_id = c.currency_id
         LEFT JOIN activities_agg a
                   ON g.dealer_code = a.dealer_code AND g.currency_id = a.currency_id
         LEFT JOIN rectifications_agg r
                   ON g.dealer_code = r.dealer_code AND g.currency_id = r.currency_id
ORDER BY `经销商代码`, `币种代码`;