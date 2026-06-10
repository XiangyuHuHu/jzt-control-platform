-- 仅导入“洗煤厂设备新0601.csv”中的 带电 / 挂牌 信号
-- 规则：
-- 1) 仅处理 tag_name 形如：设备名称.带电 / 设备名称.挂牌
-- 2) source_path 固定为：NS2|String|洗煤厂PLC.洗煤厂设备新.<tag_name>
-- 3) tag_name 组成：设备名称.状态
--
-- 使用方式（Windows 示例）：
-- 1. 先把 CSV 放到 PostgreSQL 服务器可访问目录（或使用 \copy）
-- 2. 在 psql 中执行：
--    \set csv_file 'D:/微信/xwechat_files/wxid_i3dhpkolsldo12_78de/msg/file/2026-06/洗煤厂设备新0601.csv'
--    \i deploy/sql/import-kep-device-new-power-signals.sql

BEGIN;

CREATE TEMP TABLE tmp_kep_device_new_raw (
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

-- 服务端 COPY（默认 UTF8）。如现场 CSV 为 GBK，请先转码后再导入。
COPY tmp_kep_device_new_raw
FROM :'csv_file'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

WITH normalized AS (
  SELECT
    trim(tag_name) AS tag_name,
    split_part(trim(tag_name), '.', 1) AS device_name,
    split_part(trim(tag_name), '.', 2) AS signal_name,
    trim(data_type_raw) AS data_type_raw,
    COALESCE(NULLIF(trim(scan_rate_raw), ''), '1000')::int AS scan_rate
  FROM tmp_kep_device_new_raw
  WHERE trim(tag_name) LIKE '%.带电'
     OR trim(tag_name) LIKE '%.挂牌'
),
prepared AS (
  SELECT
    -- 稳定、短、唯一的平台编码
    'coal.kep.signal.' || substr(md5(tag_name), 1, 16) AS tag_code,
    tag_name,
    'KEPSERVER'::text AS source_type,
    'NS2|String|洗煤厂PLC.洗煤厂设备新.' || tag_name AS source_path,
    regexp_replace(device_name, '[^0-9A-Za-z一-龥]+', '_', 'g') AS device_code,
    device_name,
    'coal-plant'::text AS area_code,
    CASE
      WHEN lower(data_type_raw) = 'boolean' THEN 'BOOLEAN'
      WHEN lower(data_type_raw) = 'short' THEN 'INT16'
      WHEN lower(data_type_raw) = 'dword' THEN 'INT32'
      ELSE upper(data_type_raw)
    END AS data_type,
    ''::text AS unit,
    scan_rate,
    0.0::double precision AS deadband,
    'GOOD_ONLY'::text AS quality_rule,
    true AS enabled,
    '导入来源: 洗煤厂设备新0601.csv，仅带电/挂牌'::text AS remark,
    signal_name
  FROM normalized
)
INSERT INTO iot_tag (
  tag_code, tag_name, source_type, source_path, device_code, device_name,
  area_code, data_type, unit, scan_rate, deadband, quality_rule, enabled, remark
)
SELECT
  tag_code, tag_name, source_type, source_path, device_code, device_name,
  area_code, data_type, unit, scan_rate, deadband, quality_rule, enabled, remark
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
    trim(tag_name) AS tag_name,
    split_part(trim(tag_name), '.', 1) AS device_name,
    split_part(trim(tag_name), '.', 2) AS signal_name
  FROM tmp_kep_device_new_raw
  WHERE trim(tag_name) LIKE '%.带电'
     OR trim(tag_name) LIKE '%.挂牌'
),
prepared AS (
  SELECT
    'map.kep.signal.' || substr(md5(tag_name), 1, 16) AS mapping_id,
    'coal.kep.signal.' || substr(md5(tag_name), 1, 16) AS tag_code,
    'coal.device_signal.' || substr(md5(tag_name), 1, 16) AS business_code,
    device_name || '-' || signal_name AS business_name,
    'NS2|String|洗煤厂PLC.洗煤厂设备新.' || tag_name AS source_path,
    ''::text AS transform_rule,
    true AS enabled,
    '导入来源: 洗煤厂设备新0601.csv，仅带电/挂牌'::text AS remark
  FROM normalized
)
INSERT INTO iot_tag_mapping (
  mapping_id, tag_code, business_code, business_name, source_path,
  transform_rule, enabled, remark
)
SELECT
  mapping_id, tag_code, business_code, business_name, source_path,
  transform_rule, enabled, remark
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

