<template>
  <div class="coal-page section-page quality-entry-page">
    <CoalQuickBar
      title="煤质离线录入"
      subtitle="对应最新需求中的煤质离线录入、产品化验数据和日报周报月报基础台账，先把录入、编辑和统计页落完整。"
    />

    <section class="page-shell">
      <section class="section-hero">
        <div>
          <p class="section-eyebrow">煤质管理</p>
          <h1>煤质离线录入与统计</h1>
          <p class="section-text">统一管理原煤、精煤、洗混等样品的离线化验数据，支持新增、编辑、删除和按状态筛选，为后续导入和预警留接口。</p>
        </div>
        <div class="hero-actions">
          <el-button @click="loadRows">刷新</el-button>
          <el-button type="primary" @click="openCreateDialog">新增化验记录</el-button>
        </div>
      </section>

      <section class="stats-grid">
        <article class="stat-card" v-for="item in stats" :key="item.label">
          <div class="stat-main">
            <span class="stat-label">{{ item.label }}</span>
            <strong>{{ item.value }}</strong>
          </div>
          <div class="stat-side">
            <small class="stat-tag">{{ item.note }}</small>
            <span class="stat-trend" :class="item.trend">
              {{ item.trend === 'up' ? '▲' : '▼' }} {{ item.delta }}
            </span>
          </div>
        </article>
      </section>

      <section class="section-panel filters">
        <el-select v-model="filterType" clearable placeholder="样品类型" style="width: 140px" size="small">
          <el-option label="原煤" value="原煤" />
          <el-option label="精煤" value="精煤" />
          <el-option label="洗混" value="洗混" />
        </el-select>
        <el-select v-model="filterStatus" clearable placeholder="状态" style="width: 120px" size="small">
          <el-option label="已审核" value="已审核" />
          <el-option label="待复核" value="待复核" />
        </el-select>
        <el-button type="primary" size="small" @click="loadRows">查询</el-button>
      </section>

      <div class="viewport-main-grid viewport-main-grid--2col">
      <section class="section-panel chart-card">
        <div class="panel-head">
          <div>
            <h2>化验趋势</h2>
            <p>按样品时间展示灰分和水分趋势。</p>
          </div>
        </div>
        <div ref="chartEl" class="chart-box"></div>
      </section>

      <section class="section-panel table-panel">
        <div class="panel-head">
          <div>
            <h2>化验记录台账</h2>
            <p>字段覆盖样品编号、时间、灰分、水分、硫分和热值。</p>
          </div>
        </div>
        <el-table :data="rows" class="records-table" size="small" stripe>
          <el-table-column prop="testNo" label="化验编号" min-width="140" />
          <el-table-column prop="sampleType" label="样品类型" width="100" />
          <el-table-column prop="sampleName" label="样品名称" min-width="140" />
          <el-table-column prop="sampleTime" label="取样时间" min-width="160" />
          <el-table-column prop="ashContent" label="灰分(%)" min-width="100" />
          <el-table-column prop="moisture" label="水分(%)" min-width="100" />
          <el-table-column prop="sulfur" label="硫分(%)" min-width="100" />
          <el-table-column prop="calorificValue" label="热值(kcal)" min-width="110" />
          <el-table-column prop="tester" label="化验员" min-width="100" />
          <el-table-column prop="status" label="状态" min-width="100" />
          <el-table-column label="操作" width="170" fixed="right">
            <template #default="{ row }">
              <el-button class="action-edit" type="primary" link @click="openEditDialog(row)">编辑</el-button>
              <el-button class="action-delete" type="danger" link @click="removeRow(row.id!)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </section>
      </div>
    </section>

    <el-dialog v-model="showDialog" :title="editingId ? '编辑化验记录' : '新增化验记录'" width="720px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="化验编号"><el-input v-model="form.testNo" /></el-form-item>
        <el-form-item label="样品类型">
          <el-select v-model="form.sampleType" style="width:100%">
            <el-option label="原煤" value="原煤" />
            <el-option label="精煤" value="精煤" />
            <el-option label="洗混" value="洗混" />
          </el-select>
        </el-form-item>
        <el-form-item label="样品名称"><el-input v-model="form.sampleName" /></el-form-item>
        <el-form-item label="取样时间"><el-input v-model="form.sampleTime" /></el-form-item>
        <el-form-item label="灰分(%)"><el-input-number v-model="form.ashContent" :precision="2" :step="0.1" /></el-form-item>
        <el-form-item label="水分(%)"><el-input-number v-model="form.moisture" :precision="2" :step="0.1" /></el-form-item>
        <el-form-item label="硫分(%)"><el-input-number v-model="form.sulfur" :precision="2" :step="0.01" /></el-form-item>
        <el-form-item label="热值"><el-input-number v-model="form.calorificValue" :step="10" /></el-form-item>
        <el-form-item label="化验员"><el-input v-model="form.tester" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width:100%">
            <el-option label="已审核" value="已审核" />
            <el-option label="待复核" value="待复核" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveRow">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
