<template>
  <div class="process-check-page">
    <section class="page-header">
      <div>
        <p class="page-tag">生产运行 / 生产技术检查</p>
        <h1>生产运行技术检查台账</h1>
        <p class="page-desc">覆盖生产记录检查、工艺制度稽核、实验记录抽查和整改闭环跟踪。</p>
      </div>
      <div class="page-actions">
        <el-button type="primary" @click="openCreateDialog">新增检查记录</el-button>
        <el-button @click="exportCsv">导出 CSV</el-button>
      </div>
    </section>

    <section class="kpi-grid">
      <article class="kpi-card">
        <span>检查总数</span>
        <strong>{{ stats.total }}</strong>
        <small>当前筛选结果</small>
      </article>
      <article class="kpi-card">
        <span>待处理</span>
        <strong>{{ stats.open }}</strong>
        <small>待安排整改</small>
      </article>
      <article class="kpi-card">
        <span>整改中</span>
        <strong>{{ stats.progress }}</strong>
        <small>持续跟踪中</small>
      </article>
      <article class="kpi-card">
        <span>已闭环</span>
        <strong>{{ stats.closed }}</strong>
        <small>复核完成</small>
      </article>
    </section>

    <section class="panel">
      <div class="panel-head">
        <h2>检查台账明细</h2>
        <div class="tools">
          <el-input v-model="filters.keyword" placeholder="检查内容 / 单号" clearable />
          <el-select v-model="filters.shift" clearable placeholder="班次">
            <el-option label="白班" value="白班" />
            <el-option label="中班" value="中班" />
            <el-option label="夜班" value="夜班" />
          </el-select>
          <el-select v-model="filters.status" clearable placeholder="状态">
            <el-option label="待处理" value="OPEN" />
            <el-option label="整改中" value="IN_PROGRESS" />
            <el-option label="已闭环" value="CLOSED" />
          </el-select>
          <el-date-picker v-model="filters.date" type="date" value-format="YYYY-MM-DD" placeholder="检查日期" />
          <el-button type="primary" @click="loadRowsFromServer">查询</el-button>
        </div>
      </div>

      <el-table :data="pagedRows" class="check-table">
        <el-table-column prop="recordNo" label="单号" min-width="150" />
        <el-table-column prop="recordType" label="检查类别" min-width="120">
          <template #default="{ row }">{{ typeText(row.recordType) }}</template>
        </el-table-column>
        <el-table-column prop="shift" label="班次" width="90" />
        <el-table-column prop="content" label="检查内容" min-width="220" show-overflow-tooltip />
        <el-table-column prop="handling" label="整改措施" min-width="180" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="110">
          <template #default="{ row }">
            <el-tag :class="['status-tag', `status-${row.status.toLowerCase()}`]" effect="plain">{{ statusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="priority" label="优先级" width="90">
          <template #default="{ row }">{{ priorityText(row.priority) }}</template>
        </el-table-column>
        <el-table-column prop="recorder" label="记录人" width="90" />
        <el-table-column prop="recordTime" label="检查时间" width="170" />
        <el-table-column prop="handler" label="整改责任人" width="100" />
        <el-table-column prop="handleTime" label="整改完成时间" width="170" />
        <el-table-column label="操作" width="145" fixed="right">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button size="small" @click="openEditDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" plain @click="removeRow(row.id)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="filteredRows.length"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
        />
      </div>
    </section>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑检查记录' : '新增检查记录'" width="680px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="检查类别">
          <el-select v-model="form.recordType" style="width: 100%">
            <el-option label="生产记录检查" value="PRODUCTION_CHECK" />
            <el-option label="工艺制度稽核" value="PROCESS_AUDIT" />
            <el-option label="实验记录抽查" value="LAB_CHECK" />
            <el-option label="材料消耗复核" value="MATERIAL_REVIEW" />
          </el-select>
        </el-form-item>
        <el-form-item label="班次">
          <el-select v-model="form.shift" style="width: 100%">
            <el-option label="白班" value="白班" />
            <el-option label="中班" value="中班" />
            <el-option label="夜班" value="夜班" />
          </el-select>
        </el-form-item>
        <el-form-item label="检查内容"><el-input v-model="form.content" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="整改措施"><el-input v-model="form.handling" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width: 100%">
            <el-option label="待处理" value="OPEN" />
            <el-option label="整改中" value="IN_PROGRESS" />
            <el-option label="已闭环" value="CLOSED" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级">
          <el-select v-model="form.priority" style="width: 100%">
            <el-option label="高" value="HIGH" />
            <el-option label="中" value="MEDIUM" />
            <el-option label="低" value="LOW" />
          </el-select>
        </el-form-item>
        <el-form-item label="记录人"><el-input v-model="form.recorder" /></el-form-item>
        <el-form-item label="检查时间">
          <el-date-picker v-model="form.recordTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%" />
        </el-form-item>
        <el-form-item label="整改责任人"><el-input v-model="form.handler" /></el-form-item>
        <el-form-item label="整改完成时间">
          <el-date-picker v-model="form.handleTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveRow">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  createDispatchRecord,
  deleteDispatchRecord,
  listDispatchRecords,
  updateDispatchRecord,
  type DispatchRecordDto,
} from '../../api/coal-business'

type CheckStatus = 'OPEN' | 'IN_PROGRESS' | 'CLOSED'
type CheckPriority = 'HIGH' | 'MEDIUM' | 'LOW'
type CheckType = 'PRODUCTION_CHECK' | 'PROCESS_AUDIT' | 'LAB_CHECK' | 'MATERIAL_REVIEW'

const rows = ref<DispatchRecordDto[]>([])
const page = ref(1)
const pageSize = ref(10)
const filters = reactive({ keyword: '', shift: '', status: '', date: '' })
const dialogVisible = ref(false)
const editingId = ref<number | null>(null)

const createDefaultForm = () => ({
  shift: '白班',
  recordType: 'PRODUCTION_CHECK' as CheckType,
  content: '',
  handling: '',
  recorder: '',
  recordTime: new Date().toISOString().slice(0, 19).replace('T', ' '),
  handler: '',
  handleTime: '',
  status: 'OPEN' as CheckStatus,
  priority: 'MEDIUM' as CheckPriority,
})

const form = ref(createDefaultForm())

const typeText = (value: string) =>
  ({
    PRODUCTION_CHECK: '生产记录检查',
    PROCESS_AUDIT: '工艺制度稽核',
    LAB_CHECK: '实验记录抽查',
    MATERIAL_REVIEW: '材料消耗复核',
  })[value] || value

const statusText = (value: string) =>
  ({
    OPEN: '待处理',
    IN_PROGRESS: '整改中',
    CLOSED: '已闭环',
  })[value] || value

const priorityText = (value: string) =>
  ({
    HIGH: '高',
    MEDIUM: '中',
    LOW: '低',
  })[value] || value

const filteredRows = computed(() =>
  rows.value.filter((item) => {
    const keyword = filters.keyword.trim()
    const matchKeyword =
      !keyword || item.content?.includes(keyword) || item.recordNo?.includes(keyword) || item.handling?.includes(keyword)
    const matchShift = !filters.shift || item.shift === filters.shift
    const matchStatus = !filters.status || item.status === filters.status
    const matchDate = !filters.date || (item.recordTime || '').startsWith(filters.date)
    return matchKeyword && matchShift && matchStatus && matchDate
  }),
)

const pagedRows = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return filteredRows.value.slice(start, start + pageSize.value)
})

