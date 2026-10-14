-- 排查出现双胞胎记录的真正分叉点
SELECT
    rect_design.code         AS `方案编号`,
    plan_vin.id              AS `计划表主键ID`,
    plan_vin.vehicle         AS `计划表外键vehicle`,
    tv.model_id                    AS `车辆档案主键id`,
    tv.vehicle_id            AS `车辆档案业务vehicle_id`,
    tv.vin                   AS `车架号VIN`,
    tv.ytenant_id            AS `车辆租户`,
    d.dealer_code            AS `经销商代码`,
    price_param.labor_unit_price AS `单价`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification rect_design
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin plan_vin
              ON plan_vin.ytenant_id = rect_design.ytenant_id
                  AND plan_vin.foreignerKey = rect_design.id
                  AND plan_vin.dr = 0
         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle tv
                   ON plan_vin.vehicle = tv.vehicle_id
                       AND tv.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON d.id = tv.dealer_id AND d.dr = 0
         LEFT JOIN (
    SELECT dealer_code, business_area_id, MAX(labor_unit_price) AS labor_unit_price
    FROM c_oem_isscp_aftersvc_db.tm_claim_base_parameter
    WHERE enable = 1 AND dr = 0
    GROUP BY dealer_code, business_area_id
) price_param
                   ON price_param.dealer_code = d.dealer_code AND price_param.business_area_id = tv.product_line
WHERE rect_design.code = 'AMS2026082000042'
  AND tv.vin = 'LJ166B3E0V2251278';