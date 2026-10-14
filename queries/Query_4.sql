INSERT INTO c_scm_yy_ys01_db.ysbuy_offer (ORG_ID, APPLY_DATE, AUDITNOTE, PRODUCT_CODE, DR, BUY_OFFER_SUM, CREATOR,
                                          SOURCECHILD_ID, QUALITY_REQ, CREATE_TIME, ID, PROCINST_ID, MEMO, MODIFIER,
                                          YTENANT_ID, SOURCEBUSIOBJ, SOURCEGRAND_ID, IS_IMPORTANT_BUY_OFFER, APPLYOR,
                                          BIZFLOWNAME, APPLY_AMOUNT, CAS, SOURCECODE, BIZFLOW_ID, BUSTYPE, MODIFY_TIME,
                                          AUDITOR, FIRSTBUSIOBJ, ORG, BIZFLOWINSTANCE_ID, BUY_OFFER_MEMO,
                                          PURITY_QUALITY_REQUIREMENT, VERIFYSTATE, SRM_OFFER_NO, BUY_OFFER_NO, REMARK,
                                          AUDIT_TIME, FIRSTCHILD_ID, SRM_OFFER_ID, SOURCE_ID, UNITID, PRODUCT_ID,
                                          APPLY_DEPT, PRODUCT_SPEC, PRODUCT_TYPE, FIRSTCODE, "code", FIRST_ID,
                                          BUY_OFFER_TYPE, BIZFLOW_MAKEBILLCODE)
VALUES ('2321064150210445321', '2025-12-17', null, null, 0, '1', 'ec4326d0-d490-4d5a-9105-260b51fd16d0', null,
        null, '2025-12-17 16:17:22', '2428885120582680583', null, null, null, 'q3eowjxq', null, null, null,
        '2367983524032544770', null, null, null, null, null, null, null, null, null, '666666', null, null, null, 0,
        null, null, null, null, null, null, null, null, '2321188137338404882', null, null, null, null, '000001', null,
        null, null)


ALTER TABLE ysbuy_offer ADD COLUMN buy_offer_result VARCHAR(200);
COMMENT ON column ysbuy_offer.buy_offer_result IS '询价结果';
;
DO $body$
    BEGIN
        IF EXISTS (SELECT 1 FROM pg_catalog.pg_class c left join pg_catalog.pg_namespace n on c.relnamespace = n.oid WHERE n.nspname = lower(current_schema()) AND c.relname = lower('ysbuy_offer_detail') AND c.relkind = 'r') THEN
            DROP TRIGGER IF EXISTS ysbuy_offer_detail_validity_period on ysbuy_offer_detail;
        END IF;
    END;
$body$;
ALTER table ysbuy_offer_detail ALTER COLUMN validity_period DROP DEFAULT, ALTER COLUMN validity_period TYPE VARCHAR(200) USING validity_period::VARCHAR(200), ALTER COLUMN validity_period DROP NOT NULL;
COMMENT ON column ysbuy_offer_detail.validity_period IS '报价有效期';
;






















SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'ysbuy_offer'
  AND character_maximum_length <= 10;