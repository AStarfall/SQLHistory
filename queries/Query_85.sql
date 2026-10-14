SELECT
    v.vin                                           AS "车架号(VIN)",
    v.material_code                                 AS "车辆_物料代码",
    v.structure_code                                AS "车辆表自带_结构号(错填为M209)",
    m.structure_code                                AS "物料表真实_结构号(X6027)",
    CASE WHEN m.enable = 1 THEN '已启用(1)'
         ELSE '未启用/停用(0)' END                  AS "物料档案状态(需业务确认)",
    mg.model_group_code                             AS "匹配到的车型组代码",
    mg.name                                         AS "匹配到的车型组名称",
    CASE WHEN mg.model_group_type = '60461001' THEN '60461001-工时车型组'
         WHEN mg.model_group_type = '60461002' THEN '60461002-质保车型组'
         ELSE mg.model_group_type END               AS "车型组类型",
    mg.id                                           AS "车型组底层主键ID(工时关联用)",
    COUNT(lh.id)                                    AS "该车型组下可用工时条数"
FROM c_oem_isscp_vehicle_db.tm_vehicle v
         LEFT JOIN c_oem_isscp_vehicle_db.tm_material m
                   ON TRIM(v.material_code) = TRIM(m.material_code) AND m.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_model_groups_model mgm
                   ON TRIM(m.structure_code) = TRIM(mgm.structure_code) AND mgm.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_model_groups mg
                   ON mgm.foreignerKey = mg.id AND mg.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tm_claim_labor_hours lh
                   ON lh.model_groups = mg.id AND lh.dr = 0 AND lh.enable = 1
WHERE v.vin = 'LJ1EKBBR1N1500592' AND v.dr = 0
GROUP BY
    v.vin, v.material_code, v.structure_code,
    m.structure_code, m.enable,
    mg.model_group_code, mg.name, mg.model_group_type, mg.id;