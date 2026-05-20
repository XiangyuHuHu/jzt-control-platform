<template>
  <div class="ops-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">生产调度</p>
        <h1>生产管理与调度管理整合页</h1>
        <p>保留一个统一入口，集中展示生产流程、二班倒排班、调度记录、耗电量录入和异常闭环。</p>
      </div>
      <div class="hero-actions">
        <el-button @click="exportDispatch">导出调度记录</el-button>
        <el-button type="primary" @click="showRecordDialog = true">新增调度记录</el-button>
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
      <article class="panel panel--wide">
        <div class="panel-head">
          <h2>实时工艺流程</h2>
          <span>破碎站、煤泥水和水平衡纳入同页监控</span>
        </div>
        <div class="flow-map">
          <div v-for="node in flowNodes" :key="node.name" class="flow-node" :class="node.status">
            <strong>{{ node.name }}</strong>
            <span>{{ node.value }}</span>
            <small>{{ node.note }}</small>
          </div>
        </div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <h2>倒班设置</h2>
          <span>默认二班倒，三班倒时一班计划为 0</span>
        </div>
        <div class="shift-list">
          <div v-for="item in shiftRows" :key="item.team" class="shift-row">
            <strong>{{ item.team }}</strong>
            <span>{{ item.role }}</span>
            <small>{{ item.time }} · 计划 {{ item.plan }} 吨</small>
          </div>
        </div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <h2>耗电量录入</h2>
          <span>生产班组可直接录入当班电耗</span>
        </div>
        <el-form :model="energyForm" label-width="86px" class="compact-form">
          <el-form-item label="日期">
            <el-date-picker v-model="energyForm.date" type="date" value-format="YYYY-MM-DD" />
          </el-form-item>
          <el-form-item label="班次">
            <el-select v-model="energyForm.shift">
              <el-option label="白班" value="白班" />
              <el-option label="夜班" value="夜班" />
            </el-select>
          </el-form-item>
          <el-form-item label="耗电量">
            <el-input-number v-model="energyForm.power" :min="0" :precision="2" />
          </el-form-item>
          <el-button type="primary" @click="saveEnergy">保存录入</el-button>
        </el-form>
      </article>

      <article class="panel panel--wide">
        <div class="panel-head">
          <div>
            <h2>调度记录</h2>
            <span>生产和调度共用同一张记录表，避免两个页面重复维护</span>
          </div>
          <div class="filter-tools">
            <el-select v-model="filterShift" clearable placeholder="班次" style="width: 120px">
              <el-option label="白班" value="白班" />
              <el-option label="夜班" value="夜班" />
            </el-select>
            <el-date-picker v-model="filterMonth" type="month" value-format="YYYY-MM" placeholder="月份" />
          </div>
        </div>
        <el-table :data="filteredRecords" class="dark-table">
          <el-table-column prop="recordNo" label="编号" width="150" />
          <el-table-column prop="recordTime" label="记录时间" width="170" />
          <el-table-column prop="weekday" label="星期" width="90" />
          <el-table-column prop="shift" label="班次" width="90" />
          <el-table-column prop="type" label="类型" width="120" />
          <el-table-column prop="content" label="内容" min-width="260" show-overflow-tooltip />
          <el-table-column prop="owner" label="记录人" width="100" />
          <el-table-column prop="status" label="状态" width="100" />
        </el-table>
      </article>
    </section>

    <el-dialog v-model="showRecordDialog" title="新增调度记录" width="620px">
      <el-form :model="recordForm" label-width="90px">
        <el-form-item label="班次">
          <el-select v-model="recordForm.shift">
            <el-option label="白班" value="白班" />
            <el-option label="夜班" value="夜班" />
          </el-select>
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="recordForm.type">
            <el-option label="运行情况" value="运行情况" />
            <el-option label="事故记录" value="事故记录" />
            <el-option label="上传下达" value="上传下达" />
            <el-option label="遗留事项" value="遗留事项" />
          </el-select>
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="recordForm.content" type="textarea" :rows="4" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRecordDialog = false">取消</el-button>
        <el-button type="primary" @click="saveRecord">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

const kpis = [
  { label: '当班处理量', value: '1,482.5 吨', note: '白班生产一班' },
  { label: '煤泥水循环', value: '92%', note: '水平衡正常' },
  { label: '破碎站负荷', value: '78%', note: '已接入设备数据' },
  { label: '待闭环事项', value: '3 项', note: '调度与机修共同处理' },
]

const flowNodes = [
  { name: '原煤仓', value: '420 t/h', note: '给料稳定', status: 'ok' },
  { name: '破碎站', value: '电流 68 A', note: '接入润华破碎设备', status: 'ok' },
  { name: '主洗系统', value: '密度 1.42', note: '运行正常', status: 'ok' },
  { name: '煤泥水', value: '浓度 34%', note: '回收关注', status: 'warn' },
  { name: '产品仓', value: '72%', note: '装车计划正常', status: 'ok' },
]

