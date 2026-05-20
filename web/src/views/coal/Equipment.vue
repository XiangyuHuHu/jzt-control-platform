<template>
  <div class="equipment-page">
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
import { ref } from 'vue'

const showMatrix = ref(false)
const showLedger = ref(false)

const kpis = [
  { label: '设备总数', value: '209 台', note: '在用 209，备用 0' },
  { label: '电流在线点', value: '46 个', note: '电机和变频器已纳入' },
  { label: '故障分析项', value: '5 项', note: '今日新增 1 项' },
  { label: '矩阵装车', value: '6 车位', note: '数据已接入展示' },
]

const currentRows = [
  { code: 'CR-01', name: '主破碎机', status: '正常', level: 'good', motorCurrent: 68.2, inverterCurrent: 64.7, load: 78, temperature: 48 },
  { code: 'BL-101', name: '101 原煤皮带机', status: '正常', level: 'good', motorCurrent: 42.5, inverterCurrent: 40.1, load: 66, temperature: 39 },
  { code: 'CF-311', name: '311 中煤离心机', status: '预警', level: 'warn', motorCurrent: 86.4, inverterCurrent: 82.8, load: 92, temperature: 65 },
  { code: 'RH-PS-02', name: '润华破碎站二号机', status: '关注', level: 'warn', motorCurrent: 74.9, inverterCurrent: 73.2, load: 84, temperature: 56 },
]

const faults = [
  { title: '311 中煤离心机振动升高', level: 'warn', reason: '振动 8.9 mm/s，伴随电流波动。', action: '下班前检查轴承和筛篮磨损。' },
  { title: '破碎站二号机电流偏高', level: 'warn', reason: '电机电流连续 15 分钟高于正常区间。', action: '复核给料粒度并检查破碎腔堵料。' },
  { title: '压滤机进料泵短时过载', level: 'danger', reason: '变频器电流峰值超过阈值。', action: '检查管路结垢和阀门开度。' },
]

const integrationRows = [
  { system: '润华系统', device: '润华破碎站二号机', tag: 'crusher.rh02.motor_current', value: '74.9 A', source: '润华 OPC 点位', status: '在线' },
  { system: '润华系统', device: '润华破碎站二号机', tag: 'crusher.rh02.inverter_current', value: '73.2 A', source: '润华 OPC 点位', status: '在线' },
  { system: '矩阵装车', device: '一号装车位', tag: 'loadout.matrix.lane01.weight', value: '38.6 t', source: '矩阵装车接口', status: '在线' },
  { system: '管控平台', device: '主破碎机', tag: 'crusher.current', value: '68.2 A', source: 'Kepserver', status: '在线' },
]

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
</script>

<style scoped>
.equipment-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}.page-hero,.kpi-grid,.content-grid{width:min(100%,1680px);margin:0 auto 16px}.page-hero,.panel,.kpi-card{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:24px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff;font-size:12px;letter-spacing:.12em}.page-hero h1{margin:0;font-size:30px}.page-hero p{margin:10px 0 0;color:#c8d6e3}.hero-actions{display:flex;gap:10px;align-items:flex-start}.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.kpi-card{padding:18px}.kpi-card span{color:#b8c7d5}.kpi-card strong{display:block;margin-top:10px;font-size:30px}.kpi-card small{display:block;margin-top:8px;color:#8bdfff}.content-grid{display:grid;grid-template-columns:1.2fr .8fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel-head{display:flex;justify-content:space-between;gap:12px;margin-bottom:16px}.panel-head h2{margin:0}.panel-head span{color:#b8c7d5}.device-cards{display:grid;grid-template-columns:1fr 1fr;gap:12px}.device-card,.fault-item{padding:16px;border-radius:8px;background:#17212b;border:1px solid rgba(255,255,255,.08)}.device-card.good{box-shadow:inset 4px 0 0 #28d7a6}.device-card.warn,.fault-item.warn{box-shadow:inset 4px 0 0 #f6b94c}.fault-item.danger{box-shadow:inset 4px 0 0 #ff7878}.device-title{display:flex;justify-content:space-between;gap:10px}.device-title span{color:#8bdfff}.metric-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:14px}.metric-grid div{padding:10px;border-radius:8px;background:rgba(255,255,255,.05)}.metric-grid small{display:block;color:#b8c7d5}.metric-grid b{display:block;margin-top:6px}.fault-list{display:grid;gap:10px}.fault-item p{margin:8px 0;color:#c8d6e3}.fault-item small{color:#8bdfff}.dark-table :deep(.el-table),.dark-table :deep(.el-table tr),.dark-table :deep(.el-table th.el-table__cell),.dark-table :deep(.el-table td.el-table__cell){background:transparent;color:#eef6ff}.dark-table :deep(.el-table__header th.el-table__cell){color:#8bdfff}@media(max-width:1100px){.equipment-page{padding-top:24px}.page-hero,.hero-actions{flex-direction:column}.kpi-grid,.content-grid,.device-cards{grid-template-columns:1fr}}
</style>