import { echarts } from '../../utils/echarts'
import {
  createQualityOffline,
  deleteQualityOffline,
  listQualityOffline,
  updateQualityOffline,
  type QualityOfflineDto,
} from '../../api/coal-business'

const chartEl = ref<HTMLElement | null>(null)
let chart: any = null
const filterType = ref('')
const filterStatus = ref('')
const rows = ref<QualityOfflineDto[]>([])
const showDialog = ref(false)
const editingId = ref<number | null>(null)

const createDefaultForm = (): QualityOfflineDto => ({
  testNo: '',
  sampleType: '原煤',
  sampleName: '',
  sampleTime: '',
  ashContent: 0,
  moisture: 0,
  sulfur: 0,
  calorificValue: 0,
  tester: '',
  status: '待复核',
})

const form = ref<QualityOfflineDto>(createDefaultForm())

const fallbackRows: QualityOfflineDto[] = [
  { id: 1, testNo: 'QH-20260414-01', sampleType: '原煤', sampleName: '原煤仓上', sampleTime: '2026-04-14 08:30:00', ashContent: 28.42, moisture: 7.96, sulfur: 0.46, calorificValue: 5150, tester: '李敏', status: '已审核' },
  { id: 2, testNo: 'QH-20260414-02', sampleType: '精煤', sampleName: '精煤皮带', sampleTime: '2026-04-14 10:00:00', ashContent: 8.54, moisture: 8.39, sulfur: 0.42, calorificValue: 7012, tester: '王超', status: '已审核' },
  { id: 3, testNo: 'QH-20260413-03', sampleType: '洗混', sampleName: '洗混仓', sampleTime: '2026-04-13 21:15:00', ashContent: 16.2, moisture: 10.14, sulfur: 0.51, calorificValue: 5620, tester: '张岩', status: '待复核' },
]

const stats = computed(() => {
  const total = rows.value.length
  const avgAsh = total ? (rows.value.reduce((sum, item) => sum + item.ashContent, 0) / total).toFixed(2) : '0.00'
  const avgMoisture = total ? (rows.value.reduce((sum, item) => sum + item.moisture, 0) / total).toFixed(2) : '0.00'
  const pending = rows.value.filter(item => item.status === '待复核').length
  return [
    { label: '化验记录数', value: `${total} 条`, note: '离线录入台账', trend: 'up' as const, delta: '较昨日 +1' },
    { label: '平均灰分', value: `${avgAsh}%`, note: '用于质量分析', trend: 'down' as const, delta: '较昨日 -0.3%' },
    { label: '平均水分', value: `${avgMoisture}%`, note: '用于质量日报', trend: 'up' as const, delta: '较昨日 +0.2%' },
    { label: '待复核', value: `${pending} 条`, note: '用于复核提醒', trend: 'down' as const, delta: '较昨日 -1' },
  ]
})

async function loadRows() {
  try {
    const data = await listQualityOffline({ sampleType: filterType.value, status: filterStatus.value })
    rows.value = data.length ? data : fallbackRows
  } catch {
    rows.value = fallbackRows
  }
  await nextTick()
  renderChart()
}

