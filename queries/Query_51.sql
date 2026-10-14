UPDATE c_oem_isscp_aftersvc_db.tm_claim_settlement
SET
    apply_status = '61881001',
    verifystate = 0
WHERE id IN ('2622394124796428479')
and dr = 0;

select * from c_oem_isscp_aftersvc_db.tm_claim_settlement
where dr = 0;

UPDATE tm_claim_settlement
SET
    region_company = '亚非地区公司',
    country = '利比里亚'
WHERE id IN ('2619893654942647102')
  and dr = 0;



select *
from c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
where foreignerKey in (select id
                       from c_oem_isscp_aftersvc_db.tt_claim_rectification
                       where code in ('SAN20240806005482'));




LJ12EKR29S4708054
SELECT
    v.vin AS 车辆VIN,
    LENGTH(v.vin) AS 字符长度,
    v.vehicle_id,
    rv.id AS 整改明细行ID,
    rv.foreignerkey AS 所属整改ID,
    r.code AS 整改项目编码
FROM c_oem_isscp_vehicle_db.tm_vehicle v
         LEFT JOIN tt_claim_rectification_vin rv ON v.vehicle_id = rv.vehicle AND rv.dr = 0
         LEFT JOIN tt_claim_rectification r ON rv.foreignerkey = r.id AND r.dr = 0
WHERE v.vin IN (
                'LJ12EKR29S4708054',
                'LJ12EKR2XS4708130',
                'LJ12EKR27S4708120',
                'LJ12EKR24S4708155'
    );



SELECT
    rv.id AS 上报明细ID,
    rp.code AS 上报单号,
    rp.verifystate AS 单据审批状态,
    v.vin AS 车辆VIN
FROM tt_claim_rectification_report_vin rv
         JOIN tt_claim_rectification_report rp ON rv.foreignerkey = rp.id
         JOIN c_oem_isscp_vehicle_db.tm_vehicle v ON rv.vehicle = v.vehicle_id
WHERE v.vehicle_id IN (
                       '4641484600139047907',
                       '4641484600138994594',
                       '4641484600138998025',
                       '4641484600138996121'
    )
  AND rv.dr = 0
  AND rp.dr = 0;


SELECT
    r.id AS 上报单ID,
    r.code AS 上报单号,
    r.rectification AS 上报单关联的整改项目ID,
    rec.code AS 关联的整改项目编码,
    rec.name AS 关联的整改项目名称,
    v.vin AS 成功导入的车辆VIN,
    rv.create_time AS 导入时间
FROM tt_claim_rectification_report_vin rv
         JOIN tt_claim_rectification_report r ON rv.foreignerkey = r.id
         JOIN tt_claim_rectification rec ON r.rectification = rec.id
         JOIN c_oem_isscp_vehicle_db.tm_vehicle v ON rv.vehicle = v.vehicle_id
WHERE rv.dr = 0
ORDER BY rv.create_time DESC;













