SELECT
    v.vin                AS "车架号(VIN)",
    v.material_code      AS "物料代码",
    v.structure_code     AS "车辆表上的结构号",
    m.structure_code     AS "物料表上的结构号",
    m.enable             AS "物料启用状态(0未启用/1启用)",
    CASE
        WHEN m.id IS NULL THEN '异常1：车辆的物料代码在物料表不存在'
        WHEN IFNULL(v.structure_code, '') <> IFNULL(m.structure_code, '') THEN '异常2：车辆表与物料表的结构号不一致'
        WHEN m.enable <> 1 THEN '异常3：对应物料未启用(enable=0)'
        ELSE '正常'
        END                  AS "数据诊断结论"
FROM c_oem_isscp_vehicle_db.tm_vehicle v
         LEFT JOIN c_oem_isscp_vehicle_db.tm_material m
                   ON TRIM(v.material_code) = TRIM(m.material_code) AND m.dr = 0
WHERE v.dr = 0
  AND (
    m.id IS NULL
        OR IFNULL(v.structure_code, '') <> IFNULL(m.structure_code, '')
        OR m.enable <> 1
    );