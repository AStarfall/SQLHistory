SELECT
    t.contract_no                                     AS "发运合同号",
    COALESCE(c.name, t.country)                       AS "国家",
    COALESCE(ba.business_area_name, t.business_area)  AS "业务范围",
    t.quantity                                        AS "数量",
    t.task_publishing_date                            AS "任务发布时间",
    -- 主表任务状态枚举翻译 (oem_pdi_task_status_6258_C)
    CASE CAST(t.status AS CHAR)
        WHEN '62581001' THEN '待完成'
        WHEN '62581002' THEN '部分完成'
        WHEN '62581003' THEN '已完成'
        ELSE t.status
        END                                               AS "状态",
    COALESCE(bp.partner_name, bp.partner_short_name, t.task_service_station) AS "任务实施服务站",
    t.plan_shipment                                   AS "计划装运港",
    t.shipping_mark                                   AS "唛头名称",
    t.shipping_loading_into                           AS "唛头装载港",
    t.shipping_loading_out                            AS "唛头卸货港",
    t.install_date                                    AS "装船时间",
    t.install_address                                 AS "装船地点",
    t.remark                                          AS "备注",
    NULLIF(sub.checked_count, 0)                      AS "已检查台数",
    NULLIF(sub.unchecked_count, 0)                    AS "未检查台数",
    NULLIF(sub.closed_count, 0)                       AS "已关闭台数"
FROM c_oem_isscp_aftersvc_db.TM_BASE_PROJECT_INFO t

-- 1. 国家/地区基础档案
         LEFT JOIN iuap_apdoc_basedoc.bd_country c
                   ON t.country = c.id
                       AND c.dr = 0

-- 2. 产品线/业务范围
         LEFT JOIN c_oem_isscp_vehicle_db.tm_business_area ba
                   ON t.business_area = ba.id
                       AND ba.dr = 0

-- 3. 第三方供应商/实施服务站
         LEFT JOIN c_oem_isscp_common_db.tm_business_partner bp
                   ON t.task_service_station = bp.id
                       AND bp.dr = 0

-- 4. 子表聚合：PDI检查车辆台数统计
         LEFT JOIN (
    SELECT
        v.foreignerKey AS base_project_id,
        COUNT(CASE WHEN v.status IN ('CHECKED', '20', '已检查')   THEN 1 END) AS checked_count,
        COUNT(CASE WHEN v.status IN ('UNCHECKED', '10', '未检查') THEN 1 END) AS unchecked_count,
        COUNT(CASE WHEN v.status IN ('CLOSED', '30', '已关闭')    THEN 1 END) AS closed_count
    FROM c_oem_isscp_aftersvc_db.tm_vehiclde_record v
    WHERE v.dr = 0
    GROUP BY v.foreignerKey
) sub
                   ON t.id = sub.base_project_id

WHERE t.dr = 0
ORDER BY t.task_publishing_date DESC;