const stats = computed(() => {
  const total = filteredRows.value.length
  const open = filteredRows.value.filter((item) => item.status === 'OPEN').length
  const progress = filteredRows.value.filter((item) => item.status === 'IN_PROGRESS').length
  const closed = filteredRows.value.filter((item) => item.status === 'CLOSED').length
  return { total, open, progress, closed }
})

const nextRecordNo = () => `PC${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${String(rows.value.length + 1).padStart(3, '0')}`

const loadRowsFromServer = async () => {
  try {
    const apiRows = await listDispatchRecords({
      shift: filters.shift || undefined,
      status: filters.status || undefined,
      date: filters.date || undefined,
    })
    rows.value = apiRows.filter((item) =>
      ['PRODUCTION_CHECK', 'PROCESS_AUDIT', 'LAB_CHECK', 'MATERIAL_REVIEW'].includes(item.recordType),
    )
  } catch {
    rows.value = []
    ElMessage.error('后端检查台账不可用，请检查服务或数据库连接')
  }
}

const openCreateDialog = () => {
  editingId.value = null
  form.value = createDefaultForm()
  dialogVisible.value = true
}

const openEditDialog = (row: DispatchRecordDto) => {
  editingId.value = Number(row.id || 0)
  form.value = {
    shift: row.shift || '白班',
    recordType: (row.recordType as CheckType) || 'PRODUCTION_CHECK',
    content: row.content || '',
    handling: row.handling || '',
    recorder: row.recorder || '',
    recordTime: row.recordTime || '',
    handler: row.handler || '',
    handleTime: row.handleTime || '',
    status: (row.status as CheckStatus) || 'OPEN',
    priority: (row.priority as CheckPriority) || 'MEDIUM',
  }
  dialogVisible.value = true
}

