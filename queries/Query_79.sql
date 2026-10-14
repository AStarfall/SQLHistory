UPDATE tt_claim_order
SET
    dealer_code = 'GJIQ16',
    dealer_name = 'Madar Al-Mia for Trading Cars, Spare Parts and Accessories Ltd',
    dealer_id   = '2606307951835086856'
WHERE (
    dealer_id = '4641484600135348365'
    )
  AND dr = 0;


-- 1. 核验老店 GJIQ14 是否已经全部清零（期望结果：0）
SELECT COUNT(1) AS gjiq14_remaining_count
FROM tt_claim_order
WHERE (
    dealer_id = '4641484600135348365'
        OR TRIM(REPLACE(REPLACE(dealer_code, CHAR(13), ''), CHAR(10), '')) = 'GJIQ14'
    )
  AND dr = 0;

-- 2. 核验刚更新到新店 GJIQ16 的索赔单数量（期望结果：>= 233）
SELECT COUNT(1) AS gjiq16_updated_count
FROM tt_claim_order
WHERE dealer_code = 'GJIQ16'
  AND dealer_id = '2606307951835086856'
  AND dr = 0;