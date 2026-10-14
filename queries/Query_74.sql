-- 检查 GJCR08 是否已经存在 2026-09 的结算单，重点看 apply_status 和 verifystate
SELECT
    id,
    code,
    dealer_code_ref,
    settle_month,
    now_settle_month,
    apply_status,
    verifystate,
    total_amt,
    create_time,
    modify_time
FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
WHERE dealer_code_ref = 'GJCR08'
  AND (settle_month = '2026-09' OR now_settle_month = '2026-09')
  AND dr = 0;

-- 对比提报日期与终审完成日期
SELECT
    code AS `索赔单号`,
    dealer_code AS `总代编码`,
    second_dealer_code AS `二级网点`,
    verifystate AS `审核状态(2为终审通过)`,
    submission_date AS `提报日期`,
    audit_time AS `终审完成时间`,
    total_amount AS `总金额`
FROM c_oem_isscp_aftersvc_db.tt_claim_order
WHERE dealer_code = 'GJCR08'
  AND dr = 0
  AND (
    -- 业务以为的 9 月数据（提报时间在9月）
    (submission_date >= '2026-09-01 00:00:00' AND submission_date <= '2026-09-30 23:59:59')
        OR
        -- 代码实际需要的 9 月数据（终审时间在9月）
    (audit_time >= '2026-09-01 00:00:00' AND audit_time <= '2026-09-30 23:59:59')
    )
ORDER BY audit_time DESC, submission_date DESC;




-- 检查服务活动上报（注意网点穿透与审核时间）
SELECT
    rep.id AS report_id,
    COALESCE(parent_d.dealer_code, direct_d.dealer_code) AS actual_dealer_code,
    rep.verifystate,
    rep.audit_time,
    vi.vin
FROM c_oem_isscp_aftersvc_db.tm_vin_imports vi
         INNER JOIN c_oem_isscp_aftersvc_db.tt_service_activity_reports rep
                    ON vi.foreignerKey = rep.id AND rep.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_secondary_outlet sec
                   ON vi.dealer = sec.id AND sec.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer parent_d
                   ON sec.parent_dealer = parent_d.id AND parent_d.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer direct_d
                   ON vi.dealer = direct_d.id AND direct_d.dr = 0
WHERE (parent_d.dealer_code = 'GJCR08' OR direct_d.dealer_code = 'GJCR08')
  AND rep.audit_time >= '2026-09-01 00:00:00'
  AND rep.audit_time <= '2026-09-30 23:59:59'
  AND vi.dr = 0;

-- 检查主动整改上报
SELECT
    rep.id AS rectification_report_id,
    d.dealer_code,
    rep.verifystate,
    rep.audit_time,
    rv.vin
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
         INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report rep
                    ON rv.foreignerKey = rep.id AND rep.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON rep.dealer = d.id AND d.dr = 0
WHERE d.dealer_code = 'GJCR08'
  AND rep.audit_time >= '2026-09-01 00:00:00'
  AND rep.audit_time <= '2026-09-30 23:59:59'
  AND rv.dr = 0;




WITH
august_dealers AS (
    SELECT DISTINCT dealer_code_ref
    FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
    WHERE settle_month = '2026-08' AND dr = 0
),

september_settled_dealers AS (
    SELECT DISTINCT dealer_code_ref
    FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
    WHERE settle_month = '2026-09' AND dr = 0
),

september_valid_data AS (
    -- 索赔单
    SELECT dealer_code, COUNT(1) AS claim_cnt
    FROM c_oem_isscp_aftersvc_db.tt_claim_order
    WHERE verifystate = 2
      AND audit_time >= '2026-09-01 00:00:00'
      AND audit_time <= '2026-09-30 23:59:59'
      AND dr = 0
    GROUP BY dealer_code
)


SELECT
    ad.dealer_code_ref AS `异常总代编码`,
    COALESCE(vd.claim_cnt, 0) AS `9月有效待结索赔单数`,
    '8月结过账但9月未生成结算单' AS `异常描述`
FROM august_dealers ad
         INNER JOIN september_valid_data vd
                    ON ad.dealer_code_ref = vd.dealer_code
         LEFT JOIN september_settled_dealers ssd
                   ON ad.dealer_code_ref = ssd.dealer_code_ref
WHERE ssd.dealer_code_ref IS NULL
ORDER BY `9月有效待结索赔单数` DESC;


























SELECT COUNT(1) AS `9月份结算单总数`
FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
WHERE settle_month = '2026-09' AND dr = 0;



SELECT
    code AS `结算单号`,
    dealer_code_ref AS `总代代码`,
    total_amt AS `总金额`,
    apply_status AS `状态`,
    create_time AS `生成时间`
FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
WHERE settle_month = '2026-09' AND dr = 0
ORDER BY create_time ASC;


SELECT COUNT(1) AS `9月全国终审索赔单真实总数`
FROM c_oem_isscp_aftersvc_db.tt_claim_order
WHERE verifystate = 2
  AND audit_time >= '2026-09-01 00:00:00'
  AND audit_time <= '2026-09-30 23:59:59'
  AND dr = 0;





SELECT dealer_code_ref, settle_month, apply_status, verifystate
FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
WHERE dealer_code_ref = 'GJCR08'
  AND settle_month = '2026-08'
  AND dr = 0;





SELECT dealer_code_ref, settle_month, apply_status
FROM c_oem_isscp_aftersvc_db.tm_claim_settlement
WHERE dealer_code_ref IN ('GJBD05', 'GJBO03PV001', 'GJMY12')
  AND settle_month = '2026-08'
  AND apply_status NOT IN ('61881001', '61881004')
  AND dr = 0;