const saveRow = async () => {
  if (!form.value.content.trim()) {
    ElMessage.warning('请填写检查内容')
    return
  }
  if (!form.value.recorder.trim()) {
    ElMessage.warning('请填写记录人')
    return
  }
  if (!form.value.recordTime) {
    ElMessage.warning('请填写检查时间')
    return
  }

  const payload: DispatchRecordDto = {
    id: editingId.value || undefined,
    recordNo: editingId.value ? rows.value.find((item) => item.id === editingId.value)?.recordNo || nextRecordNo() : nextRecordNo(),
    shift: form.value.shift,
    recordType: form.value.recordType,
    content: form.value.content,
    handling: form.value.handling,
    recorder: form.value.recorder,
    recordTime: form.value.recordTime,
    handler: form.value.handler,
    handleTime: form.value.handleTime,
    status: form.value.status,
    priority: form.value.priority,
  }

  try {
    if (editingId.value) {
      await updateDispatchRecord(payload)
    } else {
      await createDispatchRecord(payload)
    }
    await loadRowsFromServer()
    dialogVisible.value = false
    ElMessage.success(editingId.value ? '检查记录已更新' : '检查记录已新增')
  } catch {
    ElMessage.error('保存失败，请检查后端服务')
  }
}

const removeRow = async (id?: number) => {
  if (!id) return
  try {
    await ElMessageBox.confirm('确认删除该条检查记录？', '提示', { type: 'warning' })
    await deleteDispatchRecord(id)
    await loadRowsFromServer()
    ElMessage.success('已删除')
  } catch {
    // ignore cancel
  }
}

const exportCsv = () => {
  const header = '单号,类别,班次,检查内容,整改措施,状态,优先级,记录人,检查时间,整改责任人,整改完成时间'
  const body = filteredRows.value.map((row) =>
    [
      row.recordNo || '',
      typeText(row.recordType || ''),
      row.shift || '',
      row.content || '',
      row.handling || '',
      statusText(row.status || ''),
      priorityText(row.priority || ''),
      row.recorder || '',
      row.recordTime || '',
      row.handler || '',
      row.handleTime || '',
    ].join(','),
  )
  const csv = [header, ...body].join('\n')
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `生产技术检查台账_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('检查台账 CSV 已导出')
}

onMounted(async () => {
  await loadRowsFromServer()
})
</script>

<style scoped>
.process-check-page{height:100%;overflow:hidden;padding:0;background:#091019;color:#eef6ff}
.page-header,.kpi-grid,.panel{width:min(100%,1680px);margin:0 auto 16px}
.page-header{display:flex;justify-content:space-between;gap:24px;padding:28px 30px;border:1px solid rgba(96,183,255,.12);border-radius:20px;background:rgba(8,19,30,.92)}
.page-tag{margin:0 0 10px;color:#7ecfff;font-size:12px;letter-spacing:.12em}
.page-header h1,.panel-head h2{margin:0}
.page-desc{margin:10px 0 0;color:rgba(227,239,250,.68);line-height:1.7}
.page-actions{display:flex;gap:12px;align-items:flex-start;flex-wrap:wrap}
.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}
.kpi-card,.panel{border:1px solid rgba(96,183,255,.12);border-radius:18px;background:rgba(8,19,30,.92)}
.kpi-card{padding:20px}
.kpi-card span{display:block;color:rgba(227,239,250,.62);font-size:13px}
.kpi-card strong{display:block;margin-top:14px;font-size:34px;color:#f3faff}
.kpi-card small{display:block;margin-top:10px;color:#67d8ff}
.panel{padding:24px}
.panel-head{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;margin-bottom:18px}
.tools{display:flex;gap:12px;flex-wrap:wrap}
.tools :deep(.el-input),.tools :deep(.el-select),.tools :deep(.el-date-editor){width:180px}
.check-table{--el-table-bg-color:transparent;--el-table-tr-bg-color:rgba(11,32,49,.72);--el-table-header-bg-color:rgba(20,52,78,.92);--el-table-border-color:rgba(108,189,255,.12);--el-table-text-color:#e8f4ff;--el-table-header-text-color:#8dd6ff}
.status-tag{border-radius:999px}
.status-open{background:rgba(255,190,74,.16);border-color:rgba(255,190,74,.36);color:#ffd88e}
.status-in_progress{background:rgba(80,180,255,.16);border-color:rgba(80,180,255,.36);color:#9ad8ff}
.status-closed{background:rgba(40,211,160,.16);border-color:rgba(40,211,160,.36);color:#7ff2c9}
.row-actions{display:flex;gap:8px}
.pagination-wrap{display:flex;justify-content:flex-end;margin-top:18px}
@media (max-width:1200px){.kpi-grid{grid-template-columns:repeat(2,1fr)}}
@media (max-width:900px){.kpi-grid{grid-template-columns:1fr}.tools{flex-direction:column}.tools :deep(.el-input),.tools :deep(.el-select),.tools :deep(.el-date-editor){width:100%}}
</style>
