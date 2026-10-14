select id,pubts from c_oem_isscp_aftersvc_db.tt_claim_order
         where code = 'GJAE02WO260701076';

select * from c_oem_isscp_aftersvc_db.tm_claim_part where foreignerKey = (select id from c_oem_isscp_aftersvc_db.tt_claim_order
where code = 'GJAE02WO260701076');

select * from c_oem_isscp_part_db.tm_part_material where part_code ='GH52B-BJ';



select * from c_oem_isscp_aftersvc_db.tm_claim_part where install_part_id is null ;