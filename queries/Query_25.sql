SELECT
    main.dealer_id                                                   AS `经销商ID`,
    main.dealer_code                                                 AS `经销商代码`,
    main.dealer_name                                                 AS `经销商名称`,
    main.currency_id                                                 AS `币种ID`,
    curr.name                                                        AS `币种`,

    IFNULL(SUM(CASE WHEN main.verifystate = 4 THEN 1 ELSE 0 END), 0) AS `退回数量`,
    IFNULL(SUM(CASE WHEN main.verifystate = 4 THEN main.total_amount ELSE 0 END),
           0)                                                        AS `退回金额`,

    IFNULL(SUM(CASE WHEN main.verifystate = 3 THEN 1 ELSE 0 END), 0) AS `拒绝数量`,
    IFNULL(SUM(CASE WHEN main.verifystate = 3 THEN main.total_amount ELSE 0 END),
           0)                                                        AS `拒绝金额`,

    IFNULL(SUM(CASE WHEN main.verifystate = 1 THEN 1 ELSE 0 END), 0) AS `处理中数量`,
    IFNULL(SUM(CASE WHEN main.verifystate = 1 THEN main.total_amount ELSE 0 END),
           0)                                                        AS `处理中金额`,

    IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NULL THEN 1 ELSE 0 END),
           0)                                                        AS `通过数量`,
    IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NULL THEN main.total_amount ELSE 0 END),
           0)                                                        AS `通过金额`,

    IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NOT NULL THEN 1 ELSE 0 END),
           0)                                                        AS `已结算数量`,
    IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NOT NULL THEN main.total_amount ELSE 0 END),
           0)                                                        AS `已结算金额`,

    IFNULL(SUM(CASE WHEN main.verifystate IN (1, 2, 3, 4) THEN 1 ELSE 0 END),
           0)                                                        AS `上报总数量`,
    IFNULL(SUM(CASE WHEN main.verifystate IN (1, 2, 3, 4) THEN main.total_amount ELSE 0 END),
           0)                                                        AS `上报总金额`

FROM c_oem_isscp_aftersvc_db.tt_claim_order main

         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant curr
                   ON main.currency_id = curr.id
                       AND curr.dr = 0

         LEFT JOIN c_oem_isscp_aftersvc_db.tm_claim_details detail
                   ON main.code = detail.claim_code
                       AND detail.dr = 0

WHERE main.dr = 0
  AND main.verifystate != 0
-- 预留查询条件
-- AND main.submission_date >= '?' AND main.submission_date <= '?'
-- AND main.dealer_code = '?'

GROUP BY main.dealer_id,
         main.dealer_code,
         main.dealer_name,
         main.currency_id,
         curr.name;