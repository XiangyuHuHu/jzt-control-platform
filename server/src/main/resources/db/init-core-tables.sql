CREATE TABLE IF NOT EXISTS work_order (
    id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(64),
    title VARCHAR(255),
    description TEXT,
    type VARCHAR(64),
    priority VARCHAR(32),
    status VARCHAR(32),
    device_id BIGINT,
    assignee_id BIGINT,
    creator_id BIGINT,
    planned_start_time TIMESTAMP,
    planned_end_time TIMESTAMP,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    result TEXT,
    remarks TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_work_order_status ON work_order(status);
CREATE INDEX IF NOT EXISTS idx_work_order_created_at ON work_order(created_at);

CREATE TABLE IF NOT EXISTS energy_consumption (
    id BIGSERIAL PRIMARY KEY,
    record_date DATE,
    shift VARCHAR(32),
    energy_type VARCHAR(64),
    consumption DOUBLE PRECISION,
    unit VARCHAR(32),
    unit_price DOUBLE PRECISION,
    cost DOUBLE PRECISION,
    related_output DOUBLE PRECISION,
    unit_consumption DOUBLE PRECISION,
    meter_reading DOUBLE PRECISION,
    meter_no VARCHAR(64),
    recorder VARCHAR(64),
    data_source VARCHAR(32),
    remark TEXT,
    create_by VARCHAR(64),
    create_time TIMESTAMP,
    update_by VARCHAR(64),
    update_time TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_energy_consumption_record_date ON energy_consumption(record_date);

CREATE TABLE IF NOT EXISTS dispatch_record (
    id BIGSERIAL PRIMARY KEY,
    record_no VARCHAR(64) NOT NULL,
    shift VARCHAR(32),
    record_type VARCHAR(64),
    content TEXT,
    handling TEXT,
    recorder VARCHAR(64),
    record_time TIMESTAMP,
    handler VARCHAR(64),
    handle_time TIMESTAMP,
    status VARCHAR(32),
    priority VARCHAR(32),
    attachment_url TEXT,
    create_by VARCHAR(64),
    create_time TIMESTAMP DEFAULT now(),
    update_by VARCHAR(64),
    update_time TIMESTAMP DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_dispatch_record_record_no ON dispatch_record(record_no);
CREATE INDEX IF NOT EXISTS idx_dispatch_record_record_time ON dispatch_record(record_time);
CREATE INDEX IF NOT EXISTS idx_dispatch_record_status ON dispatch_record(status);

CREATE TABLE IF NOT EXISTS storage_transport (
    id BIGSERIAL PRIMARY KEY,
    record_type VARCHAR(64) NOT NULL,
    record_no VARCHAR(64) NOT NULL,
    coal_type VARCHAR(128),
    quantity DOUBLE PRECISION,
    record_time TIMESTAMP,
    source_or_dest VARCHAR(255),
    transport_mode VARCHAR(32),
    vehicle_no VARCHAR(64),
    loading_station VARCHAR(128),
    train_no VARCHAR(64),
    carriage_count INTEGER,
    customer_name VARCHAR(128),
    contract_no VARCHAR(128),
    quality_index TEXT,
    operator VARCHAR(64),
    status VARCHAR(32),
    remark TEXT,
    create_by VARCHAR(64),
    create_time TIMESTAMP DEFAULT now(),
    update_by VARCHAR(64),
    update_time TIMESTAMP DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_storage_transport_record_no ON storage_transport(record_no);
CREATE INDEX IF NOT EXISTS idx_storage_transport_record_time ON storage_transport(record_time);
CREATE INDEX IF NOT EXISTS idx_storage_transport_record_type ON storage_transport(record_type);

INSERT INTO work_order (
    order_no, title, description, type, priority, status,
    device_id, assignee_id, creator_id,
    planned_start_time, planned_end_time, created_at, updated_at
)
SELECT *
FROM (
    VALUES
        ('WO-20260413-001', '主破碎机巡检', '例行巡检主破碎机振动与温度', '巡检', '中', '待处理', 1, 1001, 1000, now() - INTERVAL '2 hour', now() + INTERVAL '4 hour', now(), now()),
        ('WO-20260413-002', '皮带机润滑维护', '对给料皮带执行润滑维护', '保养', '中', '处理中', 2, 1002, 1000, now() - INTERVAL '6 hour', now() + INTERVAL '2 hour', now(), now()),
        ('WO-20260413-003', '筛分机异常复核', '复核筛分机报警并形成记录', '维修', '高', '已完成', 3, 1003, 1000, now() - INTERVAL '1 day', now() - INTERVAL '20 hour', now() - INTERVAL '1 day', now())
) AS seed(
    order_no, title, description, type, priority, status,
    device_id, assignee_id, creator_id,
    planned_start_time, planned_end_time, created_at, updated_at
)
WHERE NOT EXISTS (SELECT 1 FROM work_order LIMIT 1);

INSERT INTO energy_consumption (
    record_date, shift, energy_type, consumption, unit, unit_price, cost,
    related_output, unit_consumption, meter_reading, meter_no, recorder,
    data_source, remark, create_by, create_time, update_by, update_time
)
SELECT *
FROM (
    VALUES
        (CURRENT_DATE, 'DAY', 'ELECTRICITY', 1280.5, 'kWh', 0.72, 921.96, 560.0, 2.2866, 102345.2, 'ELEC-M-01', '系统', 'AUTO', '测试初始化数据', 'system', now(), 'system', now()),
        (CURRENT_DATE - 1, 'NIGHT', 'ELECTRICITY', 1198.0, 'kWh', 0.72, 862.56, 540.0, 2.2185, 101064.7, 'ELEC-M-01', '系统', 'AUTO', '测试初始化数据', 'system', now(), 'system', now()),
        (CURRENT_DATE - 2, 'DAY', 'WATER', 356.0, 't', 3.10, 1103.60, 525.0, 0.6781, 55672.4, 'WATER-M-02', '系统', 'AUTO', '测试初始化数据', 'system', now(), 'system', now())
) AS seed(
    record_date, shift, energy_type, consumption, unit, unit_price, cost,
    related_output, unit_consumption, meter_reading, meter_no, recorder,
    data_source, remark, create_by, create_time, update_by, update_time
)
WHERE NOT EXISTS (SELECT 1 FROM energy_consumption LIMIT 1);
