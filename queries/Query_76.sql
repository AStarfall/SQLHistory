SELECT
    v.vin,
    v.model_code AS `车型代码`,
    v.model_name AS `车型名称`,
    v.material_code AS `整车物料号/配置码`,
    ba.business_area_name AS `产品线`
FROM c_oem_isscp_vehicle_db.tm_vehicle v
         LEFT JOIN c_oem_isscp_vehicle_db.tm_business_area ba
                   ON v.product_line = ba.id
WHERE (v.model_name LIKE '%尊界%' OR v.model_code LIKE '%X6%') -- 换成尊界的实际代号或名称
  AND v.dr = 0
