-- 导入 SMART200 六接口点位并按新规则生成 source_path
-- 路径规则：
-- 1) 生产补水:      NS2|String|SMART200.SCBS.管控平台数据接口生产补水.<tag_name>
-- 2) 生产恒压:      NS2|String|SMART200.SCHY.管控平台数据接口生产恒压.<tag_name>
-- 3) 生活恒压:      NS2|String|SMART200.SHHY.管控平台数据接口生活恒压.<tag_name>
-- 4) 压滤机347:     NS2|String|SMART200.YLJ347.管控平台数据接口压滤机347.<tag_name>
-- 5) 压滤机348:     NS2|String|SMART200.YLJ348.管控平台数据接口压滤机348.<tag_name>
-- 6) 浓缩机:        NS2|String|SMART200.NSJ.管控平台数据接口浓缩机.<tag_name>
--
-- 使用方式（Windows 示例）：
-- \set scbs_file  'D:/金海泽地/金正泰/管控平台数据接口生产补水.csv'
-- \set schy_file  'D:/金海泽地/金正泰/管控平台数据接口生产恒压供水.csv'
-- \set shhy_file  'D:/金海泽地/金正泰/管控平台数据接口生活恒压供水.csv'
-- \set ylj347_file 'D:/金海泽地/金正泰/管控平台数据接口YLJ347.csv'
-- \set ylj348_file 'D:/金海泽地/金正泰/管控平台数据接口YLJ348.csv'
-- \set nsj_file 'D:/金海泽地/金正泰/管控平台数据接口浓缩机.csv'
-- \i deploy/sql/import-smart200-five-interfaces.sql
--
-- 说明：
-- - 由于各接口中存在同名 tag_name（如“1泵变频频率”），tag_code 使用 md5(interface_key|tag_name) 避免冲突；
-- - 默认 COPY 使用 UTF8，如源文件为 GBK 请先转码；
-- - 仅做点位/映射导入，不执行前端写控制。

BEGIN;

CREATE TEMP TABLE tmp_smart200_raw (
  source_key text,
  source_name text,
  source_file text,
  tag_name text,
  address text,
  data_type_raw text,
  respect_data_type text,
  client_access text,
  scan_rate_raw text,
  scaling text,
  raw_low text,
  raw_high text,
  scaled_low text,
  scaled_high text,
  scaled_data_type text,
  clamp_low text,
  clamp_high text,
  eng_units text,
  description text,
  negate_value text
) ON COMMIT DROP;

CREATE TEMP TABLE tmp_smart200_stage (
  tag_name text,
  address text,
  data_type_raw text,
  respect_data_type text,
  client_access text,
  scan_rate_raw text,
  scaling text,
  raw_low text,
  raw_high text,
  scaled_low text,
  scaled_high text,
  scaled_data_type text,
  clamp_low text,
  clamp_high text,
  eng_units text,
  description text,
  negate_value text
) ON COMMIT DROP;

-- SCBS: 生产补水
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'scbs_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'SCBS'::text,
  '管控平台数据接口生产补水'::text,
  '管控平台数据接口生产补水.csv'::text,
  *
FROM tmp_smart200_stage;

-- SCHY: 生产恒压
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'schy_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'SCHY'::text,
  '管控平台数据接口生产恒压'::text,
  '管控平台数据接口生产恒压供水.csv'::text,
  *
FROM tmp_smart200_stage;

-- SHHY: 生活恒压
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'shhy_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'SHHY'::text,
  '管控平台数据接口生活恒压'::text,
  '管控平台数据接口生活恒压供水.csv'::text,
  *
FROM tmp_smart200_stage;

-- YLJ347: 压滤机347
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'ylj347_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'YLJ347'::text,
  '管控平台数据接口压滤机347'::text,
  '管控平台数据接口YLJ347.csv'::text,
  *
FROM tmp_smart200_stage;

-- YLJ348: 压滤机348
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'ylj348_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'YLJ348'::text,
  '管控平台数据接口压滤机348'::text,
  '管控平台数据接口YLJ348.csv'::text,
  *
FROM tmp_smart200_stage;

-- NSJ: 浓缩机
TRUNCATE tmp_smart200_stage;
COPY tmp_smart200_stage
FROM :'nsj_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
INSERT INTO tmp_smart200_raw
SELECT
  'NSJ'::text,
  '管控平台数据接口浓缩机'::text,
  '管控平台数据接口浓缩机.csv'::text,
  *
FROM tmp_smart200_stage;

