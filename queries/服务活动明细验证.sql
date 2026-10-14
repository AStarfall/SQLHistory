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

-- 2. 设计单币种映射
act_dealer_currency AS (SELECT foreignerKey, dealer, currency
                        FROM (SELECT foreignerKey,
                                     dealer,
                                     currency,
                                     ROW_NUMBER() OVER (PARTITION BY foreignerKey, dealer ORDER BY id) AS rn
                              FROM c_oem_isscp_aftersvc_db.tm_activity_dealer
                              WHERE dr = 0) t
                        WHERE rn = 1),
act_default_currency AS (SELECT foreignerKey, currency
                         FROM (SELECT foreignerKey,
                                      currency,
                                      ROW_NUMBER() OVER (PARTITION BY foreignerKey ORDER BY id) AS rn
                               FROM c_oem_isscp_aftersvc_db.tm_activity_dealer
                               WHERE dr = 0) t
                         WHERE rn = 1)

-- 3. 服务活动明细输出
SELECT act.code                                        AS `服务活动编号`,
       act.activity_name                               AS `服务活动名称`,
       act.activity_start_time                         AS `活动开始日期`,
       act.activity_end_time                           AS `活动结束日期`,
       act.hours                                       AS `工时数`,
       ROUND(COALESCE(act.other_costs, 0), 2)          AS `其他费用`,
       v.model_code                                    AS `车型代码`,
       v.model_name                                    AS `车型名称`,
       COALESCE(sec.dealer_code, direct_d.dealer_code) AS `二级经销商编码`,
       vi.vin                                          AS `VIN`,
       ROUND(
               ROUND(COALESCE(act.hours, 0) * COALESCE(bp.labor_unit_price, 0), 2) + COALESCE(act.other_costs, 0),
               2
       )                                               AS `总金额`,
       COALESCE(cur.code, 'UNKNOWN')                   AS `币种`
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
         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant cur
                   ON COALESCE(ad_parent.currency, ad_sec.currency, ad_def.currency, dp.currency_id) = cur.id AND
                      cur.dr = 0
WHERE rep.audit_time >= '2026-08-01 00:00:00'
  AND rep.audit_time <= '2026-08-31 23:59:59'
  AND vi.dr = 0
  AND COALESCE(sec.dealer_code, direct_d.dealer_code) is not null
ORDER BY rep.audit_time DESC, act.code, vi.vin;