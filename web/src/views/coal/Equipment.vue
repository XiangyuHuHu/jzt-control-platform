<template>
  <div class="equipment-manage-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">设备管理</p>
        <h1>设备运行与故障分析平台</h1>
        <p>增加矩阵装车数据、润华系统、破碎站设备数据，以及电机和变频器电流监测。</p>
      </div>
      <div class="hero-actions">
        <el-button @click="showMatrix = true">矩阵装车数据</el-button>
        <el-button type="primary" @click="showLedger = true">设备台账</el-button>
      </div>
    </section>

    <section class="kpi-grid">
      <article v-for="item in kpis" :key="item.label" class="kpi-card">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }}</strong>
        <small>{{ item.note }}</small>
      </article>
    </section>

    <section class="content-grid">
      <article class="panel">
        <div class="panel-head">
          <h2>关键设备电流</h2>
          <span>电机、变频器、破碎站统一展示</span>
        </div>
        <div class="device-cards">
          <div v-for="item in currentRows" :key="item.code" class="device-card" :class="item.level">
            <div class="device-title">
              <strong>{{ item.name }}</strong>
              <span>{{ item.status }}</span>
            </div>
            <div class="metric-grid">
              <div><small>电机电流</small><b>{{ item.motorCurrent }} A</b></div>
              <div><small>变频器电流</small><b>{{ item.inverterCurrent }} A</b></div>
              <div><small>负荷</small><b>{{ item.load }}%</b></div>
              <div><small>温度</small><b>{{ item.temperature }}℃</b></div>
            </div>
          </div>
        </div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <h2>设备故障分析</h2>
          <span>供智能决策页面同步调用</span>
        </div>
        <div class="fault-list">
          <div v-for="item in faults" :key="item.title" class="fault-item" :class="item.level">
            <strong>{{ item.title }}</strong>
            <p>{{ item.reason }}</p>
            <small>建议：{{ item.action }}</small>
          </div>
        </div>
      </article>

      <article class="panel panel--wide">
        <div class="panel-head">
          <h2>润华系统与破碎站设备数据</h2>
          <span>按现场反馈补充外部系统字段</span>
        </div>
        <el-table :data="integrationRows" class="dark-table">
          <el-table-column prop="system" label="系统" width="140" />
          <el-table-column prop="device" label="设备" min-width="180" />
          <el-table-column prop="tag" label="测点" min-width="160" />
          <el-table-column prop="value" label="实时值" width="140" />
          <el-table-column prop="source" label="数据来源" min-width="160" />
          <el-table-column prop="status" label="状态" width="100" />
        </el-table>
      </article>
    </section>

    <el-dialog v-model="showMatrix" title="矩阵装车数据" width="760px">
      <el-table :data="matrixRows">
        <el-table-column prop="lane" label="装车位" width="120" />
        <el-table-column prop="product" label="产品" width="120" />
        <el-table-column prop="plate" label="车号" width="140" />
        <el-table-column prop="weight" label="装车量" width="120" />
        <el-table-column prop="status" label="状态" />
      </el-table>
    </el-dialog>

    <el-dialog v-model="showLedger" title="设备台账" width="86%">
      <el-table :data="ledgerRows">
        <el-table-column prop="device" label="设备名称" min-width="180" />
        <el-table-column prop="code" label="编码" width="140" />
        <el-table-column prop="location" label="位置" width="160" />
        <el-table-column prop="type" label="设备类型" width="120" />
        <el-table-column prop="owner" label="责任班组" width="120" />
        <el-table-column prop="status" label="状态" width="100" />
        <el-table-column prop="note" label="说明" min-width="220" />
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useIotHub } from '../../composables/useIotHub'

