SELECT main.code                                         AS `预授权申请单号`,
       main.claim_no                                     AS `索赔申请单号`,
       main.internal_claim_no                            AS `经销商内部索赔单号`,

       CASE main.claim_type
           WHEN '60401001' THEN '一般索赔'
           WHEN '60401004' THEN '零件更换索赔'
           WHEN '60401005' THEN 'PDI索赔'
           WHEN '60401006' THEN '保外索赔'
           ELSE main.claim_type
           END                                           AS `索赔类型`,

       DATE_FORMAT(main.warranty_start_date, '%Y-%m-%d') AS `销售日期`,
       DATE_FORMAT(main.fault_date, '%Y-%m-%d')          AS `故障日期`,
       DATE_FORMAT(main.create_time, '%Y-%m-%d')         AS `创建日期`,
       DATE_FORMAT(main.submit_date, '%Y-%m-%d')         AS `提交日期`,
       DATE_FORMAT(main.audit_time, '%Y-%m-%d')          AS `审核完成日期`,

       main.vehicle_model_code                           AS `车型代码`,
       main.vehicle_model_name                           AS `车型名称`,
       main.vin                                          AS `VIN`,
       main.car_num                                      AS `车牌号`,
       main.engine_no                                    AS `发动机/电机号`,

       sec_dealer.dealer_code                            AS `二级经销商代码`,

       main.mileage_in                                   AS `故障里程`,

       pm.part_code                                      AS `主故障件代码`,
       pm.part_name                                      AS `主故障件名称`,
       part.install_qty                                  AS `换上件数量`,
       part.sup_code                                     AS `供应商代码`,

       IFNULL(main.work_hours_amount, 0)                 AS `基本工时金额`,
       IFNULL(main.part_amount, 0)                       AS `配件金额`,
       IFNULL(main.other_fee_amount, 0)                  AS `其他费用金额`,
       IFNULL(main.part_manage_fee, 0)                   AS `配件管理费`,
       IFNULL(main.total_amount, 0)                      AS `总金额`,

       main.remark                                       AS `申请备注`,

       CASE main.verifystate
           WHEN 0 THEN '已保存'
           WHEN 1 THEN '审核中'
           WHEN 2 THEN '审核通过'
           WHEN 3 THEN '审核拒绝'
           WHEN 4 THEN '审核退回'
           ELSE '未知状态'
           END                                           AS `申请状态`

FROM c_oem_isscp_aftersvc_db.tt_pre_authorization main

         LEFT JOIN c_oem_isscp_aftersvc_db.tm_preauth_part part
                   ON main.id = part.foreignerKey
                       AND part.is_main_fault_part = '10041001'
                       AND part.dr = 0

         LEFT JOIN c_oem_isscp_part_db.tm_part_material pm
                   ON part.remove_part_code = pm.id
                       AND pm.dr = 0

         LEFT JOIN c_oem_isscp_common_db.tm_secondary_outlet sec_dealer
                   ON main.second_dealer_id = sec_dealer.id
                       AND sec_dealer.dr = 0
                       AND sec_dealer.status = '10011001'

WHERE main.verifystate != 0


ORDER BY main.create_time DESC;