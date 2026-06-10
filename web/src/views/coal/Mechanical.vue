<template>
  <div class="coal-page section-page mechanical-page">
    <CoalQuickBar
      title="机电设备台账"
      subtitle="对应最新需求中的设备台账、运行状态、二维码和设备档案，不替换设备总览页，单独形成深页。"
    />

    <section class="page-shell">
      <section class="section-hero">
        <div>
          <p class="section-eyebrow">机电设备</p>
          <h1>设备台账与二维码档案</h1>
          <p class="section-text">按设备状态、型号、位置和归属部门查看台账，同时保留二维码编号字段，为后续扫码联动预留基础。</p>
        </div>
      </section>

      <div class="toolbar-row">
        <section class="stats-grid">
          <article class="stat-card" v-for="item in stats" :key="item.label">
            <span>{{ item.label }}</span>
            <strong>{{ item.value }}</strong>
            <small>{{ item.note }}</small>
          </article>
        </section>
        <section class="section-panel filters">
          <el-select v-model="filterStatus" clearable placeholder="设备状态" style="width: 140px" size="small">
            <el-option label="在用" value="在用" />
            <el-option label="检修" value="检修" />
            <el-option label="备用" value="备用" />
          </el-select>
          <el-button type="primary" size="small" @click="loadRows">查询</el-button>
        </section>
      </div>

      <div class="mechanical-body">
        <section class="section-panel chart-panel">
          <div class="panel-head">
            <h2>设备状态分布</h2>
          </div>
          <div ref="chartEl" class="chart-box"></div>
        </section>

        <section class="section-panel detail-panel">
          <div class="panel-head">
            <h2>设备档案详情</h2>
          </div>
          <el-descriptions v-if="selectedRow" :column="1" border class="detail-desc">
            <el-descriptions-item label="设备名称">{{ selectedRow.name }}</el-descriptions-item>
            <el-descriptions-item label="规格型号">{{ selectedRow.model }}</el-descriptions-item>
            <el-descriptions-item label="设备类型">{{ selectedRow.deviceType }}</el-descriptions-item>
            <el-descriptions-item label="当前状态">{{ selectedRow.status }}</el-descriptions-item>
            <el-descriptions-item label="安装位置">{{ selectedRow.location }}</el-descriptions-item>
            <el-descriptions-item label="归属部门">{{ selectedRow.ownerDept }}</el-descriptions-item>
            <el-descriptions-item label="二维码编号">{{ selectedRow.qrCode }}</el-descriptions-item>
          </el-descriptions>
          <p v-else class="detail-empty">请在下方台账中选择设备</p>
        </section>

        <section class="section-panel table-panel">
          <div class="panel-head">
            <h2>机电设备台账</h2>
            <div class="panel-actions">
              <el-button size="small" @click="handleExport">导出 CSV</el-button>
              <el-button type="primary" size="small" @click="handlePrint">打印</el-button>
            </div>
          </div>
          <el-table :data="rows" size="small" highlight-current-row @row-click="selectedRow = $event">
          <el-table-column prop="name" label="设备名称" min-width="180" />
          <el-table-column prop="model" label="规格型号" min-width="120" />
          <el-table-column prop="deviceType" label="设备类型" min-width="120" />
          <el-table-column prop="status" label="状态" min-width="100" />
          <el-table-column prop="location" label="位置" min-width="160" />
          <el-table-column prop="ownerDept" label="归属部门" min-width="120" />
          <el-table-column prop="qrCode" label="二维码编号" min-width="120" />
          </el-table>
        </section>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
import { echarts } from '../../utils/echarts'
import { listMechanicalLedgers, type MechanicalLedgerDto } from '../../api/coal-business'
import { exportRowsToCsv, printRowsAsTable } from '../../utils/report-export'
import { ElMessage } from 'element-plus'

const filterStatus = ref('')
const rows = ref<MechanicalLedgerDto[]>([])
const selectedRow = ref<MechanicalLedgerDto | null>(null)
const chartEl = ref<HTMLElement | null>(null)
let chart: any = null

const fallbackRows: MechanicalLedgerDto[] = [
  { name: '100扫地泵', model: 'Y225M-6', deviceType: '离心泵', status: '在用', location: '原煤仓上', ownerDept: '滨海金地', qrCode: 'EQR-100' },
  { name: '101带式输送机', model: 'DTII-800', deviceType: '输送机', status: '在用', location: '原煤仓下', ownerDept: '选煤车间', qrCode: 'EQR-101' },
  { name: '311离心机', model: 'LW530', deviceType: '离心机', status: '检修', location: '脱介车间', ownerDept: '机电班', qrCode: 'EQR-311' },
  { name: '503刮板机', model: 'GB-500', deviceType: '刮板机', status: '备用', location: '产品仓上', ownerDept: '机修班', qrCode: 'EQR-503' },
]

const stats = computed(() => [
  { label: '设备总数', value: `${rows.value.length} 台`, note: '当前筛选结果' },
  { label: '在用', value: `${rows.value.filter(item => item.status === '在用').length} 台`, note: '用于运行台账统计' },
  { label: '检修', value: `${rows.value.filter(item => item.status === '检修').length} 台`, note: '需持续跟踪' },
  { label: '备用', value: `${rows.value.filter(item => item.status === '备用').length} 台`, note: '可用于应急切换' },
])

