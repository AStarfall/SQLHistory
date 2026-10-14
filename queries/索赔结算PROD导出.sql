WITH
-- 1. 基础参数：提取启用状态的单价配置（总代 + 产品线寻址）与总代默认币种[cite: 1]
base_price_param AS (
    SELECT
        dealer_code,
        business_area_id,
        labor_unit_price
    FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
    WHERE enable = 1 AND dr = 0
),
dealer_default_param AS (
    SELECT
        dealer_code,
        dealer_id,
        dealer_name,
        currency_id,
        currency_code,
        ROW_NUMBER() OVER(PARTITION BY dealer_code ORDER BY create_time DESC) AS rn
    FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
    WHERE dr = 0
),

-- 2. 索赔单数据抽取与求和[cite: 1]
claims_agg AS (
    SELECT
        c.dealer_code,
        COALESCE(c.currency_id, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        COUNT(c.id) AS claim_count,
        ROUND(SUM(COALESCE(c.total_amount, 0)), 2) AS claim_settle_amt
    FROM c_oem_isscp_aftersvc_db.tt_claim_order c
             LEFT JOIN dealer_default_param dp
                       ON c.dealer_code = dp.dealer_code AND dp.rn = 1
    WHERE c.verifystate = 2
      AND c.audit_time >= '2026-08-01 00:00:00'
      AND c.audit_time <= '2026-08-31 23:59:59'
      AND c.dr = 0
    GROUP BY c.dealer_code, COALESCE(c.currency_id, dp.currency_id, 'UNKNOWN_CURRENCY')
),

-- 3. 服务活动数据抽取与金额计算[cite: 1]
activities_calc AS (
    SELECT
        COALESCE(parent_d.dealer_code, direct_d.dealer_code) AS dealer_code,
        COALESCE(ad_parent.currency, ad_sec.currency, ad_def.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                COALESCE(act.hours, 0) * COALESCE(bp.labor_unit_price, 0) + COALESCE(act.other_costs, 0),
                2
        ) AS calc_amount
    FROM c_oem_isscp_aftersvc_db.tm_vin_imports vi
             INNER JOIN c_oem_isscp_aftersvc_db.tt_service_activity_design act
                        ON vi.foreignerKey = act.id AND act.verifystate = 2 AND act.dr = 0
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
             LEFT JOIN c_oem_isscp_aftersvc_db.tm_activity_dealer ad_parent
                       ON act.id = ad_parent.foreignerKey AND parent_d.id = ad_parent.dealer AND ad_parent.dr = 0
             LEFT JOIN c_oem_isscp_aftersvc_db.tm_activity_dealer ad_sec
                       ON act.id = ad_sec.foreignerKey AND sec.id = ad_sec.dealer AND ad_sec.dr = 0
             LEFT JOIN c_oem_isscp_aftersvc_db.tm_activity_dealer ad_def
                       ON act.id = ad_def.foreignerKey AND ad_def.dr = 0
             LEFT JOIN dealer_default_param dp
                       ON COALESCE(parent_d.dealer_code, direct_d.dealer_code) = dp.dealer_code AND dp.rn = 1
    WHERE act.audit_time >= '2026-08-01 00:00:00'
      AND act.audit_time <= '2026-08-31 23:59:59'
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

-- 4. 主动整改数据抽取与金额计算[cite: 1]
rectifications_calc AS (
    SELECT
        rd.code AS dealer_code,
        COALESCE(rd.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                COALESCE(rect.work_hours, 0) * COALESCE(bp.labor_unit_price, 0) + COALESCE(rect.other_cost, 0),
                2
        ) AS calc_amount
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
             INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification rect
                        ON rv.foreignerKey = rect.id AND rect.verifystate = 2 AND rect.dr = 0
             LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers rd
                       ON rect.id = rd.foreignerKey AND rd.dr = 0
             LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v
                       ON rv.vehicle = v.vehicle_id AND v.dr = 0
             LEFT JOIN base_price_param bp
                       ON rd.code = bp.dealer_code
                           AND v.product_line = bp.business_area_id
             LEFT JOIN dealer_default_param dp
                       ON rd.code = dp.dealer_code AND dp.rn = 1
    WHERE rect.audit_time >= '2026-08-01 00:00:00'
      AND rect.audit_time <= '2026-08-31 23:59:59'
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

-- 5. 组合全量业务分组 Key[cite: 1]
all_groups AS (
    SELECT dealer_code, currency_id FROM claims_agg
    UNION
    SELECT dealer_code, currency_id FROM activities_agg
    UNION
    SELECT dealer_code, currency_id FROM rectifications_agg
)

-- 6. 最终主表聚合输出（已严格对应 tm_claim_settlement 元数据标准中文名）[cite: 1]
SELECT
    '2026-08' AS `结算月份`,
    g.dealer_code AS `经销商代码`,
    COALESCE(dp.dealer_name, g.dealer_code) AS `经销商名称`,
    dp.dealer_id AS `经销商`,
    g.currency_id AS `币种`,
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
                   ON g.dealer_code = dp.dealer_code AND dp.rn = 1
         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                   ON g.currency_id = cur.id AND cur.dr = 0
         LEFT JOIN claims_agg c
                   ON g.dealer_code = c.dealer_code AND g.currency_id = c.currency_id
         LEFT JOIN activities_agg a
                   ON g.dealer_code = a.dealer_code AND g.currency_id = a.currency_id
         LEFT JOIN rectifications_agg r
                   ON g.dealer_code = r.dealer_code AND g.currency_id = r.currency_id
ORDER BY `经销商代码`, `币种代码`;