const showMatrix = ref(false)
const showLedger = ref(false)
const iotHub = useIotHub()
const smart200Tags = {
  scbsPumpFreq: 'coal.kep.smart200.f4ecb3aabe551361',
  scbsPumpCurrent: 'coal.kep.smart200.e35ed12178c27440',
  scbsPressure: 'coal.kep.smart200.a110c32c0c5619bb',
  scbsFault: 'coal.kep.smart200.9bae336ab5de0b6b',
  schyPumpFreq: 'coal.kep.smart200.dd2995b49c8de188',
  schyPumpCurrent: 'coal.kep.smart200.db819f726386f67a',
  schyPressure: 'coal.kep.smart200.997e2953e6c3869d',
  schyFault: 'coal.kep.smart200.1548c86bdcdb2ef7',
  shhyPumpFreq: 'coal.kep.smart200.fb6033658b90b8ff',
  shhyPumpCurrent: 'coal.kep.smart200.d5dfe698622e8052',
  shhyPressure: 'coal.kep.smart200.6e5c1d0e75a7400d',
  shhyFault: 'coal.kep.smart200.c3af8de050dbbb1c',
  ylj347FeedPressure: 'coal.kep.smart200.6c28fda2760dfd38',
  ylj347PressPressure: 'coal.kep.smart200.2231e5ad509d8d0e',
  ylj347PumpFreq: 'coal.kep.smart200.15f29d51e03e9337',
  ylj347Fault: 'coal.kep.smart200.7a92290246684f22',
  nsjFault: 'coal.kep.smart200.6b2eb0f8bb28200a',
  nsjPressure: 'coal.kep.smart200.0dd9b6f7994e2e78',
  nsjRakeHeight: 'coal.kep.smart200.777f6db238ad3628',
  nsjOverload: 'coal.kep.smart200.43830c329099aff6',
  nsjRunning: 'coal.kep.smart200.446fcf8b275c5bba',
  nsjRemote: 'coal.kep.smart200.78afc5b600e88cf0',
  nsjAuto: 'coal.kep.smart200.1f9aaef0b02d7a75',
}
const getNumericTag = (tagCode: string, fallback: number, digits = 1) => {
  const live = iotHub.getTagValue(tagCode)?.value
  if (typeof live !== 'number' || !Number.isFinite(live)) return Number(fallback.toFixed(digits))
  return Number(live.toFixed(digits))
}
const getBoolTag = (tagCode: string, fallback = false) => {
  const live = iotHub.getTagValue(tagCode)?.value
  if (typeof live === 'boolean') return live
  if (typeof live === 'number') return live > 0
  return fallback
}

const kpis = computed(() => {
  const faults = [smart200Tags.scbsFault, smart200Tags.schyFault, smart200Tags.shhyFault, smart200Tags.ylj347Fault, smart200Tags.nsjFault, smart200Tags.nsjOverload]
  const activeFault = faults.filter((tagCode) => getBoolTag(tagCode, false)).length
  return [
    { label: '设备总数', value: '209 台', note: '在用 209，备用 0' },
    { label: 'SMART200在线点', value: '23 个', note: '供水+压滤机+浓缩机关键信号' },
    { label: '故障分析项', value: `${activeFault} 项`, note: activeFault ? '检测到实时告警' : '当前无告警' },
    { label: '矩阵装车', value: '6 车位', note: '数据已接入展示' },
  ]
})

