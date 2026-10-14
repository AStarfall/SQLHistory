WITH
-- 1. 基础单价参数字典
base_price_param AS (SELECT dealer_code, business_area_id, labor_unit_price
                     FROM (SELECT dealer_code,
                                  business_area_id,
                                  labor_unit_price,
                                  ROW_NUMBER() OVER (
                                      PARTITION BY dealer_code, business_area_id
                                      ORDER BY modify_time DESC, pubts DESC, labor_unit_price DESC
                                      ) AS rn
                           FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
                           WHERE enable = 1
                             AND dr = 0) t
                     WHERE rn = 1),
dealer_default_param AS (SELECT dealer_code, currency_id, currency_code
                         FROM (SELECT dealer_code,
                                      currency_id,
                                      currency_code,
                                      ROW_NUMBER() OVER (PARTITION BY dealer_code ORDER BY modify_time DESC, pubts DESC) AS rn
                               FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
                               WHERE dr = 0) t
                         WHERE rn = 1),

-- 2. 车辆档案字典（通过 vehicle_id 关联）
vehicle_param AS (SELECT vehicle_id, vin, model_code, model_name, product_line
                  FROM (SELECT vehicle_id,
                               vin,
                               model_code,
                               model_name,
                               product_line,
                               ROW_NUMBER() OVER (PARTITION BY vehicle_id ORDER BY create_time DESC) AS rn
                        FROM c_oem_isscp_vehicle_db.tm_vehicle
                        WHERE dr = 0) t
                  WHERE rn = 1),

-- 3. 整改定义币种映射
rect_dealer_currency AS (SELECT foreignerKey, code, currency
                         FROM (SELECT foreignerKey,
                                      code,
                                      currency,
                                      ROW_NUMBER() OVER (PARTITION BY foreignerKey, code ORDER BY id) AS rn
                               FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
                               WHERE dr = 0) t
                         WHERE rn = 1),
rect_default_currency AS (SELECT foreignerKey, currency
                          FROM (SELECT foreignerKey,
                                       currency,
                                       ROW_NUMBER() OVER (PARTITION BY foreignerKey ORDER BY id) AS rn
                                FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
                                WHERE dr = 0) t
                          WHERE rn = 1)

-- 4. 主动整改明细输出
SELECT rect.code                                AS `主动整改项目编号`,
       rect.name                                AS `主动整改项目名称`,
       rect.start_date                          AS `主动整改开始日期`,
       rect.end_date                            AS `主动整改结束日期`,
       rect.work_hours                          AS `工时数`,
       ROUND(COALESCE(rect.other_cost, 0), 2)   AS `其他费用`,
       v.model_code                             AS `车型代码`,
       v.model_name                             AS `车型名称`,
       COALESCE(sec.dealer_code, d.dealer_code) AS `二级经销商编码`,
       v.vin                                    AS `VIN`,
       rep.code                                    AS `上报编号`,
       ROUND(
               ROUND(COALESCE(rect.work_hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(rect.other_cost, 0),
               2
       )                                        AS `总金额`,
       COALESCE(cur.code, 'UNKNOWN')            AS `币种`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
         INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report rep
                    ON rv.foreignerKey = rep.id AND rep.verifystate = 2 AND rep.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification rect
                   ON rep.rectification = rect.id AND rect.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON rep.dealer = d.id AND d.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_secondary_outlet sec
                   ON rep.dealer = sec.id AND sec.dr = 0
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
         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                   ON COALESCE(rd_code.currency, rd_def.currency, dp.currency_id) = cur.id AND cur.dr = 0
WHERE rep.audit_time >= '2026-08-01 00:00:00'
  AND rep.audit_time <= '2026-08-31 23:59:59'
  AND rv.dr = 0
AND rep.verifystate = 2
ORDER BY rep.audit_time DESC, rect.code, v.vin;