async function loadRows() {
  try {
    const data = await listMechanicalLedgers({ status: filterStatus.value })
    rows.value = data.length ? data : fallbackRows
  } catch {
    rows.value = fallbackRows
  }
  selectedRow.value = rows.value[0] || null
  await nextTick()
  renderChart()
}

function renderChart() {
  if (!chartEl.value) return
  chart?.dispose()
  chart = echarts.init(chartEl.value)
  const categories = ['在用', '检修', '备用']
  const values = categories.map(key => rows.value.filter(item => item.status === key).length)
  chart.setOption({
    tooltip: { trigger: 'item' },
    series: [{
      type: 'pie',
      radius: ['48%', '72%'],
      data: categories.map((name, index) => ({
        name,
        value: values[index],
        itemStyle: { color: ['#4ec9ff', '#ffb84e', '#2fe0a5'][index] },
      })),
      label: { color: '#dbe7ff' },
    }],
  })
}

const handleResize = () => chart?.resize()
const exportColumns: Array<{ key: keyof MechanicalLedgerDto; label: string }> = [
  { key: 'name', label: '设备名称' },
  { key: 'model', label: '规格型号' },
  { key: 'deviceType', label: '设备类型' },
  { key: 'status', label: '状态' },
  { key: 'location', label: '位置' },
  { key: 'ownerDept', label: '归属部门' },
  { key: 'qrCode', label: '二维码编号' },
]

const handleExport = () => {
  exportRowsToCsv(rows.value, exportColumns, `机电台账_${new Date().toISOString().slice(0, 10)}`)
  ElMessage.success('机电台账 CSV 已下载')
}

const handlePrint = () => {
  const ok = printRowsAsTable('机电设备台账', rows.value, exportColumns, {
    subtitle: '金海泽地选煤厂设备档案报表',
    meta: [
      { label: '筛选状态', value: filterStatus.value || '全部' },
      { label: '记录条数', value: `${rows.value.length}` },
    ],
    preparedBy: '机电班',
    reviewedBy: '设备主管',
    approvedBy: '生产副总',
  })
  if (!ok) {
    ElMessage.warning('浏览器拦截了打印窗口，请允许弹窗后重试')
    return
  }
  ElMessage.success('已打开打印预览')
}

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
  overflow: hidden;
  padding: 0;
  background: #091019;
  color: #eef6ff;
}

.page-shell {
  width: min(100%, 1680px);
  height: 100%;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.section-hero h1 {
  margin: 0;
  font-size: 20px;
}

.toolbar-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
  align-items: stretch;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.stat-card {
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
}

.stat-card span {
  display: block;
  color: #97aabc;
  font-size: 12px;
}

.stat-card strong {
  display: block;
  margin-top: 6px;
  font-size: 22px;
}

.stat-card small {
  display: block;
  margin-top: 4px;
  color: #6ec8ff;
  font-size: 11px;
}

.filters {
  display: flex;
  gap: 8px;
  align-items: center;
  padding: 10px 12px !important;
  margin: 0 !important;
}

.mechanical-body {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 0.9fr 1fr;
  grid-template-rows: minmax(0, 1fr) minmax(0, 1.1fr);
  gap: 8px;
  overflow: hidden;
}

.section-panel {
  padding: 12px 14px;
  border-radius: 14px;
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.16);
  margin: 0;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.chart-panel {
  grid-column: 1;
  grid-row: 1;
}

.detail-panel {
  grid-column: 2;
  grid-row: 1;
}

.table-panel {
  grid-column: 1 / -1;
  grid-row: 2;
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

.panel-actions {
  display: flex;
  gap: 8px;
}

.chart-box {
  flex: 1;
  min-height: 100px;
}

.table-panel :deep(.el-table) {
  flex: 1;
}

.detail-empty {
  margin: 0;
  color: #8fa8bc;
  font-size: 13px;
}

.detail-panel :deep(.el-descriptions) {
  flex: 1;
  min-height: 0;
  overflow: auto;
}

.detail-panel :deep(.el-descriptions__body) {
  background: transparent !important;
}

.detail-panel :deep(.el-descriptions__table) {
  background: transparent !important;
}

.detail-panel :deep(.el-descriptions__cell) {
  background: rgba(18, 30, 46, 0.95) !important;
  border-color: rgba(122, 190, 255, 0.18) !important;
}

.detail-panel :deep(.el-descriptions__label) {
  width: 108px;
  color: #9fb4c9 !important;
  font-weight: 600;
  background: rgba(14, 24, 38, 0.98) !important;
}

.detail-panel :deep(.el-descriptions__content) {
  color: #eef6ff !important;
  background: rgba(22, 36, 52, 0.95) !important;
}

@media (max-width: 1200px) {
  .toolbar-row {
    grid-template-columns: 1fr;
  }

  .mechanical-body {
    grid-template-columns: 1fr;
    grid-template-rows: auto auto minmax(0, 1fr);
  }

  .chart-panel,
  .detail-panel,
  .table-panel {
    grid-column: 1;
    grid-row: auto;
  }
}
</style>
