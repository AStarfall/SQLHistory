SELECT
    FinalReport.`国家名称`,
    FinalReport.`活动编号`,
    FinalReport.`活动名称`,
    FinalReport.`产品线`,
    FinalReport.`币种`,
    FinalReport.`总费用`,
    FinalReport.`开始日期`,
    FinalReport.`结束日期`,
    FinalReport.`发布日期`,
    FinalReport.`结束后上传时间限制`,
    FinalReport.`工时数`,
    FinalReport.`工时单价`,
    FinalReport.`其他费用`,
    FinalReport.`解决方案说明`,
    FinalReport.`索赔申请指导`,
    FinalReport.`经销商代码`,
    FinalReport.`经销商名称`,
    FinalReport.`经销商数量`,
    FinalReport.`车辆台数`,
    FinalReport.`完成台数`,
    CASE
        WHEN FinalReport.`车辆台数` IS NULL OR FinalReport.`车辆台数` = 0 THEN NULL
        ELSE CONCAT(ROUND((FinalReport.`完成台数` / FinalReport.`车辆台数`) * 100, 2), '%')
        END AS `完成率`
FROM (
         SELECT
             dealer_agg.country_names                                 AS `国家名称`,
             design.code                                              AS `活动编号`,
             design.activity_name                                     AS `活动名称`,
             NULL                                                     AS `产品线`,

             -- 【核心修复】：币种三级级联（主表文本 -> 子表关联中台字典代码 -> 国际部通用'USD'）
             COALESCE(
                     NULLIF(design.currency_code, ''),
                     dealer_agg.currency_codes,
                     'USD'
             )                                                        AS `币种`,

             -- 总费用：累计实际结算总额（单台维修费 * 实际完成台数）
             ROUND(
                     (
                         (IFNULL(design.hours, 0) * IFNULL(dealer_agg.labor_unit_price, 0))
                             + IFNULL(design.other_costs, 0)
                         ) * IFNULL(report_agg.completed_qty, 0),
                     2
             )                                                        AS `总费用`,

             DATE_FORMAT(design.activity_start_time, '%Y-%m-%d')      AS `开始日期`,
             DATE_FORMAT(design.activity_end_time, '%Y-%m-%d')        AS `结束日期`,
             DATE_FORMAT(design.audit_time, '%Y-%m-%d')               AS `发布日期`,
             design.upload_deadline                                   AS `结束后上传时间限制`,
             IFNULL(design.hours, 0)                                  AS `工时数`,
             IFNULL(dealer_agg.labor_unit_price, 0)                   AS `工时单价`,
             IFNULL(design.other_costs, 0)                            AS `其他费用`,
             design.solution_description                              AS `解决方案说明`,
             design.application_guide                                 AS `索赔申请指导`,
             dealer_agg.dealer_codes                                  AS `经销商代码`,
             dealer_agg.dealer_names                                  AS `经销商名称`,
             IFNULL(dealer_agg.dealer_count, 0)                       AS `经销商数量`,
             IFNULL(design.plan_count, 0)                             AS `车辆台数`,
             IFNULL(report_agg.completed_qty, 0)                      AS `完成台数`
         FROM c_oem_isscp_aftersvc_db.tt_service_activity_design design

                  -- 【总代直连与币种字典聚合层】：子表外键关联中台 bd_currency_tenant
                  LEFT JOIN (
             SELECT
                 ad.foreignerKey                                      AS activity_id,
                 COUNT(DISTINCT bd.dealer_code)                       AS dealer_count,
                 GROUP_CONCAT(DISTINCT bd.dealer_code SEPARATOR ',')  AS dealer_codes,
                 GROUP_CONCAT(DISTINCT bd.dealer_name SEPARATOR ',')  AS dealer_names,
                 GROUP_CONCAT(DISTINCT bc.name SEPARATOR ',')         AS country_names,
                 -- 核心：提取中台币种档案编码并去重平铺，防止多币种导致裂变
                 GROUP_CONCAT(DISTINCT cur.code SEPARATOR ',')        AS currency_codes,
                 MAX(IFNULL(price.labor_unit_price, 0))               AS labor_unit_price
             FROM c_oem_isscp_aftersvc_db.tm_activity_dealer ad
                      INNER JOIN c_oem_isscp_common_db.tm_dealer bd
                                 ON (ad.dealer = bd.id OR (ad.dealer IS NULL AND ad.dealer_code = bd.dealer_code))
                                     AND bd.dr = 0
                      LEFT JOIN iuap_apdoc_basedoc.bd_country bc
                                ON bd.country = bc.id
                                    AND bc.dr = 0
                 -- 【核心打通】：基于子表单选引用 CurrencyTenantVO 关联真实币种档案
                      LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                                ON ad.currency = cur.id
                                    AND cur.dr = 0
                      LEFT JOIN (
                 SELECT
                     dealer_code,
                     MAX(labor_unit_price) AS labor_unit_price
                 FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
                 WHERE enable = 1 AND dr = 0
                 GROUP BY dealer_code
             ) price ON price.dealer_code = bd.dealer_code
             WHERE ad.dr = 0
             GROUP BY ad.foreignerKey
         ) dealer_agg ON design.id = dealer_agg.activity_id

             -- 【完工台数聚合层】：终审通过(verifystate = 2)去重车架号
                  LEFT JOIN (
             SELECT
                 r.activity_code                                      AS design_id,
                 COUNT(DISTINCT v.vin)                                AS completed_qty
             FROM c_oem_isscp_aftersvc_db.tt_service_activity_reports r
                      JOIN c_oem_isscp_aftersvc_db.tm_vin_imports v
                           ON r.id = v.foreignerKey AND v.dr = 0
             WHERE r.dr = 0
               AND r.verifystate = 2
             GROUP BY r.activity_code
         ) report_agg ON design.id = report_agg.design_id

         WHERE design.dr = 0
           AND design.verifystate = 2

     ) AS FinalReport