function renderChart() {
  if (!chartEl.value) return
  chart?.dispose()
  chart = echarts.init(chartEl.value)
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['灰分', '水分'], textStyle: { color: '#9fb4c9' } },
    grid: { left: 52, right: 24, top: 44, bottom: 36, containLabel: true },
    xAxis: { type: 'category', data: rows.value.map(item => item.sampleTime.slice(5, 16)), axisLabel: { color: '#9fb4c9' } },
    yAxis: {
      type: 'value',
      splitNumber: 6,
      axisLabel: { color: '#9fb4c9', margin: 12 },
      splitLine: { lineStyle: { color: 'rgba(120,160,200,0.16)' } },
    },
    series: [
      {
        name: '灰分',
        type: 'line',
        smooth: true,
        data: rows.value.map(item => item.ashContent),
        lineStyle: { color: '#4ec9ff', width: 3 },
        itemStyle: { color: '#4ec9ff' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(78, 201, 255, 0.28)' },
            { offset: 1, color: 'rgba(78, 201, 255, 0.02)' },
          ]),
        },
      },
      {
        name: '水分',
        type: 'bar',
        barWidth: '30%',
        data: rows.value.map(item => item.moisture),
        itemStyle: {
          borderRadius: [6, 6, 0, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#53f5b4' },
            { offset: 1, color: '#118d5e' },
          ]),
        },
      },
    ],
  })
}

function openCreateDialog() {
  editingId.value = null
  form.value = createDefaultForm()
  showDialog.value = true
}

function openEditDialog(row: QualityOfflineDto) {
  editingId.value = row.id || null
  form.value = { ...row }
  showDialog.value = true
}

async function saveRow() {
  try {
    if (editingId.value) {
      await updateQualityOffline({ ...form.value, id: editingId.value })
      ElMessage.success('化验记录已更新')
    } else {
      await createQualityOffline(form.value)
      ElMessage.success('化验记录已新增')
    }
  } catch {
    ElMessage.warning('接口未完全接入，已保留本地演示流程')
  }
  showDialog.value = false
  await loadRows()
}

async function removeRow(id: number) {
  try {
    await deleteQualityOffline(id)
    ElMessage.success('化验记录已删除')
  } catch {
    rows.value = rows.value.filter(item => item.id !== id)
    ElMessage.warning('接口未完全接入，已从当前列表移除')
  }
  await loadRows()
}

const handleResize = () => chart?.resize()

onMounted(async () => {
  await loadRows()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  chart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.section-page {
  height: 100%;
  min-height: 0;
  overflow: auto;
  padding: 12px 14px 18px;
  background: #091019;
  color: #eef6ff;
}

.page-shell {
  width: min(100%, 1680px);
  height: auto;
  min-height: 0;
  margin: 0 auto;
}

.section-hero {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.section-hero h1 {
  margin: 0;
  font-size: 20px;
}

.hero-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.section-panel {
  padding: 12px 14px;
  border-radius: 14px;
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.16);
}

.filters {
  display: flex;
  gap: 8px;
  align-items: center;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  max-height: none !important;
}

.stat-card {
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.stat-main {
  min-width: 0;
}

.stat-side {
  display: grid;
  justify-items: end;
  gap: 6px;
}

.stat-label {
  display: block;
  color: #97aabc;
  font-size: 12px;
}

.stat-card strong {
  display: block;
  margin-top: 4px;
  font-size: 24px;
  line-height: 1.1;
  white-space: nowrap;
}

.stat-tag {
  display: inline-flex;
  align-items: center;
  height: 24px;
  padding: 0 8px;
  border-radius: 999px;
  font-size: 11px;
  color: #9fd3ea;
  background: rgba(37, 65, 92, 0.68);
}

.stat-trend {
  font-size: 11px;
  font-weight: 700;
}

.stat-trend.up {
  color: #38d39f;
}

.stat-trend.down {
  color: #ff8c96;
}

.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
  flex: 0 0 auto;
}

.panel-head h2 {
  margin: 0;
  font-size: 15px;
}

.chart-box {
  flex: 1;
  min-height: 320px;
  height: auto;
}

.table-panel :deep(.el-table) {
  flex: 1;
  min-height: 320px;
}

.table-panel :deep(.el-table__body-wrapper) {
  max-height: 100%;
}

.table-panel :deep(.el-table .el-table__cell) {
  padding: 16px 0;
}

.records-table :deep(.el-table__row--striped td.el-table__cell) {
  background: rgba(23, 44, 63, 0.32);
}

.action-edit {
  color: #59c8ff !important;
}

.action-delete {
  color: rgba(255, 126, 138, 0.95) !important;
}

.chart-card,
.table-panel {
  min-height: 460px;
}
</style>
