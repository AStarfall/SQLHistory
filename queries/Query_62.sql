SELECT
    '主动整改' AS `活动类型`,
    -- 1. 地区公司：通过渠道表 tm_dealer.big_org_id 关联用友组织表 org_orgs
    IFNULL (org.name,
            '未知地区' ) AS `地区公司`,
    -- 2. 国家：优先取渠道国家，缺失时回退取方案分配子表维护的国家
    IFNULL (bc.name,
            IFNULL (plan_bc.name,
                    '未知国家' )) AS `国家`,
    -- 3. 经销商代码与名称：优先取实际提报网点，其次取车辆档案归属网点，最后取方案分配网点
    COALESCE(d.dealer_code,
             tv.dealer_code,
             plan_d.code) AS `经销商代码`,
    COALESCE(d.dealer_name,
             tv.dealer_name,
             plan_d.name) AS `经销商名称`,
    -- 4. 主动整改方案信息
    rect_design.code AS `主动整改编号`,
    rect_design.name AS `主动整改名称`,
    -- 5. 车辆 VIN：通过 tm_vehicle.vin 获取标准 17 位 VIN 码
    COALESCE(tv.vin,
             rpt.report_vin_code,
             '未知VIN' ) AS `VIN`,
    -- 6. 工时与费用（按示例 8 工时、0 其他费用对应 160 总费用，单价按 20 计）
    IFNULL (rect_design.work_hours,
            0 ) AS `工时数`,
    IFNULL (rect_design.other_cost,
            0 ) AS `其他费用`,
    (IFNULL(rect_design.work_hours,
            0 ) * 20 + IFNULL (rect_design.other_cost,
                               0 )) AS `总费用`,
    -- 7. 方案说明与指导
    rect_design.opinion AS `解决方案说明`,
    rect_design.description AS `索赔申请指导`,
    -- 8. 业务日期（格式化为示例中的 yyyy/c/e，如 2026/8/5）
    DATE_FORMAT(rect_design.audit_time,
                '%Y/%c/%e' ) AS `活动发布日期`,
    DATE_FORMAT(rpt.report_create_time,
                '%Y/%c/%e' ) AS `提报日期`,
    DATE_FORMAT(rpt.report_audit_time,
                '%Y/%c/%e' ) AS `审批完成日期`,
    DATE_FORMAT(rect_design.start_date,
                '%Y/%c/%e' ) AS `开始日期`,
    DATE_FORMAT(rect_design.end_date,
                '%Y/%c/%e' ) AS `结束日期`
FROM
    c_oem_isscp_aftersvc_db.tt_claim_rectification rect_design -- 【全量追踪驱动】：主动整改方案计划车辆子表
        JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin plan_vin ON rect_design.id = plan_vin.foreignerKey
        AND plan_vin.dr = 0 -- 【车辆档案】：定位到 c_oem_isscp_vehicle_db 库，主键为 vehicle_id
        LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle tv ON plan_vin.vehicle = tv.vehicle_id
        AND tv.dr = 0 -- 【上报数据聚合】：按车辆与整改方案进行收敛，防重复提报扇出
        LEFT JOIN (
        SELECT
            rv.vehicle,
            r.rectification,
            MAX(rv.code) AS report_vin_code,
            MAX(r.dealer) AS dealer_id,
            MAX(r.create_time) AS report_create_time,
            MAX(r.audit_time) AS report_audit_time
        FROM
            c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
                JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv ON r.id = rv.foreignerKey
                AND rv.dr = 0
        WHERE
            r.dr = 0
          AND r.verifystate = 2 -- 已审批通过的提报
        GROUP BY
            rv.vehicle,
            r.rectification ) rpt ON plan_vin.vehicle = rpt.vehicle
        AND rect_design.id = rpt.rectification -- 【兜底经销商】：方案默认分配的经销商子表
        LEFT JOIN (
        SELECT
            foreignerKey,
            MIN(code) AS code,
            MIN(name) AS name,
            MIN(country) AS country_id
        FROM
            c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
        WHERE
            dr = 0
        GROUP BY
            foreignerKey ) plan_d ON rect_design.id = plan_d.foreignerKey -- 【渠道主表】：关联经销商档案
        LEFT JOIN c_oem_isscp_common_db.tm_dealer d ON d.id = COALESCE(rpt.dealer_id,
                                                                       tv.dealer_id)
        AND d.dr = 0 -- 【组织档案（地区公司）】：关联 iuap_apdoc_basedoc.org_orgs
        LEFT JOIN iuap_apdoc_basedoc.org_orgs org ON d.big_org_id = org.id
        AND org.dr = 0 -- 【国家基础档案】
        LEFT JOIN iuap_apdoc_basedoc.bd_country bc ON d.country = bc.id
        AND bc.dr = 0
        LEFT JOIN iuap_apdoc_basedoc.bd_country plan_bc ON plan_d.country_id = plan_bc.id
        AND plan_bc.dr = 0
WHERE
    rect_design.dr = 0
  AND rect_design.verifystate = 2 -- 仅统计审批通过生效的主动整改方案
ORDER BY
    rect_design.code DESC,
    `提报日期` DESC;