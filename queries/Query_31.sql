SELECT main.dealer_code                                                                                               AS `经销商代码`,
       main.dealer_name                                                                                               AS `经销商名称`,

       IFNULL(curr.name, '未知币种')                                                                                  AS `_辅助币种分组列`,

       MAX(DATE_FORMAT(main.submission_date, '%Y-%m-%d'))                                                             AS `最新提交日期`,

       IFNULL(SUM(CASE WHEN main.verifystate = 4 THEN 1 ELSE 0 END), 0)                                               AS `退回数量`,
       IFNULL(SUM(CASE WHEN main.verifystate = 4 THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `退回金额`,

       IFNULL(SUM(CASE WHEN main.verifystate = 3 THEN 1 ELSE 0 END), 0)                                               AS `拒绝数量`,
       IFNULL(SUM(CASE WHEN main.verifystate = 3 THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `拒绝金额`,

       IFNULL(SUM(CASE WHEN main.verifystate = 1 THEN 1 ELSE 0 END), 0)                                               AS `处理中数量`,
       IFNULL(SUM(CASE WHEN main.verifystate = 1 THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `处理中金额`,

       IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NULL THEN 1 ELSE 0 END),
              0)                                                                                                      AS `通过数量`,
       IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NULL THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `通过金额`,

       IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NOT NULL THEN 1 ELSE 0 END),
              0)                                                                                                      AS `已结算数量`,
       IFNULL(SUM(CASE WHEN main.verifystate = 2 AND detail.claim_code IS NOT NULL THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `已结算金额`,

       IFNULL(SUM(CASE WHEN main.verifystate IN (1, 2, 3, 4) THEN 1 ELSE 0 END),
              0)                                                                                                      AS `上报总数量`,
       IFNULL(SUM(CASE WHEN main.verifystate IN (1, 2, 3, 4) THEN main.total_amount ELSE 0 END),
              0)                                                                                                      AS `上报总金额`,

       IFNULL(curr.name, '未知币种')                                                                                  AS `币种`

FROM c_oem_isscp_aftersvc_db.tt_claim_order main

         LEFT JOIN iuap_apdoc_basedoc.bd_currency_tenant curr
                   ON main.currency_id = curr.id
                       AND curr.dr = 0

         LEFT JOIN (SELECT DISTINCT claim_code
                    FROM c_oem_isscp_aftersvc_db.tm_claim_details
                    WHERE dr = 0) detail
                   ON main.code = detail.claim_code

WHERE main.dr = 0
  AND main.verifystate != 0

GROUP BY main.dealer_code,
         main.dealer_name,
         IFNULL(curr.name, '未知币种')

ORDER BY main.dealer_code ASC;