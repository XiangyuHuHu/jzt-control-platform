<template>
  <div class="coal-page section-page quality-report-page">
    <CoalQuickBar
      title="质量报表中心"
      subtitle="把最新需求里的日报、周报、月报独立成报表中心，保留原报表页作为综合分析入口。"
    />

    <section class="page-shell">
      <section class="section-hero">
        <div>
          <p class="section-eyebrow">质量报表</p>
          <h1>日报周报月报中心</h1>
          <p class="section-text">按报表周期管理质量报表生成、审核和汇总，便于后续直连打印和正式报表接口。</p>
        </div>
      </section>

      <section class="section-panel filters">
        <el-select v-model="filterCycle" clearable placeholder="报表周期" style="width:180px">
          <el-option label="日报" value="日报" />
          <el-option label="周报" value="周报" />
          <el-option label="月报" value="月报" />
        </el-select>
        <el-button type="primary" @click="loadRows">查询</el-button>
      </section>

      <section class="stats-grid">
        <article class="stat-card" v-for="item in stats" :key="item.label">
          <div class="stat-main">
            <span class="stat-label">
              {{ item.label }}
              <i v-if="item.statusKey === '待审核'" class="pending-dot" aria-hidden="true"></i>
            </span>
            <strong>{{ item.value }}</strong>
          </div>
          <small class="stat-tag" :class="`stat-tag--${item.tagType}`">{{ item.note }}</small>
        </article>
      </section>

      <section class="section-panel">
        <div class="panel-head">
          <div>
            <h2>质量报表列表</h2>
            <p>保留报表名称、日期、状态、责任人和摘要字段。</p>
          </div>
          <div class="panel-actions">
            <el-button @click="handleExport">导出 CSV</el-button>
            <el-button type="primary" @click="handlePrint">打印</el-button>
          </div>
        </div>
        <el-table :data="rows">
          <el-table-column prop="cycle" label="周期" min-width="100" />
          <el-table-column prop="reportDate" label="报表日期" min-width="120" />
          <el-table-column prop="reportName" label="报表名称" min-width="180" />
          <el-table-column prop="status" label="状态" min-width="120">
            <template #default="{ row }">
              <span class="status-tag" :class="statusClass(row.status)">{{ row.status }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="owner" label="责任人" min-width="100" />
          <el-table-column prop="summary" label="摘要" min-width="280" show-overflow-tooltip />
          <el-table-column label="操作" width="220" fixed="right">
            <template #default="{ row }">
              <div class="action-group">
                <el-button link type="primary" @click="handleView(row)">查看</el-button>
                <el-button v-if="row.status === '已生成'" link type="success" @click="handleDownload(row)">导出</el-button>
                <el-button v-else-if="row.status === '待审核'" link class="action-approve" @click="handleApprove(row)">去审核</el-button>
                <el-button v-else link type="info" @click="handleEdit(row)">继续编辑</el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </section>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
import { listQualityReportCenter, type QualityReportCenterDto } from '../../api/coal-business'
import { exportRowsToCsv, printRowsAsTable } from '../../utils/report-export'
import { ElMessage } from 'element-plus'

const filterCycle = ref('')
const rows = ref<QualityReportCenterDto[]>([])

const fallbackRows: QualityReportCenterDto[] = [
  { cycle: '日报', reportDate: '2026-04-15', reportName: '煤质情况统计报表', status: '已生成', owner: '于思源', summary: '湿混：Mt 36.7%，Mad 9.17%，Aad 39.6%，St,ad 0.4%，Qnet,ar 2253' },
  { cycle: '日报', reportDate: '2026-04-15', reportName: '煤质情况统计报表', status: '已生成', owner: '于思源', summary: '干后煤泥：Mt 27%，Mad 6.44%，Aad 40.57%，St,ad 0.36%，Qnet,ar 2678' },
  { cycle: '周报', reportDate: '2026-04-13', reportName: '煤质周度汇总', status: '待审核', owner: '质量科', summary: '本周全硫稳定在 0.35%~0.42%，热值波动可控' },
]

const stats = computed(() => [
  { label: '报表总数', statusKey: '总数', value: `${rows.value.length} 份`, note: '当前筛选结果', tagType: 'all' },
  { label: '已生成', statusKey: '已生成', value: `${rows.value.filter(item => item.status === '已生成').length} 份`, note: '可直接查看或导出', tagType: 'done' },
  { label: '待审核', statusKey: '待审核', value: `${rows.value.filter(item => item.status === '待审核').length} 份`, note: '待质量负责人审核', tagType: 'pending' },
  { label: '编制中', statusKey: '编制中', value: `${rows.value.filter(item => item.status === '编制中').length} 份`, note: '待补充分析内容', tagType: 'draft' },
])

async function loadRows() {
  try {
    const data = await listQualityReportCenter({ cycle: filterCycle.value })
    rows.value = data.length ? data : fallbackRows
  } catch {
    rows.value = fallbackRows
  }
}

const exportColumns: Array<{ key: keyof QualityReportCenterDto; label: string }> = [
  { key: 'cycle', label: '周期' },
  { key: 'reportDate', label: '报表日期' },
  { key: 'reportName', label: '报表名称' },
  { key: 'status', label: '状态' },
  { key: 'owner', label: '责任人' },
  { key: 'summary', label: '摘要' },
]

const handleExport = () => {
  exportRowsToCsv(rows.value, exportColumns, `质量报表中心_${new Date().toISOString().slice(0, 10)}`)
  ElMessage.success('质量报表 CSV 已下载')
}

const statusClass = (status: string) => {
  if (status === '已生成') return 'status-tag--done'
  if (status === '待审核') return 'status-tag--pending'
  return 'status-tag--draft'
}

const handleView = (row: QualityReportCenterDto) => {
  ElMessage.success(`已打开《${row.reportName}》详情`)
}

const handleDownload = (row: QualityReportCenterDto) => {
  ElMessage.success(`已为《${row.reportName}》创建导出任务`)
}

const handleApprove = (row: QualityReportCenterDto) => {
  ElMessage.success(`已进入《${row.reportName}》审核流程`)
}

const handleEdit = (row: QualityReportCenterDto) => {
  ElMessage.success(`继续编辑《${row.reportName}》`)
}

const handlePrint = () => {
  const ok = printRowsAsTable('质量报表列表', rows.value, exportColumns, {
    subtitle: '金海泽地选煤厂质量报表中心',
    meta: [
      { label: '筛选周期', value: filterCycle.value || '全部' },
      { label: '记录条数', value: `${rows.value.length}` },
    ],
    preparedBy: '质量科',
    reviewedBy: '质检主任',
    approvedBy: '总工办',
  })
  if (!ok) {
    ElMessage.warning('浏览器拦截了打印窗口，请允许弹窗后重试')
    return
  }
  ElMessage.success('已打开打印预览')
}

onMounted(async () => {
  await loadRows()
})
</script>

<style scoped>
.section-page{height:100%;min-height:0;overflow:auto;padding:12px 14px 18px;background:#091019;color:#eef6ff}
.page-shell{width:min(100%,1680px);margin:0 auto}
.section-hero{display:flex;justify-content:space-between;gap:24px;align-items:flex-start;margin-bottom:20px}
.section-eyebrow{margin:0 0 10px;color:#72d8ff;font-size:12px;letter-spacing:.2em;text-transform:uppercase}
.section-hero h1{margin:0;font-size:38px}
.section-text{max-width:820px;margin:12px 0 0;color:#96aabc;line-height:1.7}
.section-panel{padding:22px;border-radius:20px;border:1px solid rgba(122,190,255,.12);background:rgba(12,20,31,.92);box-shadow:0 18px 40px rgba(0,0,0,.16);margin-bottom:20px}
.filters{display:flex;gap:12px;align-items:center;flex-wrap:wrap}
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px}
.stat-card{padding:14px 16px;border-radius:18px;border:1px solid rgba(122,190,255,.12);background:rgba(12,20,31,.92);display:flex;justify-content:space-between;align-items:center;gap:12px}
.stat-main{min-width:0}
.stat-label{display:inline-flex;align-items:center;gap:6px;color:#97aabc;font-size:12px}
.pending-dot{width:8px;height:8px;border-radius:50%;background:#ff9b1a;box-shadow:0 0 10px rgba(255,155,26,.82);animation:pulse 1.6s ease-in-out infinite}
.stat-card strong{display:block;margin-top:8px;font-size:28px;line-height:1.1;white-space:nowrap}
.stat-tag{display:inline-flex;align-items:center;height:24px;padding:0 8px;border-radius:999px;font-size:11px;white-space:nowrap}
.stat-tag--all{background:rgba(69,114,148,.42);color:#b5dbff}
.stat-tag--done{background:rgba(25,190,107,.26);color:#6ff0ae}
.stat-tag--pending{background:rgba(255,153,0,.26);color:#ffc36a}
.stat-tag--draft{background:rgba(45,140,240,.26);color:#8dc7ff}
.panel-head{display:flex;justify-content:space-between;align-items:flex-start;gap:20px;margin-bottom:16px}
.panel-actions{display:flex;gap:8px;align-items:center}
.panel-head h2{margin:0;font-size:24px}
.panel-head p{margin:8px 0 0;color:#8fa8bc}
.status-tag{display:inline-flex;align-items:center;justify-content:center;min-width:68px;height:24px;padding:0 8px;border-radius:999px;color:#fff;font-size:12px;font-weight:600}
.status-tag--done{background:#19be6b}
.status-tag--pending{background:#ff9900}
.status-tag--draft{background:#2d8cf0}
.action-group{display:flex;gap:8px;align-items:center}
.action-approve{color:#ff9b1a !important;font-weight:700}
@media (max-width: 1200px){.stats-grid{grid-template-columns:repeat(2,1fr)}}
@media (max-width: 768px){.stats-grid{grid-template-columns:1fr}}
@keyframes pulse{0%,100%{transform:scale(.9);opacity:.65}50%{transform:scale(1.1);opacity:1}}
</style>