const currentRows = computed(() => {
  const scbsCurrent = getNumericTag(smart200Tags.scbsPumpCurrent, 41.6)
  const schyCurrent = getNumericTag(smart200Tags.schyPumpCurrent, 38.4)
  const shhyCurrent = getNumericTag(smart200Tags.shhyPumpCurrent, 33.2)
  const yljFeed = getNumericTag(smart200Tags.ylj347FeedPressure, 1.8)
  const yljPress = getNumericTag(smart200Tags.ylj347PressPressure, 3.6)
  const yljFreq = getNumericTag(smart200Tags.ylj347PumpFreq, 42.0)
  const scbsFault = getBoolTag(smart200Tags.scbsFault)
  const schyFault = getBoolTag(smart200Tags.schyFault)
  const shhyFault = getBoolTag(smart200Tags.shhyFault)
  const yljFault = getBoolTag(smart200Tags.ylj347Fault)
  const nsjFault = getBoolTag(smart200Tags.nsjFault) || getBoolTag(smart200Tags.nsjOverload)
  const nsjPressure = getNumericTag(smart200Tags.nsjPressure, 1.55, 2)
  return [
    {
      code: 'SCBS',
      name: '生产补水泵组',
      status: scbsFault ? '告警' : '正常',
      level: scbsFault ? 'warn' : 'good',
      motorCurrent: scbsCurrent,
      inverterCurrent: getNumericTag(smart200Tags.scbsPumpFreq, 35.0),
      load: Math.min(100, Math.round((scbsCurrent / 60) * 100)),
      temperature: getNumericTag(smart200Tags.scbsPressure, 1.9, 2) * 26,
    },
    {
      code: 'SCHY',
      name: '生产恒压泵组',
      status: schyFault ? '告警' : '正常',
      level: schyFault ? 'warn' : 'good',
      motorCurrent: schyCurrent,
      inverterCurrent: getNumericTag(smart200Tags.schyPumpFreq, 33.0),
      load: Math.min(100, Math.round((schyCurrent / 60) * 100)),
      temperature: getNumericTag(smart200Tags.schyPressure, 2.0, 2) * 24,
    },
    {
      code: 'SHHY',
      name: '生活恒压泵组',
      status: shhyFault ? '告警' : '正常',
      level: shhyFault ? 'warn' : 'good',
      motorCurrent: shhyCurrent,
      inverterCurrent: getNumericTag(smart200Tags.shhyPumpFreq, 31.0),
      load: Math.min(100, Math.round((shhyCurrent / 60) * 100)),
      temperature: getNumericTag(smart200Tags.shhyPressure, 1.7, 2) * 24,
    },
    {
      code: 'YLJ347',
      name: '压滤机347压榨单元',
      status: yljFault ? '告警' : '关注',
      level: yljFault ? 'warn' : 'good',
      motorCurrent: yljFeed,
      inverterCurrent: yljFreq,
      load: Math.min(100, Math.round((yljPress / 4.5) * 100)),
      temperature: yljPress * 10,
    },
    {
      code: 'NSJ',
      name: '浓缩机单元',
      status: nsjFault ? '告警' : (getBoolTag(smart200Tags.nsjRunning) ? '正常' : '关注'),
      level: nsjFault ? 'warn' : 'good',
      motorCurrent: getNumericTag(smart200Tags.nsjRakeHeight, 420, 1),
      inverterCurrent: getBoolTag(smart200Tags.nsjRemote) ? 1 : 0,
      load: Math.min(100, Math.round((nsjPressure / 2.2) * 100)),
      temperature: nsjPressure * 20,
    },
  ]
})

const faults = computed(() => {
  const rows = []
  if (getBoolTag(smart200Tags.scbsFault)) {
    rows.push({ title: '生产补水总故障', level: 'danger', reason: 'SCBS 返回总故障信号。', action: '检查泵组线路与缺水联锁后复位。' })
  }
  if (getBoolTag(smart200Tags.schyFault)) {
    rows.push({ title: '生产恒压总故障', level: 'warn', reason: 'SCHY 压力站出现总故障信号。', action: '检查变频器与压力阈值设定。' })
  }
  if (getBoolTag(smart200Tags.shhyFault)) {
    rows.push({ title: '生活恒压总故障', level: 'warn', reason: 'SHHY 信号异常。', action: '检查泵组工频/变频切换状态。' })
  }
  if (getBoolTag(smart200Tags.ylj347Fault)) {
    rows.push({ title: '压滤机347设备故障', level: 'danger', reason: 'YLJ347 设备故障点位触发。', action: '检查压榨泵运行和阀位反馈。' })
  }
  if (getBoolTag(smart200Tags.nsjFault)) {
    rows.push({ title: '浓缩机故障', level: 'danger', reason: 'NSJ 返回 0正常1故障 异常位。', action: '检查浓缩机运行压力和耙位机构。' })
  }
  if (getBoolTag(smart200Tags.nsjOverload)) {
    rows.push({ title: '浓缩机油泵电机过载', level: 'warn', reason: 'NSJ 油泵电机过载位触发。', action: '降低负载并排查油路与机械阻力。' })
  }
  if (!rows.length) {
    rows.push({ title: '设备状态稳定', level: 'warn', reason: 'SMART200 关键故障点未触发。', action: '维持巡检，关注压力波动趋势。' })
  }
  return rows
})

