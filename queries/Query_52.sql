ALTER TABLE `tm_claim_settlement`
    ADD COLUMN `region_company` varchar(200) COMMENT '地区公司',
    ADD COLUMN `country` varchar(200) COMMENT '国家',
    ADD COLUMN `voucher_no` varchar(200) COMMENT 'SAP凭证号';