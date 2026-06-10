export type CoalNavItem = {
  label: string
  path: string
  desc?: string
}

export const coalPrimaryEntries: CoalNavItem[] = [
  { label: '综合看板', path: '/jzt/coal/dashboard', desc: '总览、告警、关键指标与运行态势' },
  { label: '生产调度', path: '/jzt/coal/production', desc: '生产流程、班组交接、调度记录与异常处置整合' },
  { label: '设备管理', path: '/jzt/coal/equipment', desc: '设备状态、台账、故障分析、电机和变频器数据' },
  { label: '煤质管理', path: '/jzt/coal/quality', desc: '离线化验、趋势分析、质量预警与看板' },
]

export const coalTopicEntries: CoalNavItem[] = [
  { label: '储装管理', path: '/jzt/coal/storage', desc: '入厂、装车、销售与库存监控' },
  { label: '能耗管理', path: '/jzt/coal/energy', desc: '耗电量录入、水耗、药剂、油脂和水平衡' },
  { label: '协同管理', path: '/jzt/coal/collaboration', desc: '待办事项、跨部门工单、闭环进度与值班协同' },
  { label: '智能决策', path: '/jzt/coal/decision', desc: '产品方案、质量预测、设备故障分析与优化建议' },
  { label: '巡检监测', path: '/jzt/coal/monitor', desc: '人员、巡检、视频识别与安全联动' },
  { label: '系统设置', path: '/jzt/coal/settings', desc: '用户、角色、点位、接口与系统参数' },
]

export const coalPlatformEntries: CoalNavItem[] = [
  { label: '数据治理', path: '/jzt/coal/data-governance', desc: '元数据、数据质量与数据模型管理' },
  { label: '数据集成', path: '/jzt/coal/data-integration', desc: 'Kepserver、ETL、同步任务与共享接口' },
  { label: '数据接入', path: '/jzt/coal/data-access', desc: '数据源、接口清单、字段映射与接入拓扑' },
]

export const coalProductionExtensionEntries: CoalNavItem[] = [
  { label: '生产运行统计', path: '/jzt/coal/production-operation', desc: '生产数据概览、运行统计、完成率和运行评价' },
  { label: '工艺流程专项', path: '/jzt/coal/process-flow', desc: '流程节点状态、负荷告警与处置建议' },
  { label: '生产技术检查', path: '/jzt/coal/process-check', desc: '生产记录、实验记录、工艺与材料消耗跟踪' },
  { label: '原材料跟踪', path: '/jzt/coal/material-tracking', desc: '原材料入库、出库、领用与库存追踪' },
  { label: '生产计划统计', path: '/jzt/coal/planning', desc: '年度、月度、日班计划与完成率跟踪' },
  { label: '调度日志细分', path: '/jzt/coal/dispatch-log', desc: '启停车、停送电、当班记录和调度日志明细' },
  { label: '介质消耗', path: '/jzt/coal/medium', desc: '介耗统计、异常提醒与班报月报' },
  { label: '药剂消耗', path: '/jzt/coal/reagent', desc: '药剂用量、单耗对比与异常提醒' },
  { label: '水耗与水平衡', path: '/jzt/coal/water', desc: '补水汇总、循环水、煤泥水与水平衡分析' },
  { label: '电耗台账', path: '/jzt/coal/power', desc: '耗电量录入、配电状态、电耗台账与报警分析' },
  { label: '油脂消耗', path: '/jzt/coal/grease', desc: '油脂领用、班报月报与异常追踪' },
  { label: '用风量', path: '/jzt/coal/air', desc: '流量采集、单位风耗与考核依据' },
  { label: '排班管理', path: '/jzt/coal/shift-schedule', desc: '二班倒、三班倒、生产班与检修班配置' },
]

export const coalExtensionEntries: CoalNavItem[] = [
  { label: '建模分析专题', path: '/jzt/coal/model-analysis', desc: '质量稳定控制、质量预测、趋势分析和产品仓质量分析' },
  { label: '安全与健康', path: '/jzt/coal/safety-health', desc: '人员安全、健康指标与风险闭环' },
  { label: '煤质离线录入', path: '/jzt/coal/quality-entry', desc: '化验数据录入、复核、统计和趋势分析' },
  { label: '质量报表', path: '/jzt/coal/quality-report', desc: '日报、周报、月报与质量统计报表' },
  { label: '机电设备管理', path: '/jzt/coal/mechanical', desc: '设备档案、运行数据、二维码与闭环处置' },
  { label: '销售统计', path: '/jzt/coal/sales', desc: '按日期、产品、客户和运输方式统计销售质量' },
  { label: '智能密控', path: '/jzt/coal/smart-density', desc: '密度预测、分流补水建议与密控模型调用' },
  { label: '智能加药', path: '/jzt/coal/smart-reagent', desc: '加药泵频率预测、备用泵建议与加药模型调用' },
]

export const coalExtensionEntriesForHome = [...coalProductionExtensionEntries, ...coalExtensionEntries]

export const coalQuickNav: CoalNavItem[] = [
  { label: '首页', path: '/jzt/coal' },
  { label: '生产运行', path: '/jzt/coal/production' },
  { label: '设备运维', path: '/jzt/coal/equipment' },
  { label: '质量能耗', path: '/jzt/coal/quality' },
  { label: '智能优化', path: '/jzt/coal/decision' },
  { label: '平台系统', path: '/jzt/coal/settings' },
]

export const coalCockpitTopNav: CoalNavItem[] = [
  { label: '综合看板', path: '/jzt/coal/dashboard' },
  { label: '设备管理', path: '/jzt/coal/equipment' },
  { label: '煤质管理', path: '/jzt/coal/quality' },
  { label: '生产调度', path: '/jzt/coal/production' },
]

export const coalCockpitSideNav: CoalNavItem[] = [
  { label: '总览', path: '/jzt/coal/dashboard' },
  { label: '设备状态', path: '/jzt/coal/equipment' },
  { label: '调度告警', path: '/jzt/coal/production' },
  { label: '生产目标', path: '/jzt/coal/planning' },
  { label: '巡检维保', path: '/jzt/coal/monitor' },
]
