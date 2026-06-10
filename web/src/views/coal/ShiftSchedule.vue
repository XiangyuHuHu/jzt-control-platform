<template>
  <div class="shift-schedule-page">
    <CoalQuickBar
      title="排班管理"
      subtitle="统一管理二班倒/三班倒班制，联动生产计划口径和检修班安排。"
    />

    <section class="page-hero">
      <div>
        <p class="eyebrow">排班管理</p>
        <h1>二班倒与检修班配置</h1>
        <p>默认二班倒：一班生产、二班生产、检修班不计生产计划；切换三班倒时允许其中一班生产计划为 0。</p>
      </div>
      <div class="hero-actions">
        <el-radio-group v-model="mode">
          <el-radio-button label="二班倒" />
          <el-radio-button label="三班倒" />
        </el-radio-group>
      </div>
    </section>

    <section class="kpi-grid">
      <article class="kpi-card">
        <span>班制方案</span>
        <strong>{{ mode }}</strong>
        <small>当前生效排班模式</small>
      </article>
      <article class="kpi-card">
        <span>生产班组</span>
        <strong>{{ productionTeams }} 个</strong>
        <small>参与当日生产计划</small>
      </article>
      <article class="kpi-card">
        <span>检修/备用班</span>
        <strong>{{ maintenanceTeams }} 个</strong>
        <small>用于检修和值班</small>
      </article>
      <article class="kpi-card">
        <span>计划总量</span>
        <strong>{{ totalPlan.toLocaleString() }} 吨</strong>
        <small>按当前班制汇总</small>
      </article>
    </section>

    <section class="panel">
      <div class="panel-head">
        <div>
          <h2>班组排班明细</h2>
          <p>切换班制后，生产计划与班组说明同步更新。</p>
        </div>
      </div>
      <el-table :data="rows" class="dark-table" stripe>
        <el-table-column prop="team" label="班组" min-width="120" />
        <el-table-column prop="role" label="类型" min-width="110" />
        <el-table-column prop="time" label="时间" min-width="160" />
        <el-table-column prop="production" label="是否生产班" min-width="120" />
        <el-table-column prop="plan" label="生产计划(吨)" min-width="130" />
        <el-table-column prop="remark" label="说明" min-width="220" />
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
const mode = ref('二班倒')
const rows = computed(() => mode.value === '二班倒'
  ? [
      { team: '一班', role: '生产班', time: '08:00-20:00', production: '是', plan: 12600, remark: '白班生产' },
      { team: '二班', role: '生产班', time: '20:00-08:00', production: '是', plan: 12600, remark: '夜班生产' },
      { team: '检修班', role: '检修班', time: '08:00-17:30', production: '否', plan: 0, remark: '设备检修和保养' },
    ]
  : [
      { team: '一班', role: '生产班', time: '08:00-16:00', production: '是', plan: 8400, remark: '早班生产' },
      { team: '二班', role: '生产班', time: '16:00-00:00', production: '是', plan: 8400, remark: '中班生产' },
      { team: '三班', role: '备用/检修', time: '00:00-08:00', production: '否', plan: 0, remark: '计划为 0，可用于检修' },
    ])

const productionTeams = computed(() => rows.value.filter((item) => item.production === '是').length)
const maintenanceTeams = computed(() => rows.value.filter((item) => item.production !== '是').length)
const totalPlan = computed(() => rows.value.reduce((sum, item) => sum + Number(item.plan || 0), 0))
</script>

<style scoped>
.shift-schedule-page {
  height: 100%;
  min-height: 0;
  overflow: auto;
  padding: 12px 14px 18px;
  background: #16202a;
  color: #eef6ff;
}

.page-hero,
.kpi-grid,
.panel {
  width: min(100%, 1680px);
  margin: 0 auto 16px;
}

.page-hero,
.kpi-card,
.panel {
  border: 1px solid rgba(169, 202, 232, 0.18);
  border-radius: 18px;
  background: #202c38;
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.16);
}

.page-hero {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  padding: 24px 28px;
}

.eyebrow {
  margin: 0 0 10px;
  color: #72d8ff;
  font-size: 12px;
  letter-spacing: 0.18em;
}

.page-hero h1 {
  margin: 0;
  font-size: 30px;
}

.page-hero p {
  margin: 10px 0 0;
  color: #9ab1c7;
}

.hero-actions {
  display: flex;
  align-items: flex-start;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.kpi-card {
  padding: 16px 18px;
}

.kpi-card span {
  color: #9ab1c7;
}

.kpi-card strong {
  display: block;
  margin-top: 10px;
  font-size: 28px;
}

.kpi-card small {
  display: block;
  margin-top: 8px;
  color: #67d8ff;
}

.panel {
  padding: 20px;
  margin-bottom: 0;
}

.panel-head {
  margin-bottom: 12px;
}

.panel-head h2 {
  margin: 0;
  font-size: 22px;
}

.panel-head p {
  margin: 8px 0 0;
  color: #8fa8bc;
}

.dark-table {
  width: 100%;
}

.dark-table :deep(.el-table),
.dark-table :deep(.el-table__inner-wrapper),
.dark-table :deep(.el-table tr),
.dark-table :deep(.el-table th.el-table__cell),
.dark-table :deep(.el-table td.el-table__cell) {
  background: transparent;
  color: #eef6ff;
}

.dark-table :deep(.el-table__header th.el-table__cell) {
  color: #7ecfff;
}

@media (max-width: 1200px) {
  .kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 900px) {
  .page-hero {
    flex-direction: column;
  }
}

@media (max-width: 768px) {
  .kpi-grid {
    grid-template-columns: 1fr;
  }
}
</style>
