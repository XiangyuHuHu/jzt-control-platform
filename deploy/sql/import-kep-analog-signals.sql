-- 导入“洗煤厂模拟量信号.csv”，并统一 source_path 为最新格式：
-- NS2|String|洗煤厂PLC.洗煤厂模拟量信号.<tag_name>
--
-- 使用方式（Windows 示例）：
-- 1) 在 psql 中执行：
--    \set csv_file 'D:/微信/xwechat_files/wxid_i3dhpkolsldo12_78de/msg/file/2026-06/洗煤厂模拟量信号.csv'
--    \i deploy/sql/import-kep-analog-signals.sql
--
-- 说明：
-- - 仅依赖 CSV 的 Tag Name / Address / Data Type / Scan Rate；
-- - tag_code / mapping_id 使用 md5(Tag Name) 生成稳定编码；
-- - 同时会把库里旧的“模拟量信号1”前缀统一替换为新前缀。

BEGIN;

CREATE TEMP TABLE tmp_kep_analog_raw (
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

COPY tmp_kep_analog_raw
FROM :'csv_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

WITH normalized AS (
  SELECT
    trim(tag_name) AS tag_name,
    trim(address) AS address,
    trim(data_type_raw) AS data_type_raw,
    COALESCE(NULLIF(trim(scan_rate_raw), ''), '1000')::int AS scan_rate
  FROM tmp_kep_analog_raw
  WHERE trim(tag_name) <> ''
),
prepared AS (
  SELECT
    'coal.kep.analog.' || substr(md5(tag_name), 1, 16) AS tag_code,
    tag_name,
    'KEPSERVER'::text AS source_type,
    'NS2|String|洗煤厂PLC.洗煤厂模拟量信号.' || tag_name AS source_path,
    'ANALOG-' || lpad(row_number() OVER (ORDER BY tag_name)::text, 4, '0') AS device_code,
    tag_name AS device_name,
    'coal-wash-analog'::text AS area_code,
    CASE
      WHEN lower(data_type_raw) = 'float' THEN 'DOUBLE'
      WHEN lower(data_type_raw) = 'boolean' THEN 'BOOLEAN'
      WHEN lower(data_type_raw) = 'short' THEN 'INT16'
      WHEN lower(data_type_raw) = 'dword' THEN 'INT32'
      ELSE upper(data_type_raw)
    END AS data_type,
    COALESCE(NULLIF(trim(''), ''), '') AS unit,
    scan_rate,
    0.0::double precision AS deadband,
    'GOOD_ONLY'::text AS quality_rule,
    true AS enabled,
    '来源: 洗煤厂模拟量信号.csv; 最新路径格式'::text AS remark
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
  SELECT trim(tag_name) AS tag_name
  FROM tmp_kep_analog_raw
  WHERE trim(tag_name) <> ''
),
prepared AS (
  SELECT
    'map.kep.analog.' || substr(md5(tag_name), 1, 16) AS mapping_id,
    'coal.kep.analog.' || substr(md5(tag_name), 1, 16) AS tag_code,
    'process.analog.' || substr(md5(tag_name), 1, 16) AS business_code,
    tag_name AS business_name,
    'NS2|String|洗煤厂PLC.洗煤厂模拟量信号.' || tag_name AS source_path,
    'identity'::text AS transform_rule,
    true AS enabled,
    '来源: 洗煤厂模拟量信号.csv; 最新路径格式'::text AS remark
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

-- 兼容历史数据：统一旧前缀“模拟量信号1”为最新前缀“模拟量信号”
UPDATE iot_tag
SET
  source_path = regexp_replace(source_path, '^NS2\\|String\\|洗煤厂PLC\\.洗煤厂模拟量信号1\\.', 'NS2|String|洗煤厂PLC.洗煤厂模拟量信号.'),
  remark = replace(remark, '洗煤厂模拟量信号1.csv', '洗煤厂模拟量信号.csv'),
  updated_at = now()
WHERE source_path LIKE 'NS2|String|洗煤厂PLC.洗煤厂模拟量信号1.%'
   OR remark LIKE '%洗煤厂模拟量信号1.csv%';

UPDATE iot_tag_mapping
SET
  source_path = regexp_replace(source_path, '^NS2\\|String\\|洗煤厂PLC\\.洗煤厂模拟量信号1\\.', 'NS2|String|洗煤厂PLC.洗煤厂模拟量信号.'),
  remark = replace(remark, '洗煤厂模拟量信号1.csv', '洗煤厂模拟量信号.csv'),
  updated_at = now()
WHERE source_path LIKE 'NS2|String|洗煤厂PLC.洗煤厂模拟量信号1.%'
   OR remark LIKE '%洗煤厂模拟量信号1.csv%';

COMMIT;
