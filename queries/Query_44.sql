SELECT
    rv.id AS report_vin_id,
    rv.vehicle AS rv_vehicle,
    v.vehicle_id,
    v.vin,
    v.product_line AS v_product_line,
    bp.business_area_id AS bp_area_id,
    bp.labor_unit_price AS bp_price,
    ROUND(COALESCE(rect.work_hours, 0) * COALESCE(bp.labor_unit_price, 0) + COALESCE(rect.other_cost, 0), 2) AS calc_amt
FROM c_oem_isscp_aftersvc_db.tt_claim_rectification_report_vin rv
         INNER JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification_report rep
                    ON rv.foreignerKey = rep.id AND rep.verifystate = 2 AND rep.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tt_claim_rectification rect
                   ON rep.rectification = rect.id AND rect.dr = 0
         LEFT JOIN c_oem_isscp_common_db.tm_dealer d
                   ON rep.dealer = d.id AND d.dr = 0
         LEFT JOIN c_oem_isscp_vehicle_db.tm_vehicle v
                   ON (rv.vehicle = v.vehicle_id OR rv.vehicle = v.model_id) AND v.dr = 0
         LEFT JOIN c_oem_isscp_aftersvc_db.tm_claim_base_parameter bp
                   ON d.dealer_code = bp.dealer_code
                       AND v.product_line = bp.business_area_id
                       AND bp.enable = 1 AND bp.dr = 0
WHERE d.dealer_code = 'GJKZ19'
  AND rep.audit_time >= '2026-07-01 00:00:00'
  AND rep.audit_time <= '2026-07-31 23:59:59'
  AND rv.dr = 0;