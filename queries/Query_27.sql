SELECT FinalReport.`国家名称`,
       FinalReport.`活动编号`,
       FinalReport.`活动名称`,
       FinalReport.`活动类型`,
       FinalReport.`开始日期`,
       FinalReport.`结束日期`,
       FinalReport.`发布日期`,
       FinalReport.`结束后上传时间限制`,
       FinalReport.`工时数`,
       FinalReport.`其他费用`,
       FinalReport.`解决方案说明`,
       FinalReport.`索赔申请指导`,
       FinalReport.`经销商代码`,
       FinalReport.`经销商名称`,
       FinalReport.`经销商数量`,
       FinalReport.`车辆台数`,
       FinalReport.`完成台数`,

       CASE
           WHEN FinalReport.`车辆台数` = 0 THEN '0.00%'
           ELSE CONCAT(ROUND((FinalReport.`完成台数` / FinalReport.`车辆台数`) * 100, 2), '%')
           END AS `完成率`

FROM (SELECT MAX(bc.name)                                        AS `国家名称`,
             design.code                                         AS `活动编号`,
             design.activity_name                                AS `活动名称`,
             '服务活动'                                          AS `活动类型`,
             DATE_FORMAT(design.activity_start_time, '%Y-%m-%d') AS `开始日期`,
             DATE_FORMAT(design.activity_end_time, '%Y-%m-%d')   AS `结束日期`,
             DATE_FORMAT(design.create_time, '%Y-%m-%d')         AS `发布日期`,
             design.upload_deadline                              AS `结束后上传时间限制`,
             design.hours                                        AS `工时数`,
             design.other_costs                                  AS `其他费用`,
             design.solution_description                         AS `解决方案说明`,
             design.application_guide                            AS `索赔申请指导`,
             dealer_agg.dealer_codes                             AS `经销商代码`,
             dealer_agg.dealer_names                             AS `经销商名称`,
             IFNULL(dealer_agg.dealer_count, 0)                  AS `经销商数量`,
             IFNULL(design.plan_count, 0)                        AS `车辆台数`,
             IFNULL(report_agg.completed_qty, 0)                 AS `完成台数`
      FROM c_oem_isscp_aftersvc_db.tt_service_activity_design design

               LEFT JOIN (SELECT ad.foreignerKey                                     AS activity_id,
                                 MAX(bd.country)                                     AS country_id,
                                 COUNT(DISTINCT ad.dealer_code)                      AS dealer_count,
                                 GROUP_CONCAT(DISTINCT ad.dealer_code SEPARATOR ',') AS dealer_codes,
                                 GROUP_CONCAT(DISTINCT bd.dealer_name SEPARATOR ',') AS dealer_names
                          FROM c_oem_isscp_aftersvc_db.tm_activity_dealer ad
                                   LEFT JOIN c_oem_isscp_common_db.tm_dealer bd ON ad.dealer = bd.id AND bd.dr = 0
                          WHERE ad.dr = 0
                          GROUP BY ad.foreignerKey) dealer_agg ON design.id = dealer_agg.activity_id

               LEFT JOIN iuap_apdoc_basedoc.bd_country bc ON dealer_agg.country_id = bc.id AND bc.dr = 0

               LEFT JOIN (SELECT r.activity_code       AS design_id,
                                 COUNT(DISTINCT v.vin) AS completed_qty
                          FROM c_oem_isscp_aftersvc_db.tt_service_activity_reports r
                                   JOIN c_oem_isscp_aftersvc_db.tm_vin_imports v ON r.id = v.foreignerKey AND v.dr = 0
                          WHERE r.dr = 0
                            AND r.verifystate = 2
                          GROUP BY r.activity_code) report_agg ON design.id = report_agg.design_id

      WHERE design.dr = 0
        AND design.verifystate = 2


      UNION ALL

      SELECT MAX(bc.name)                                     AS `国家名称`,
             rect_design.code                                 AS `活动编号`,
             rect_design.name                                 AS `活动名称`,
             '主动整改'                                       AS `活动类型`,
             DATE_FORMAT(rect_design.start_date, '%Y-%m-%d')  AS `开始日期`,
             DATE_FORMAT(rect_design.end_date, '%Y-%m-%d')    AS `结束日期`,
             DATE_FORMAT(rect_design.create_time, '%Y-%m-%d') AS `发布日期`,
             rect_design.day                                  AS `结束后上传时间限制`,
             rect_design.work_hours                           AS `工时数`,
             rect_design.other_cost                           AS `其他费用`,
             rect_design.opinion                              AS `解决方案说明`,
             rect_design.description                          AS `索赔申请指导`,
             rect_dealer_agg.dealer_codes                     AS `经销商代码`,
             rect_dealer_agg.dealer_names                     AS `经销商名称`,
             IFNULL(rect_dealer_agg.dealer_count, 0)          AS `经销商数量`,
             IFNULL(rect_plan_agg.plan_qty, 0)                AS `车辆台数`,
             IFNULL(rect_report_agg.completed_qty, 0)         AS `完成台数`
      FROM c_oem_isscp_aftersvc_db.tt_claim_rectification rect_design

               LEFT JOIN (SELECT foreignerKey                              AS activity_id,
                                 MAX(country)                              AS country_id,
                                 COUNT(DISTINCT code)                      AS dealer_count,
                                 GROUP_CONCAT(DISTINCT code SEPARATOR ',') AS dealer_codes,
                                 GROUP_CONCAT(DISTINCT name SEPARATOR ',') AS dealer_names
                          FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
                          WHERE dr = 0
                          GROUP BY foreignerKey) rect_dealer_agg ON rect_design.id = rect_dealer_agg.activity_id

               LEFT JOIN iuap_apdoc_basedoc.bd_country bc ON rect_dealer_agg.country_id = bc.id AND bc.dr = 0

               LEFT JOIN (SELECT foreignerKey AS activity_id,
                                 COUNT(1)     AS plan_qty
                          FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_vin
                          WHERE dr = 0
                          GROUP BY foreignerKey) rect_plan_agg ON rect_design.id = rect_plan_agg.activity_id

               LEFT JOIN (SELECT r.rectification           AS design_id,
                                 COUNT(DISTINCT v.vehicle) AS completed_qty
                          FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
                                   JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin v
                                        ON r.id = v.foreignerKey AND v.dr = 0
                          WHERE r.dr = 0
                            AND r.verifystate = 2
                          GROUP BY r.rectification) rect_report_agg ON rect_design.id = rect_report_agg.design_id

      WHERE rect_design.dr = 0
        AND rect_design.verifystate = 2) AS FinalReport

ORDER BY FinalReport.`发布日期` DESC;