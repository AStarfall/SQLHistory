SELECT
    id,
    code AS preauth_bill_no,
    dealer_code,
    dealer_name,
    country,
    uthorization_status,
    verifystate,
    has_generated_claim,
    claim_no,
    dr,
    create_time
FROM c_oem_isscp_aftersvc_db.tt_pre_authorization
WHERE (
    TRIM(REPLACE(REPLACE(dealer_code, CHAR(13), ''), CHAR(10), '')) = 'GJIQ14'
        OR dealer_code = '4641484600135348365'
        OR dealer_name LIKE '%Madareb al Iraq%'
    )
  AND dr = 0;






UPDATE c_oem_isscp_aftersvc_db.tt_pre_authorization
SET
    dealer_code = '2606307951835086856',
    dealer_name = 'Madar Al-Mia for Trading Cars, Spare Parts and Accessories Ltd'
WHERE id IN (
             '2630129481143025665',
             '2630684511176753153'
    );



SELECT
    id,
    code AS preauth_bill_no,
    dealer_code,
    dealer_name,
    claim_no,
    modify_time
FROM tt_pre_authorization
WHERE id IN (
             '2630129481143025665',
             '2630684511176753153'
    );