SELECT
    COUNT(DISTINCT v.vehicle)                                            AS `当前SQL查出的总数(148)`,
    COUNT(DISTINCT CASE WHEN target.id IS NOT NULL THEN v.vehicle END)  AS `白名单内有效完成数(应为66)`,
    COUNT(DISTINCT CASE WHEN target.id IS NULL THEN v.vehicle END)      AS `越界/串项目的脏数据量(应为82)`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin v
              ON r.id = v.foreignerKey AND v.dr = 0
-- 核心校验：左连当前整改单的目标车辆白名单
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin target
                   ON r.rectification = target.foreignerKey
                       AND v.vehicle = target.vehicle
                       AND target.dr = 0
WHERE r.dr = 0
  AND r.verifystate = 2
  AND r.rectification = '2026052200562506';



SELECT
    v.vehicle                                AS `车辆标识`,
    r.id                                     AS `上报单ID`,
    r.code                                   AS `上报单号`,
    r.rectification                          AS `上报单记录的整改单ID`,
    r.verifystate                            AS `上报单状态`,
    target.id                                AS `是否在本项目白名单中(NULL表示不在)`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin v
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
              ON v.foreignerKey = r.id AND r.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin target
                   ON r.rectification = target.foreignerKey
                       AND v.vehicle = target.vehicle
                       AND target.dr = 0
WHERE v.dr = 0
  AND v.vehicle = 'LJ11PAADXR1310635';


-- 查看整改上报单中该外键的数据特征（是19位ID、单据编号还是短枚举值）
SELECT id, code, rectification, verifystate
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report
WHERE dr = 0
ORDER BY create_time DESC
LIMIT 5;


-- 统计该整改单白名单车辆在各审核状态下的分布
SELECT
    r.verifystate                                              AS `上报单审核状态`,
    CASE r.verifystate
        WHEN 0 THEN '开立/草稿'
        WHEN 1 THEN '审核中'
        WHEN 2 THEN '审核通过'
        WHEN 3 THEN '已拒绝'
        WHEN 4 THEN '已退回'
        ELSE '其他'
        END                                                        AS `状态描述`,
    COUNT(DISTINCT v.vehicle)                                  AS `白名单内车辆数`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin v
              ON r.id = v.foreignerKey AND v.dr = 0
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_vin target
              ON r.rectification = target.foreignerKey
                  AND v.vehicle = target.vehicle
                  AND target.dr = 0
WHERE r.dr = 0
  AND r.rectification = '2026052200562506'
GROUP BY r.verifystate;

-- 查看上报车辆子表物理结构与实际存值特征
SELECT *
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin
WHERE dr = 0
ORDER BY create_time DESC
LIMIT 2;













-- 确认是否存在 revinid 及其真实物理列名
DESC c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin;





-- 检查该整改单上报的明细中，revinid 是否都有值（是否有 NULL）
SELECT
    COUNT(1)                                AS `明细总行数(171)`,
    COUNT(vehicle)                          AS `vehicle有值数`,
    COUNT(CASE WHEN vehicle IS NULL THEN 1 END) AS `vehicle为空数`
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin v
         JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report r
              ON v.foreignerKey = r.id AND r.dr = 0
WHERE v.dr = 0
  AND r.rectification = '2026052200562506'; -- 替换为当前整改单ID


-- 确认设计单目标车辆表的字段名（是存 vehicle 还是 vin）
DESC c_oem_isscp_aftersvc_db.tt_claim_rectification_vin;






SELECT T0.id, T0.dealer_code, T1.dealer_code AS dealerCode
FROM c_oem_isscp_common_db.tm_secondary_outlet T0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer T1 ON T1.id = T0.parent_dealer AND T1.dr = 0
WHERE T0.dealer_code IN ('GJRU21045') AND T0.dr = 0 AND T0.ytenant_id = 'bsnk1p0r'



select * from  c_oem_isscp_aftersvc_db.tt_claim_rectification_report r1
         Inner join c_oem_isscp_common_db.tm_dealer d1 on d1.id = r1.dealer
         where d1.dealer_code = 'GJLS04CV001'

SELECT id, dealer_code, dealer_name, dr
FROM c_oem_isscp_common_db.tm_dealer
WHERE dealer_code = 'GJLS04CV001';

SELECT id, foreignerkey, code, name, dr, create_time, pubts
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin
WHERE foreignerkey = '2024031265927542'
  AND code = 'GJLS04CV001'


SELECT id, foreignerKey, code, name, dr,creator ,create_time, pubts
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
WHERE foreignerKey = '2024031265927542'
  AND code = 'GJLS04CV001';

SELECT id, code, rectification, dealer, verifystate, dr
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report
WHERE code = 'D20260813019';

SELECT
    rv.id AS sub_id,
    rv.foreignerKey,
    rv.vehicle AS vehicle_id,
    v.vin,
    rv.mileage,
    rv.end_date,
    rv.create_time,
    rv.creator,
    rv.dr,
    rv.pubts
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v ON rv.vehicle = v.vehicle_id
WHERE rv.foreignerKey = '2605856593729814535'
  AND v.vin IN ('LJ166A254T4005699', 'LJ166A256T4006868');