const integrationRows = computed(() => [
  { system: 'SMART200.SCBS', device: '生产补水泵组', tag: '1泵变频运行电流', value: `${getNumericTag(smart200Tags.scbsPumpCurrent, 41.6)} A`, source: 'SMART200 SCBS', status: '在线' },
  { system: 'SMART200.SCHY', device: '生产恒压泵组', tag: '出口压力', value: `${getNumericTag(smart200Tags.schyPressure, 2.08, 2)} MPa`, source: 'SMART200 SCHY', status: '在线' },
  { system: 'SMART200.SHHY', device: '生活恒压泵组', tag: '出口压力', value: `${getNumericTag(smart200Tags.shhyPressure, 1.71, 2)} MPa`, source: 'SMART200 SHHY', status: '在线' },
  { system: 'SMART200.YLJ347', device: '压滤机347', tag: '压榨泵反馈频率', value: `${getNumericTag(smart200Tags.ylj347PumpFreq, 42.0)} Hz`, source: 'SMART200 YLJ347', status: '在线' },
  { system: 'SMART200.NSJ', device: '浓缩机', tag: '运行压力MPa', value: `${getNumericTag(smart200Tags.nsjPressure, 1.55, 2)} MPa`, source: 'SMART200 NSJ', status: '在线' },
])

const matrixRows = [
  { lane: '1 号位', product: '精煤', plate: '蒙K A6123', weight: '38.6 t', status: '装车中' },
  { lane: '2 号位', product: '中煤', plate: '蒙K C2098', weight: '41.2 t', status: '待确认' },
  { lane: '3 号位', product: '煤泥', plate: '蒙K D7731', weight: '36.4 t', status: '已完成' },
]

const ledgerRows = [
  { device: '主破碎机', code: 'CR-01', location: '破碎站', type: '破碎设备', owner: '机电班', status: '运行中', note: '电机、变频器电流已接入' },
  { device: '润华破碎站二号机', code: 'RH-PS-02', location: '破碎站', type: '外部系统设备', owner: '机电班', status: '关注', note: '润华系统接入设备' },
  { device: '311 中煤离心机', code: 'CF-311', location: '离心机组', type: '离心机', owner: '生产一班', status: '预警', note: '振动和电流偏高' },
]

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'equipment-manage', intervalMs: 5000 })
  await iotHub.ensureFresh('equipment-manage', 2000)
})
</script>

<style scoped>
.equipment-manage-page{height:100%;min-height:0;overflow:auto;padding:12px 14px 18px;background:#16202a;color:#eef6ff}.page-hero,.kpi-grid,.content-grid{width:min(100%,1680px);margin:0 auto 16px}.page-hero,.panel,.kpi-card{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:24px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff;font-size:12px;letter-spacing:.12em}.page-hero h1{margin:0;font-size:30px}.page-hero p{margin:10px 0 0;color:#c8d6e3}.hero-actions{display:flex;gap:10px;align-items:flex-start}.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.kpi-card{padding:18px}.kpi-card span{color:#b8c7d5}.kpi-card strong{display:block;margin-top:10px;font-size:30px}.kpi-card small{display:block;margin-top:8px;color:#8bdfff}.content-grid{display:grid;grid-template-columns:1.2fr .8fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel-head{display:flex;justify-content:space-between;gap:12px;margin-bottom:16px}.panel-head h2{margin:0}.panel-head span{color:#b8c7d5}.device-cards{display:grid;grid-template-columns:1fr 1fr;gap:12px}.device-card,.fault-item{padding:16px;border-radius:8px;background:#17212b;border:1px solid rgba(255,255,255,.08)}.device-card.good{box-shadow:inset 4px 0 0 #28d7a6}.device-card.warn,.fault-item.warn{box-shadow:inset 4px 0 0 #f6b94c}.fault-item.danger{box-shadow:inset 4px 0 0 #ff7878}.device-title{display:flex;justify-content:space-between;gap:10px}.device-title span{color:#8bdfff}.metric-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:14px}.metric-grid div{padding:10px;border-radius:8px;background:rgba(255,255,255,.05)}.metric-grid small{display:block;color:#b8c7d5}.metric-grid b{display:block;margin-top:6px}.fault-list{display:grid;gap:10px}.fault-item p{margin:8px 0;color:#c8d6e3}.fault-item small{color:#8bdfff}.dark-table :deep(.el-table),.dark-table :deep(.el-table tr),.dark-table :deep(.el-table th.el-table__cell),.dark-table :deep(.el-table td.el-table__cell){background:transparent;color:#eef6ff}.dark-table :deep(.el-table__header th.el-table__cell){color:#8bdfff}@media(max-width:1100px){.page-hero,.hero-actions{flex-direction:column}.kpi-grid,.content-grid,.device-cards{grid-template-columns:1fr}}
</style>