const shiftRows = [
  { team: '一班', role: '生产班', time: '08:00-20:00', plan: 12600 },
  { team: '二班', role: '生产班', time: '20:00-08:00', plan: 12600 },
  { team: '检修班', role: '设备检修', time: '08:00-17:30', plan: 0 },
]

type RecordRow = {
  recordNo: string
  recordTime: string
  weekday: string
  shift: string
  type: string
  content: string
  owner: string
  status: string
}

const records = ref<RecordRow[]>([
  { recordNo: 'DD20260413001', recordTime: '2026-04-13 08:10:00', weekday: '星期一', shift: '白班', type: '运行情况', content: '主洗系统运行平稳，原煤给料维持在 420 吨/小时。', owner: '张伟', status: '已完成' },
  { recordNo: 'DD20260413002', recordTime: '2026-04-13 09:15:00', weekday: '星期一', shift: '白班', type: '事故记录', content: '2 号转载点皮带跑偏告警，已安排检修员现场处理。', owner: '李超', status: '处理中' },
  { recordNo: 'DD20260412003', recordTime: '2026-04-12 21:20:00', weekday: '星期日', shift: '夜班', type: '上传下达', content: '夜班重点关注精煤灰分波动和煤泥水浓度。', owner: '王敏', status: '已完成' },
])

const showRecordDialog = ref(false)
const filterShift = ref('')
const filterMonth = ref('2026-04')
const recordForm = reactive({ shift: '白班', type: '运行情况', content: '' })
const energyForm = reactive({ date: '2026-04-13', shift: '白班', power: 8420.5 })

const filteredRecords = computed(() =>
  records.value.filter((item) => {
    const matchShift = !filterShift.value || item.shift === filterShift.value
    const matchMonth = !filterMonth.value || item.recordTime.startsWith(filterMonth.value)
    return matchShift && matchMonth
  }),
)

const getWeekday = (date: Date) => ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'][date.getDay()]

function saveRecord() {
  if (!recordForm.content.trim()) {
    ElMessage.warning('请填写调度内容')
    return
  }
  const now = new Date()
  records.value.unshift({
    recordNo: `DD${now.getTime()}`,
    recordTime: now.toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-'),
    weekday: getWeekday(now),
    shift: recordForm.shift,
    type: recordForm.type,
    content: recordForm.content,
    owner: '当前用户',
    status: '待处理',
  })
  recordForm.content = ''
  showRecordDialog.value = false
  ElMessage.success('调度记录已保存')
}

function saveEnergy() {
  ElMessage.success(`已保存 ${energyForm.date} ${energyForm.shift} 耗电量 ${energyForm.power} kWh`)
}

function exportDispatch() {
  ElMessage.success('调度记录已生成导出任务')
}
</script>

<style scoped>
.ops-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}
.page-hero,.kpi-grid,.content-grid{width:min(100%,1680px);margin:0 auto 16px}
.page-hero,.panel,.kpi-card{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}
.page-hero{display:flex;justify-content:space-between;gap:24px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff;font-size:12px;letter-spacing:.12em}.page-hero h1{margin:0;font-size:30px}.page-hero p{margin:10px 0 0;color:#c8d6e3}.hero-actions,.filter-tools{display:flex;gap:10px;align-items:flex-start;flex-wrap:wrap}
.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.kpi-card{padding:18px}.kpi-card span{color:#b8c7d5}.kpi-card strong{display:block;margin-top:10px;font-size:30px}.kpi-card small{display:block;margin-top:8px;color:#8bdfff}
.content-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;margin-bottom:16px}.panel-head h2{margin:0}.panel-head span{color:#b8c7d5}
.flow-map{display:grid;grid-template-columns:repeat(5,1fr);gap:12px}.flow-node{min-height:128px;padding:18px;border-radius:8px;background:#17212b;border:1px solid rgba(255,255,255,.08)}.flow-node strong,.flow-node span,.flow-node small{display:block}.flow-node strong{font-size:18px}.flow-node span{margin-top:14px;font-size:24px}.flow-node small{margin-top:8px;color:#b8c7d5}.flow-node.ok{box-shadow:inset 4px 0 0 #28d7a6}.flow-node.warn{box-shadow:inset 4px 0 0 #f6b94c}
.shift-list{display:grid;gap:10px}.shift-row{padding:14px;border-radius:8px;background:#17212b}.shift-row strong,.shift-row span,.shift-row small{display:block}.shift-row span{margin-top:6px;color:#8bdfff}.shift-row small{margin-top:6px;color:#b8c7d5}
.compact-form :deep(.el-form-item){margin-bottom:14px}.dark-table :deep(.el-table),.dark-table :deep(.el-table tr),.dark-table :deep(.el-table th.el-table__cell),.dark-table :deep(.el-table td.el-table__cell){background:transparent;color:#eef6ff}.dark-table :deep(.el-table__header th.el-table__cell){color:#8bdfff}
@media(max-width:1100px){.kpi-grid,.content-grid,.flow-map{grid-template-columns:1fr}.page-hero{flex-direction:column}.ops-page{padding-top:24px}}
</style>
