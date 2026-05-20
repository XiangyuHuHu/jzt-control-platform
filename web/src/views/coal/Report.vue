<template>
  <div class="report-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">报表中心</p>
        <h1>综合报表与实时打印</h1>
        <p>报表中心已调整为中文月份、中文星期，支持连接打印机实时打印。</p>
      </div>
      <div class="hero-actions">
        <el-button @click="exportReport">导出</el-button>
        <el-button type="primary" @click="printReport">实时打印</el-button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-head">
        <el-radio-group v-model="active">
          <el-radio-button label="生产日报" />
          <el-radio-button label="质量报表" />
          <el-radio-button label="能耗报表" />
          <el-radio-button label="设备报表" />
        </el-radio-group>
        <el-date-picker v-model="month" type="month" value-format="YYYY-MM" placeholder="月份" />
      </div>
      <el-table :data="filteredRows">
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="monthText" label="月份" width="100" />
        <el-table-column prop="weekday" label="星期" width="100" />
        <el-table-column prop="reportType" label="报表类型" width="130" />
        <el-table-column prop="summary" label="摘要" min-width="260" />
        <el-table-column prop="owner" label="制表人" width="100" />
        <el-table-column prop="status" label="状态" width="100" />
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
const active = ref('生产日报')
const month = ref('2026-04')
const rows = [
  { date: '2026-04-13', monthText: '4月', weekday: '星期一', reportType: '生产日报', summary: '白班生产 1482.5 吨，破碎站负荷正常。', owner: '张伟', status: '已生成' },
  { date: '2026-04-13', monthText: '4月', weekday: '星期一', reportType: '能耗报表', summary: '耗电量 8420.5 kWh，单耗 5.68 kWh/t。', owner: '李娜', status: '已生成' },
  { date: '2026-04-12', monthText: '4月', weekday: '星期日', reportType: '设备报表', summary: '311 中煤离心机振动预警，已派发检修。', owner: '周洋', status: '已生成' },
]
const filteredRows = computed(() => rows.filter((item) => item.date.startsWith(month.value) && item.reportType === active.value))
function exportReport() {
  ElMessage.success(`${active.value}已导出`)
}
function printReport() {
  window.print()
  ElMessage.success('已调用浏览器打印，可连接现场打印机实时打印')
}
</script>

<style scoped>
.report-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}.page-hero,.panel{width:min(100%,1680px);margin:0 auto 16px;border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:20px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff}.page-hero h1{margin:0}.page-hero p{color:#c8d6e3}.hero-actions,.panel-head{display:flex;gap:12px;align-items:flex-start;justify-content:space-between;flex-wrap:wrap}.panel{padding:22px}@media print{.coal-nav-shell,.page-hero .hero-actions,.panel-head{display:none!important}.report-page{padding:0;background:#fff;color:#000}.panel{box-shadow:none;border:0;background:#fff}}@media(max-width:900px){.report-page{padding-top:24px}.page-hero{flex-direction:column}}
</style>
