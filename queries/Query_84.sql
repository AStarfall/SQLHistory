SELECT
    -- 【第1步：车辆表】
    v.vin                       AS "1_VIN",
    v.material_code             AS "1_车辆_物料代码",
    v.structure_code            AS "1_车辆自带_结构号代码",

    -- 【第2步：物料管理表】
    m.id                        AS "2_物料_主键ID",
    m.material_code             AS "2_物料_物料代码",
    m.structure_id              AS "2_物料_结构号ID",
    m.structure_code            AS "2_物料_结构号代码",
    m.structure_name            AS "2_物料_结构号名称",
    m.enable                    AS "2_物料_启用状态",

    -- 【第3步：车型组子表(结构号信息)】
    mgm.id                      AS "3_子表_主键ID",
    mgm.structure_id            AS "3_子表_结构号ID",
    mgm.structure_code          AS "3_子表_结构号代码",
    mgm.structure_name          AS "3_子表_结构号名称",
    mgm.foreignerKey            AS "3_子表_外键(foreignerKey)",

    -- 【第4步：索赔车型组主表】
    mg.id                       AS "4_车型组_主键ID",
    mg.model_group_code         AS "4_车型组_代码",
    mg.name                     AS "4_车型组_名称",
    mg.model_group_type         AS "4_车型组_类型(区分工时/备件)",
    mg.enable                   AS "4_车型组_启用状态",

    -- 【第5步：索赔工时维护表】
    COUNT(lh.id)                AS "5_匹配到的工时总条数",
    SUM(CASE WHEN lh.enable = 1 THEN 1 ELSE 0 END) AS "5_其中已启用(enable=1)的工时条数",
    MAX(lh.model_groups)        AS "5_工时表里实际存的model_groups值"

FROM c_oem_isscp_vehicle_db.tm_vehicle v

-- 1 -> 2：车辆关联物料（同时兼容 code 和 id 关联）
         LEFT JOIN c_oem_isscp_vehicle_db.tm_material m
                   ON (TRIM(v.material_code) = TRIM(m.material_code) OR v.material_id = m.id)
                       AND m.dr = 0

-- 2 -> 3：物料关联车型组结构号子表（同时兼容 code、id 以及结构号code/name颠倒的情况）
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_model_groups_model mgm
                   ON (
                          TRIM(m.structure_code) = TRIM(mgm.structure_code)
                              OR m.structure_id = mgm.structure_id
                              OR TRIM(m.structure_name) = TRIM(mgm.structure_code)
                          )
                       AND mgm.dr = 0

-- 3 -> 4：子表关联索赔车型组主表
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_model_groups mg
                   ON mgm.foreignerKey = mg.id
                       AND mg.dr = 0

-- 4 -> 5：车型组关联索赔工时表（同时兼容存 ID 或存 Code 的情况）
         LEFT JOIN c_oem_isscp_aftersvc_db.tm_claim_labor_hours lh
                   ON (lh.model_groups = mg.id OR TRIM(lh.model_groups) = TRIM(mg.model_group_code))
                       AND lh.dr = 0

WHERE v.vin = 'LJ1EKBBR1N1500592'
  AND v.dr = 0
GROUP BY
    v.vin, v.material_code, v.structure_code,
    m.id, m.material_code, m.structure_id, m.structure_code, m.structure_name, m.enable,
    mgm.id, mgm.structure_id, mgm.structure_code, mgm.structure_name, mgm.foreignerKey,
    mg.id, mg.model_group_code, mg.name, mg.model_group_type, mg.enable;