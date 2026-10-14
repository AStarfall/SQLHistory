-- ----------------------------
-- Table alter for tm_claim_settlement
-- ----------------------------
ALTER TABLE `tm_claim_settlement`
    DROP COLUMN `approval_activity_id`,
    DROP COLUMN `approval_activity_name`,
    DROP COLUMN `approval_activity_resid`,
    DROP COLUMN `approval_comment`,
    DROP COLUMN `approval_instid`,
    DROP COLUMN `approval_result`,
    DROP COLUMN `approval_sign`,
    DROP COLUMN `approval_time`,
    DROP COLUMN `task_status`,
    DROP COLUMN `taskid`;
-- ----------------------------
-- Table structure for tm_service_activity_detail
-- ----------------------------
CREATE TABLE IF NOT EXISTS `tm_service_activity_detail` (
                                                            `main_settle_id_ref` varchar(200) COMMENT '结算主表ID',
                                                            `source_doc_id_ref` varchar(200) COMMENT '源单主键',
                                                            `svc_act_code` varchar(200) COMMENT '服务活动编号',
                                                            `svc_act_name` varchar(200) COMMENT '服务活动名称',
                                                            `act_start_date` datetime COMMENT '活动开始日期',
                                                            `act_end_date` datetime COMMENT '活动结束日期',
                                                            `labor_hours_svc` decimal(32,8) COMMENT '工时数',
                                                            `other_fee_amt_svc` decimal(32,8) COMMENT '其他费用',
                                                            `vehicle_model_code_svc` varchar(200) COMMENT '车型代码',
                                                            `vehicle_model_name_svc` varchar(200) COMMENT '车型名称',
                                                            `sub_dealer_code_svc` varchar(200) COMMENT '二级经销商编码',
                                                            `vin_svc` varchar(200) COMMENT 'VIN',
                                                            `total_amt_svc` decimal(32,8) COMMENT '总金额',
                                                            `create_time` datetime COMMENT '创建时间',
                                                            `creator` varchar(60) COMMENT '创建人',
                                                            `dr` smallint(5) DEFAULT '0' COMMENT '逻辑删除',
                                                            `foreignerKey` varchar(22) NOT NULL COMMENT '外键',
                                                            `id` varchar(22) NOT NULL COMMENT '主键',
                                                            `modifier` varchar(60) COMMENT '修改人',
                                                            `modify_time` datetime COMMENT '修改时间',
                                                            `pubts` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳',
                                                            `ytenant_id` varchar(36) NOT NULL COMMENT '租户id',
                                                            INDEX `i_foreign_index_system_auto_generate`(`ytenant_id`,`foreignerKey`),
                                                            PRIMARY KEY (`id`)
) ENGINE=InnoDB COMMENT='服务活动明细';
-- ----------------------------
-- Table structure for tm_rectification_detail
-- ----------------------------
CREATE TABLE IF NOT EXISTS `tm_rectification_detail` (
                                                         `main_settle_id_ref` varchar(200) COMMENT '结算主表ID',
                                                         `source_doc_id_ref` varchar(200) COMMENT '源单主键',
                                                         `proact_rect_code` varchar(200) COMMENT '主动整改项目编号',
                                                         `proact_rect_name` varchar(200) COMMENT '主动整改项目名称',
                                                         `rect_start_date` datetime COMMENT '主动整改开始日期',
                                                         `rect_end_date` datetime COMMENT '主动整改结束日期',
                                                         `labor_hours_rect` decimal(32,8) COMMENT '工时数',
                                                         `other_fee_amt_rect` decimal(32,8) COMMENT '其他费用',
                                                         `vehicle_model_code_rect` varchar(200) COMMENT '车型代码',
                                                         `vehicle_model_name_rect` varchar(200) COMMENT '车型名称',
                                                         `sub_dealer_code_rect` varchar(200) COMMENT '二级经销商编码',
                                                         `vin_rect` varchar(200) COMMENT 'VIN',
                                                         `total_amt_rect` decimal(32,8) COMMENT '总金额',
                                                         `create_time` datetime COMMENT '创建时间',
                                                         `creator` varchar(60) COMMENT '创建人',
                                                         `dr` smallint(5) DEFAULT '0' COMMENT '逻辑删除',
                                                         `foreignerKey` varchar(22) NOT NULL COMMENT '外键',
                                                         `id` varchar(22) NOT NULL COMMENT '主键',
                                                         `modifier` varchar(60) COMMENT '修改人',
                                                         `modify_time` datetime COMMENT '修改时间',
                                                         `pubts` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳',
                                                         `ytenant_id` varchar(36) NOT NULL COMMENT '租户id',
                                                         INDEX `i_foreign_index_system_auto_generate`(`ytenant_id`,`foreignerKey`),
                                                         PRIMARY KEY (`id`)
) ENGINE=InnoDB COMMENT='主动整改明细';
-- ----------------------------
-- Table structure for tm_claim_details
-- ----------------------------
CREATE TABLE IF NOT EXISTS `tm_claim_details` (
                                                  `claim_code` varchar(200) COMMENT '索赔单号',
                                                  `claim_type_enum` varchar(200) COMMENT '索赔类型',
                                                  `sales_date` datetime COMMENT '销售日期',
                                                  `fault_date` datetime COMMENT '故障日期',
                                                  `repair_finish_date` datetime COMMENT '维修完成日期',
                                                  `claim_submit_date` datetime COMMENT '索赔提交日期',
                                                  `claim_final_audit_date` datetime COMMENT '索赔终审完成日期',
                                                  `vehicle_model_code_claim` varchar(200) COMMENT '车型代码',
                                                  `vehicle_model_name_claim` varchar(200) COMMENT '车型名称',
                                                  `sub_dealer_code_claim` varchar(200) COMMENT '二级经销商编码',
                                                  `vin_claim` varchar(200) COMMENT 'VIN',
                                                  `fault_mileage` decimal(32,8) COMMENT '故障里程',
                                                  `main_fault_part_code` varchar(200) COMMENT '主故障件代码',
                                                  `labor_amt_claim` decimal(32,8) COMMENT '工时金额',
                                                  `part_amt` decimal(32,8) COMMENT '配件金额',
                                                  `other_fee_amt_claim` decimal(32,8) COMMENT '其他费用金额',
                                                  `part_mgt_amt` decimal(32,8) COMMENT '配件管理金额',
                                                  `total_amt_claim` decimal(32,8) COMMENT '总金额',
                                                  `create_time` datetime COMMENT '创建时间',
                                                  `creator` varchar(60) COMMENT '创建人',
                                                  `dr` smallint(5) DEFAULT '0' COMMENT '逻辑删除',
                                                  `foreignerKey` varchar(22) NOT NULL COMMENT '外键',
                                                  `id` varchar(22) NOT NULL COMMENT '主键',
                                                  `modifier` varchar(60) COMMENT '修改人',
                                                  `modify_time` datetime COMMENT '修改时间',
                                                  `pubts` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳',
                                                  `ytenant_id` varchar(36) NOT NULL COMMENT '租户id',
                                                  INDEX `i_foreign_index_system_auto_generate`(`ytenant_id`,`foreignerKey`),
                                                  PRIMARY KEY (`id`)
) ENGINE=InnoDB COMMENT='索赔单明细';
