SELECT
    d.dealer_code,
    -- 1. 检查大区组织表是否命中多行
    (SELECT COUNT(1) FROM iuap_apdoc_basedoc.org_orgs WHERE id = d.big_org_id AND dr = 0) AS `组织表匹配行数`,
    -- 2. 检查国家档案表是否命中多行
    (SELECT COUNT(1) FROM iuap_apdoc_basedoc.bd_country WHERE id = d.country AND dr = 0) AS `国家表匹配行数`,
    -- 3. 检查币种档案表是否命中多行
    (SELECT COUNT(1) FROM iuap_apdoc_basedoc.bd_currency_tenant
     WHERE id = (
         SELECT MAX(currency) FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_dealers
         WHERE code = d.dealer_code AND dr = 0 LIMIT 1
     ) AND dr = 0) AS `币种表匹配行数`
FROM c_oem_isscp_common_db.tm_dealer d
WHERE d.dealer_code = 'GJCL10' AND d.dr = 0
LIMIT 1;