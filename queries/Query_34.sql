SELECT *
FROM iuap_metadata_base.md_enumeration
WHERE ytenant_id = '0'
  AND meta_component_uri IN (
    SELECT uri
    FROM iuap_metadata_base.md_meta_component
    WHERE ytenant_id = '0'
      AND app_code = 'commonparameter'
);