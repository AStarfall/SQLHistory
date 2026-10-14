SELECT
    *
FROM tm_vehicle
WHERE dr = 0
  AND material_code = 'Y41U0007K4812010'






SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y60A000000010T01' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y6NC20000005C212' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y6YN0-200302-1PE' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y802100000000002' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y8021020N08E0010' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y802300000000004' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y802300000000005' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y802300000000006' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y8023000M0880060' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y8023000M08D0060' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y8023000M08E0060' GROUP BY material_code UNION
SELECT     material_code, COUNT(DISTINCT vin) AS vehicle_qty FROM tm_vehicle WHERE dr = 0 AND material_code IS NOT NULL AND material_code = 'Y81FZ00000030501' GROUP BY material_code