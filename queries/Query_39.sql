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

-- 2. 服务活动子表币种映射[cite: 1]
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

-- 3. 主动整改定义子表币种映射（按总代代码匹配 与 缺省默认币种匹配）[cite: 1]
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

-- 4. 索赔单数据抽取与求和[cite: 1]
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
      AND c.audit_time >= '2026-07-01 00:00:00'
      AND c.audit_time <= '2026-07-31 23:59:59'
      AND c.dr = 0
    GROUP BY c.dealer_code, COALESCE(c.currency_id, dp.currency_id, 'UNKNOWN_CURRENCY')
),

-- 5. 服务活动数据抽取与金额计算[cite: 1]
activities_calc AS (
    SELECT
        COALESCE(parent_d.dealer_code, direct_d.dealer_code, sec.dealer_code, vi.dealer) AS dealer_code,
        COALESCE(ad_parent.currency, ad_sec.currency, ad_def.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                ROUND(COALESCE(act.hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(act.other_costs, 0),
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
                       ON COALESCE(parent_d.dealer_code, direct_d.dealer_code, sec.dealer_code, vi.dealer) = bp.dealer_code
                           AND v.product_line = bp.business_area_id
             LEFT JOIN act_dealer_currency ad_parent
                       ON act.id = ad_parent.foreignerKey AND parent_d.id = ad_parent.dealer
             LEFT JOIN act_dealer_currency ad_sec
                       ON act.id = ad_sec.foreignerKey AND (sec.id = ad_sec.dealer OR direct_d.id = ad_sec.dealer)
             LEFT JOIN act_default_currency ad_def
                       ON act.id = ad_def.foreignerKey
             LEFT JOIN dealer_default_param dp
                       ON COALESCE(parent_d.dealer_code, direct_d.dealer_code, sec.dealer_code, vi.dealer) = dp.dealer_code AND dp.rn = 1
    WHERE act.audit_time >= '2026-07-01 00:00:00'
      AND act.audit_time <= '2026-07-31 23:59:59'
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

-- 6. 主动整改数据抽取与金额计算 (通过 tt_claim_rectification_report 上报主表级联定义表与车辆档案)[cite: 1]
rectifications_calc AS (
    SELECT
        -- 对齐代码: 提取上报单主表 dealer 关联的总代代码[cite: 1]
        COALESCE(d.dealer_code, rep.dealer) AS dealer_code,
        -- 对齐代码: 匹配整改定义子表币种 -> 缺省币种 -> 默认币种[cite: 1]
        COALESCE(rd_code.currency, rd_def.currency, dp.currency_id, 'UNKNOWN_CURRENCY') AS currency_id,
        ROUND(
                ROUND(COALESCE(rect.work_hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(rect.other_cost, 0),
                2
        ) AS calc_amount
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
             -- 1. 车辆明细关联上报单主表 (rv.foreignerKey -> rep.id)[cite: 1]
             INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report rep
                        ON rv.foreignerKey = rep.id AND rep.verifystate = 2 AND rep.dr = 0
        -- 2. 上报单主表关联整改定义主单 (rep.rectification -> rect.id 获取工时和费用)[cite: 1]
             LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification rect
                       ON rep.rectification = rect.id AND rect.dr = 0
        -- 3. 上报单主表关联渠道经销商表 (rep.dealer -> d.id 获取总代 dealerCode)[cite: 1]
             LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                       ON rep.dealer = d.id AND d.dr = 0
        -- 4. 车辆明细关联车辆主表 (rv.vehicle -> v.vehicle_id 获取产品线)[cite: 1]
             LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v
                       ON rv.vehicle = v.vehicle_id AND v.dr = 0
        -- 5. 通过 总代代码 + 产品线 寻址启用单价[cite: 1]
             LEFT JOIN base_price_param bp
                       ON COALESCE(d.dealer_code, rep.dealer) = bp.dealer_code
                           AND v.product_line = bp.business_area_id
        -- 6. 关联整改定义子表匹配币种 (rect.id + dealerCode)[cite: 1]
             LEFT JOIN rect_dealer_currency rd_code
                       ON rect.id = rd_code.foreignerKey AND COALESCE(d.dealer_code, rep.dealer) = rd_code.code
        -- 7. 关联整改定义子表匹配缺省币种 (rect.id + DEFAULT)[cite: 1]
             LEFT JOIN rect_default_currency rd_def
                       ON rect.id = rd_def.foreignerKey
        -- 8. 基础参数默认币种兜底[cite: 1]
             LEFT JOIN dealer_default_param dp
                       ON COALESCE(d.dealer_code, rep.dealer) = dp.dealer_code AND dp.rn = 1
    WHERE rep.audit_time >= '2026-07-01 00:00:00'
      AND rep.audit_time <= '2026-07-31 23:59:59'
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

-- 7. 组合全量业务分组 Key (总代代码 + 币种)[cite: 1]
all_groups AS (
    SELECT dealer_code, currency_id FROM claims_agg
    UNION
    SELECT dealer_code, currency_id FROM activities_agg
    UNION
    SELECT dealer_code, currency_id FROM rectifications_agg
)

-- 8. 最终主表聚合输出[cite: 1]
SELECT
    '2026-07' AS `结算月份`,
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