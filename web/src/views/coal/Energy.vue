<template>
  <div class="energy-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">能耗管理</p>
        <h1>耗电量录入与水平衡</h1>
        <p>补充耗电量数据录入，集中展示水耗、煤泥水、循环水和水平衡状态。</p>
      </div>
      <el-button type="primary" @click="savePower">保存耗电量</el-button>
    </section>

    <section class="content-grid">
      <article class="panel">
        <h2>耗电量数据录入</h2>
        <el-form :model="form" label-width="92px">
          <el-form-item label="日期"><el-date-picker v-model="form.date" type="date" value-format="YYYY-MM-DD" /></el-form-item>
          <el-form-item label="班次"><el-select v-model="form.shift"><el-option label="白班" value="白班" /><el-option label="夜班" value="夜班" /></el-select></el-form-item>
          <el-form-item label="生产量"><el-input-number v-model="form.output" :min="0" :precision="2" /></el-form-item>
          <el-form-item label="耗电量"><el-input-number v-model="form.power" :min="0" :precision="2" /></el-form-item>
          <el-form-item label="单耗"><strong>{{ unitPower }} kWh/t</strong></el-form-item>
        </el-form>
      </article>

      <article class="panel">
        <h2>水平衡</h2>
        <div class="balance-grid">
          <div v-for="item in waterRows" :key="item.label">
            <span>{{ item.label }}</span>
            <strong>{{ item.value }}</strong>
            <small>{{ item.note }}</small>
          </div>
        </div>
      </article>

      <article class="panel panel--wide">
        <div class="panel-head">
          <h2>历史记录查询</h2>
          <el-date-picker v-model="month" type="month" value-format="YYYY-MM" placeholder="月份" />
        </div>
        <el-table :data="filteredRows">
          <el-table-column prop="date" label="日期" width="120" />
          <el-table-column prop="monthText" label="月份" width="100" />
          <el-table-column prop="weekday" label="星期" width="100" />
          <el-table-column prop="shift" label="班次" width="90" />
          <el-table-column prop="output" label="生产量(t)" width="120" />
          <el-table-column prop="power" label="耗电量(kWh)" width="140" />
          <el-table-column prop="unit" label="单耗(kWh/t)" width="140" />
          <el-table-column prop="waterBalance" label="水平衡状态" />
        </el-table>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

const form = reactive({ date: '2026-04-13', shift: '白班', output: 1482.5, power: 8420.5 })
const month = ref('2026-04')

const unitPower = computed(() => (form.output ? (form.power / form.output).toFixed(2) : '0.00'))
const waterRows = [
  { label: '清水补入', value: '186 m³/h', note: '正常' },
  { label: '循环水量', value: '2,430 m³/h', note: '回用率 92%' },
  { label: '煤泥水浓度', value: '34%', note: '关注沉降' },
  { label: '水平衡差额', value: '+2.6%', note: '可控范围' },
]
const rows = ref([
  { date: '2026-04-13', monthText: '4月', weekday: '星期一', shift: '白班', output: 1482.5, power: 8420.5, unit: 5.68, waterBalance: '平衡' },
  { date: '2026-04-12', monthText: '4月', weekday: '星期日', shift: '夜班', output: 1390.2, power: 7995.0, unit: 5.75, waterBalance: '平衡' },
])
const filteredRows = computed(() => rows.value.filter((item) => item.date.startsWith(month.value)))
function savePower() {
  rows.value.unshift({ date: form.date, monthText: `${Number(form.date.slice(5, 7))}月`, weekday: getWeekday(new Date(form.date)), shift: form.shift, output: form.output, power: form.power, unit: Number(unitPower.value), waterBalance: '平衡' })
  ElMessage.success('耗电量数据已保存')
}
function getWeekday(date: Date) {
  return ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'][date.getDay()]
}
</script>

<style scoped>
.energy-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}.page-hero,.content-grid{width:min(100%,1680px);margin:0 auto 16px}.page-hero,.panel{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:20px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff}.page-hero h1{margin:0}.page-hero p{color:#c8d6e3}.content-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel h2{margin:0 0 16px}.panel-head{display:flex;justify-content:space-between;gap:12px;margin-bottom:16px}.balance-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.balance-grid div{padding:16px;border-radius:8px;background:#17212b}.balance-grid span,.balance-grid small{display:block;color:#b8c7d5}.balance-grid strong{display:block;margin:10px 0;font-size:28px}@media(max-width:1100px){.energy-page{padding-top:24px}.page-hero,.content-grid{grid-template-columns:1fr;flex-direction:column}}
</style>
