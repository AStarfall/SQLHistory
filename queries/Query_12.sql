-- ----------------------------
-- Table structure for tm_business_support
-- ----------------------------
CREATE TABLE IF NOT EXISTS `tm_business_support` (
                                                     `country` varchar(36) COMMENT '国家',
                                                     `dealer_code` varchar(22) COMMENT '经销商代码',
                                                     `dealer_name` varchar(200) COMMENT '经销商名称',
                                                     `dealer_type` varchar(200) COMMENT '经销商类型',
                                                     `support_amount` decimal(32,8) COMMENT '商务支持金额',
                                                     `effective_date` datetime COMMENT '生效日期',
                                                     `expiry_date` datetime COMMENT '失效日期',
                                                     `currency` varchar(36) COMMENT '币种',
                                                     `available_limit` decimal(32,8) COMMENT '可用额度',
                                                     `proof_docs` longtext COMMENT '证明材料',
                                                     `business_status` varchar(200) COMMENT '业务状态',
                                                     `apply_type` varchar(200) COMMENT '申请状态',
                                                     `audit_to` varchar(200) COMMENT '审核至',
                                                     `audit_time` datetime COMMENT '审批日期',
                                                     `modifier` varchar(60) COMMENT '修改人',
                                                     `auditnote` varchar(200) COMMENT '审批批语',
                                                     `id` varchar(22) NOT NULL COMMENT '主键',
                                                     `pubts` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳',
                                                     `dr` smallint(5) DEFAULT '0' COMMENT '逻辑删除',
                                                     `auditor` varchar(60) COMMENT '审批人',
                                                     `code` varchar(200) COMMENT '编码',
                                                     `verifystate` smallint(5) COMMENT '单据状态',
                                                     `procinst_id` varchar(36) COMMENT '流程实例ID',
                                                     `creator` varchar(60) COMMENT '创建人',
                                                     `ytenant_id` varchar(36) NOT NULL COMMENT '租户id',
                                                     `modify_time` datetime COMMENT '修改时间',
                                                     `create_time` datetime COMMENT '创建时间',
                                                     INDEX `I_YTENANT_ID`(`ytenant_id`),
                                                     PRIMARY KEY (`id`)
) ENGINE=InnoDB COMMENT='商务支持管理功能';
