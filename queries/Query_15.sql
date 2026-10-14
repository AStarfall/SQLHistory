-- ----------------------------
-- Table alter for tm_business_support
-- ----------------------------
ALTER TABLE `tm_business_support`
    DROP COLUMN `dealer_type`,
    DROP COLUMN `currency`,
    DROP COLUMN `available_limit`,
    DROP COLUMN `proof_docs`,
    DROP COLUMN `apply_type`,
    DROP COLUMN `audit_to`,
    ADD COLUMN `dealer_id` varchar(22) COMMENT '经销商',
    ADD COLUMN `region_company` varchar(256) COMMENT '地区公司',
    ADD COLUMN `used_amount` decimal(32,8) COMMENT '已用金额',
    ADD COLUMN `remaining_limit` decimal(32,8) COMMENT '剩余可用额度',
    ADD COLUMN `year` varchar(200) COMMENT '年份',
    ADD COLUMN `currencyTenantVO` varchar(36) COMMENT '币种',
    CHANGE COLUMN `dealer_code` `dealer_code`  varchar (200) COMMENT '经销商代码';
