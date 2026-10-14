select a.id                                  as 主表id,
       b.id                                  as 子表id,
       a.policy_no,
       a.warranty_mileage                    as 保修里程,
       a.warranty_months                     as 保修月数,
       a.dealer_code                         as 经销商代码,
       c.model_group_code                    as 车型组代码,
       c.name                                as 车型组名称,
       a.dr,
       case vehicle_nature
           when '60631001' then '私家车'
           when '60631002' then '商用车'
           when '60631003' then '出租车'
           when '60631004' then '租赁车' end as 车辆性质,
       case vehicle_type
           when '60971001' then '燃油车'
           when '60971002' then '纯电'
           when '60971003' then '混动' end as 车辆类型
from c_oem_isscp_aftersvc_db.tm_claim_vehicle_warranty a
         inner join c_oem_isscp_aftersvc_db.tr_claim_warranty_vehicle b on b.foreignerKey = a.id
         inner join c_oem_isscp_aftersvc_db.tt_model_groups c on c.id = b.model_group_id
where a.policy_no ='GJBO05GH25'