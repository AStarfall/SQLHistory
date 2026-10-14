-- ----------------------------
-- Table alter for tm_service_activity_detail
-- ----------------------------
ALTER TABLE `tm_service_activity_detail`
    ADD COLUMN `currency` varchar(200) COMMENT '币种';
-- ----------------------------
-- Table alter for tm_rectification_detail
-- ----------------------------
ALTER TABLE `tm_rectification_detail`
    ADD COLUMN `currency` varchar(200) COMMENT '币种';
-- ----------------------------
-- Table alter for tm_claim_details
-- ----------------------------
ALTER TABLE `tm_claim_details`
    ADD COLUMN `currency` varchar(200) COMMENT '币种';
