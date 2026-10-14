EXPLAIN
SELECT
    '主动整改'                                                         AS `活动类型`,
    IFNULL(org.name, '未知地区')                                       AS `地区公司`,
    IFNULL(bc.name, '未知国家')                                        AS `国家`,
    COALESCE(d.dealer_code, tv.dealer_code, plan_d.code)              AS `经销商代码`,
    COALESCE(d.dealer_name, tv.dealer_name, plan_d.name)              AS `经销商名称`,
    rect_design.code                                                   AS `主动整改编号`,
    rect_design.name                                                   AS `主动整改名称`,
    IFNULL(tv.vin, '未知VIN')                                          AS `VIN`,
    IFNULL(rect_design.work_hours, 0)                                  AS `工时数`,
    IFNULL(rect_design.other_cost, 0)                                  AS `其他费用`,
    ROUND(
            IFNULL(rect_design.work_hours, 0) * IFNULL(price_param.labor_unit_price, 0)
                + IFNULL(rect_design.other_cost, 0),
            2
    )                                                                  AS `总费用`,
    rect_design.opinion                                                AS `解决方案说明`,
    rect_design.description                                            AS `索赔申请指导`,
    DATE_FORMAT(rect_design.create_time, '%Y-%c-%e')                   AS `活动发布日期`,
    DATE_FORMAT(rpt.report_create_time, '%Y-%c-%e')                     AS `提报日期`,
    DATE_FORMAT(rpt.report_audit_time, '%Y-%c-%e')                      AS `审批完成日期`,
    DATE_FORMAT(rect_design.start_date, '%Y-%c-%e')                    AS `开始日期`,
    DATE_FORMAT(rect_design.end_date, '%Y-%c-%e')                      AS `结束日期`,
    CASE
        WHEN rect_design.is_stop IN ('1', '10041001') THEN '是'
        ELSE '否'
        END                                                                AS `是否终止`

FROM c_oem_isscp_aftersvc_db.tt_claim_rectification rect_design

         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin plan_vin
              ON plan_vin.ytenant_id = rect_design.ytenant_id
                  AND plan_vin.foreignerKey = rect_design.id
                  AND plan_vin.dr = 0

         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle tv
                   ON plan_vin.vehicle = tv.vehicle_id
                       AND tv.dr = 0

         LEFT JOIN (
    SELECT
        r.rectification                                                AS rectification_id,
        rv.vehicle                                                     AS report_vehicle_id,
        MAX(r.dealer)                                                  AS dealer_id,
        MAX(r.create_time)                                             AS report_create_time,
        MAX(CASE WHEN r.verifystate = 2 THEN r.audit_time ELSE NULL END) AS report_audit_time
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
             JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
                  ON rv.ytenant_id = r.ytenant_id
                      AND rv.foreignerKey = r.id
                      AND rv.dr = 0
    WHERE r.dr = 0
    GROUP BY r.rectification, rv.vehicle
) rpt
                   ON rect_design.id = rpt.rectification_id
                       AND plan_vin.vehicle = rpt.report_vehicle_id

         LEFT JOIN (
    SELECT
        ytenant_id,
        foreignerKey,
        MIN(code)    AS code,
        MIN(name)    AS name,
        MIN(country) AS country_id
    FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
    WHERE dr = 0
    GROUP BY ytenant_id, foreignerKey
) plan_d
                   ON plan_d.ytenant_id = rect_design.ytenant_id
                       AND plan_d.foreignerKey = rect_design.id

         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON d.id = COALESCE(rpt.dealer_id, tv.dealer_id)
                       AND d.dr = 0

         LEFT JOIN iuap_apdoc_basedoc.org_orgs org
                   ON d.big_org_id = org.id
                       AND org.dr = 0

         LEFT JOIN iuap_apdoc_basedoc.bd_country bc
                   ON bc.id = COALESCE(d.country, plan_d.country_id)
                       AND bc.dr = 0

         LEFT JOIN (
    SELECT
        dealer_code,
        business_area_id,
        MAX(labor_unit_price) AS labor_unit_price
    FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
    WHERE enable = 1
      AND dr = 0
    GROUP BY dealer_code, business_area_id
) price_param
                   ON price_param.dealer_code = COALESCE(d.dealer_code, tv.dealer_code, plan_d.code)
                       AND price_param.business_area_id = tv.product_line

WHERE rect_design.dr = 0
  AND rect_design.verifystate = 2
  AND rect_design.code = 'SAN20250703006082';