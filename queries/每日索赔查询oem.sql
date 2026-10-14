SELECT
    dealer_code                                         AS "经销商代码",
    CASE claim_type
        WHEN '60401001' THEN '一般索赔'
        WHEN '60401004' THEN '零件更换索赔'
        WHEN '60401005' THEN 'PDI索赔'
        WHEN '60401006' THEN '保外索赔'
        WHEN '60401002' THEN '首次保养'
        WHEN '60401003' THEN '定期保养'
        ELSE claim_type
        END                                             AS "索赔类型",
    CASE verifystate
        WHEN 0 THEN '待上报'
        WHEN 1 THEN '已上报'
        WHEN 2 THEN '审核通过'
        WHEN 3 THEN '审核拒绝'
        WHEN 4 THEN '审核退回'
        WHEN 5 THEN '已关闭'
        WHEN 6 THEN '结算支付'
        ELSE CAST(verifystate AS INT)
        END                                             AS "索赔状态",
    code                                            AS "索赔申请单号",
    vin                                                 AS "VIN",
    DATE_FORMAT(submission_date, '%Y/%m/%d') AS "提交时间戳"
FROM tt_claim_order
WHERE dr = 0
  AND submission_date >= '2026-09-13 00:00:00'
  AND submission_date <  '2026-09-14 00:00:00'
ORDER BY submission_date ASC;