WITH normalized AS (
  SELECT
    source_key,
    source_name,
    source_file,
    trim(tag_name) AS tag_name,
    trim(address) AS address,
    trim(data_type_raw) AS data_type_raw,
    trim(client_access) AS client_access,
    COALESCE(NULLIF(trim(scan_rate_raw), ''), '1000')::int AS scan_rate,
    trim(eng_units) AS unit_text
  FROM tmp_smart200_raw
  WHERE trim(tag_name) <> ''
),
prepared AS (
  SELECT
    'coal.kep.smart200.' || substr(md5(source_key || '|' || tag_name), 1, 16) AS tag_code,
    tag_name,
    'KEPSERVER'::text AS source_type,
    'NS2|String|SMART200.' || source_key || '.' || source_name || '.' || tag_name AS source_path,
    source_key || '-' || lpad(row_number() OVER (PARTITION BY source_key ORDER BY tag_name)::text, 4, '0') AS device_code,
    source_name AS device_name,
    'coal-smart200'::text AS area_code,
    CASE
      WHEN lower(data_type_raw) = 'float' THEN 'DOUBLE'
      WHEN lower(data_type_raw) = 'boolean' THEN 'BOOLEAN'
      WHEN lower(data_type_raw) = 'short' THEN 'INT16'
      WHEN lower(data_type_raw) = 'dword' THEN 'INT32'
      ELSE upper(data_type_raw)
    END AS data_type,
    COALESCE(unit_text, '') AS unit,
    scan_rate,
    0.0::double precision AS deadband,
    'GOOD_ONLY'::text AS quality_rule,
    true AS enabled,
    '来源: ' || source_file || '; SMART200 六接口导入'::text AS remark
  FROM normalized
)
INSERT INTO iot_tag (
  tag_code, tag_name, source_type, source_path, device_code, device_name,
  area_code, data_type, unit, scan_rate, deadband, quality_rule, enabled, remark, created_at, updated_at
)
SELECT
  tag_code, tag_name, source_type, source_path, device_code, device_name,
  area_code, data_type, unit, scan_rate, deadband, quality_rule, enabled, remark, now(), now()
FROM prepared
ON CONFLICT (tag_code) DO UPDATE
SET
  tag_name = EXCLUDED.tag_name,
  source_type = EXCLUDED.source_type,
  source_path = EXCLUDED.source_path,
  device_code = EXCLUDED.device_code,
  device_name = EXCLUDED.device_name,
  area_code = EXCLUDED.area_code,
  data_type = EXCLUDED.data_type,
  unit = EXCLUDED.unit,
  scan_rate = EXCLUDED.scan_rate,
  deadband = EXCLUDED.deadband,
  quality_rule = EXCLUDED.quality_rule,
  enabled = EXCLUDED.enabled,
  remark = EXCLUDED.remark,
  updated_at = now();

WITH normalized AS (
  SELECT
    source_key,
    source_name,
    source_file,
    trim(tag_name) AS tag_name
  FROM tmp_smart200_raw
  WHERE trim(tag_name) <> ''
),
prepared AS (
  SELECT
    'map.kep.smart200.' || substr(md5(source_key || '|' || tag_name), 1, 16) AS mapping_id,
    'coal.kep.smart200.' || substr(md5(source_key || '|' || tag_name), 1, 16) AS tag_code,
    'smart200.signal.' || substr(md5(source_key || '|' || tag_name), 1, 16) AS business_code,
    source_name || '-' || tag_name AS business_name,
    'NS2|String|SMART200.' || source_key || '.' || source_name || '.' || tag_name AS source_path,
    'identity'::text AS transform_rule,
    true AS enabled,
    '来源: ' || source_file || '; SMART200 六接口导入'::text AS remark
  FROM normalized
)
INSERT INTO iot_tag_mapping (
  mapping_id, tag_code, business_code, business_name, source_path,
  transform_rule, enabled, remark, created_at, updated_at
)
SELECT
  mapping_id, tag_code, business_code, business_name, source_path,
  transform_rule, enabled, remark, now(), now()
FROM prepared
ON CONFLICT (mapping_id) DO UPDATE
SET
  tag_code = EXCLUDED.tag_code,
  business_code = EXCLUDED.business_code,
  business_name = EXCLUDED.business_name,
  source_path = EXCLUDED.source_path,
  transform_rule = EXCLUDED.transform_rule,
  enabled = EXCLUDED.enabled,
  remark = EXCLUDED.remark,
  updated_at = now();

COMMIT;
