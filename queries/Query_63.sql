SELECT
    '主动整改'                                                         AS `活动类型`,

    -- 1. 地区公司
    IFNULL(org.name, '未知地区')                                       AS `地区公司`,

    -- 2. 国家
    IFNULL(bc.name, IFNULL(plan_bc.name, '未知国家'))                 AS `国家`,

    -- 3. 经销商代码与名称
    COALESCE(d.dealer_code, tv.dealer_code, plan_d.code)              AS `经销商代码`,
    COALESCE(d.dealer_name, tv.dealer_name, plan_d.name)              AS `经销商名称`,

    -- 4. 主动整改方案信息
    rect_design.code                                                   AS `主动整改编号`,
    rect_design.name                                                   AS `主动整改名称`,

    -- 5. 车辆 17 位 VIN（直接取车辆档案的真实 vin）
    IFNULL(tv.vin, '未知VIN')                                          AS `VIN`,

    -- 6. 工时数与其他费用
    IFNULL(rect_design.work_hours, 0)                                  AS `工时数`,
    IFNULL(rect_design.other_cost, 0)                                  AS `其他费用`,

    -- 7. 总费用：工时数 * 工时单价 + 其他费用
    ROUND(
            IFNULL(rect_design.work_hours, 0) * IFNULL(price_param.labor_unit_price, 0)
                + IFNULL(rect_design.other_cost, 0),
            2
    )                                                                  AS `总费用`,

    -- 8. 方案说明与指导
    rect_design.opinion                                                AS `解决方案说明`,
    rect_design.description                                            AS `索赔申请指导`,

    -- 9. 业务日期
    DATE_FORMAT(rect_design.create_time, '%Y-%c-%e')                   AS `活动发布日期`,
    DATE_FORMAT(rpt.report_create_time,  '%Y-%c-%e')                     AS `提报日期`,
    DATE_FORMAT(rpt.report_audit_time,  '%Y-%c-%e')                      AS `审批完成日期`,
    DATE_FORMAT(rect_design.start_date, '%Y-%c-%e')                    AS `开始日期`,
    DATE_FORMAT(rect_design.end_date, '%Y-%c-%e')                      AS `结束日期`,

    -- 10. 是否终止
    CASE
        WHEN rect_design.is_stop IN ('1', '10041001') THEN '是'
        ELSE '否'
        END                                                                AS `是否终止`

FROM c_oem_isscp_aftersvc_db.tt_claim_rectification rect_design

-- 【主驱动】：只拉取有效且审批发布的整改活动（可在此处按需添加发布年份/日期过滤加速）
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin plan_vin
              ON rect_design.id = plan_vin.foreignerKey
                  AND plan_vin.dr = 0

-- 【车辆档案】：主键关联 (eq_ref 级别极速)
         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle tv
                   ON plan_vin.vehicle = tv.vehicle_id
                       AND tv.dr = 0

-- 【上报收敛（关键优化）】：按活动与车辆分组，去除 OR 条件，保证 1:1 精确等值匹配
         LEFT JOIN (
    SELECT
        r.rectification                                AS rectification_id,
        rv.vehicle                                     AS report_vehicle_id,
        MAX(r.dealer)                                  AS dealer_id,
        MAX(r.create_time)                             AS report_create_time,
        -- 仅在审批通过状态(verifystate=2)时保留审核时间，其余情况置 NULL
        MAX(CASE WHEN r.verifystate = 2 THEN r.audit_time ELSE NULL END) AS report_audit_time
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
             JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
                  ON r.id = rv.foreignerKey
                      AND rv.dr = 0
    WHERE r.dr = 0
    GROUP BY r.rectification, rv.vehicle
) rpt
                   ON rect_design.id = rpt.rectification_id
                       AND plan_vin.vehicle = rpt.report_vehicle_id

-- 【方案保底网点】：按活动收敛
         LEFT JOIN (
    SELECT
        foreignerKey,
        MIN(code)    AS code,
        MIN(name)    AS name,
        MIN(country) AS country_id
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
    WHERE dr = 0
    GROUP BY foreignerKey
) plan_d ON rect_design.id = plan_d.foreignerKey

-- 【渠道主表】：主键等值查找
         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON d.id = COALESCE(rpt.dealer_id, tv.dealer_id)
                       AND d.dr = 0

-- 【基础档案】：组织与国家
         LEFT JOIN iuap_apdoc_basedoc.org_orgs org
                   ON d.big_org_id = org.id
                       AND org.dr = 0

         LEFT JOIN iuap_apdoc_basedoc.bd_country bc
                   ON d.country = bc.id
                       AND bc.dr = 0

         LEFT JOIN iuap_apdoc_basedoc.bd_country plan_bc
                   ON plan_d.country_id = plan_bc.id
                       AND plan_bc.dr = 0

-- 【索赔基础参数】：工时单价
         LEFT JOIN c_oem_isscp_aftersvc_db.tm_claim_base_parameter price_param
                   ON price_param.dealer_code = COALESCE(d.dealer_code, tv.dealer_code, plan_d.code)
                       AND price_param.business_area_id = tv.product_line
                       AND price_param.enable = 1
                       AND price_param.dr = 0

WHERE rect_design.dr = 0
  AND rect_design.verifystate = 2