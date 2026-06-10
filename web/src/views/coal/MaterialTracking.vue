<template>
  <div class="material-page">
    <section class="page-header">
      <div>
        <p class="page-tag">生产运行 / 原材料跟踪</p>
        <h1>原材料详细跟踪台账</h1>
        <p class="page-desc">覆盖入库、出库、领用全过程，支持按批次追溯、库存核算与班组消耗统计。</p>
      </div>
      <div class="page-actions">
        <el-button @click="openCreateDialog('INBOUND')">入库登记</el-button>
        <el-button @click="openCreateDialog('OUTBOUND')">出库登记</el-button>
        <el-button type="primary" @click="openCreateDialog('ISSUE')">领用登记</el-button>
      </div>
    </section>

    <section class="kpi-grid">
      <article class="kpi-card">
        <span>当日入库</span>
        <strong>{{ stats.inbound.toFixed(1) }} 吨</strong>
        <small>包含原煤、药剂、油脂等原材料</small>
      </article>
      <article class="kpi-card">
        <span>当日出库</span>
        <strong>{{ stats.outbound.toFixed(1) }} 吨</strong>
        <small>按去向自动归集</small>
      </article>
      <article class="kpi-card">
        <span>当班领用</span>
        <strong>{{ stats.issue.toFixed(1) }} 吨</strong>
        <small>班组领用实时更新</small>
      </article>
      <article class="kpi-card">
        <span>台账结余</span>
        <strong>{{ stats.balance.toFixed(1) }} 吨</strong>
        <small>入库 - 出库 - 领用</small>
      </article>
    </section>

    <section class="panel">
      <div class="panel-head">
        <h2>原材料流转记录</h2>
        <div class="tools">
          <el-input v-model="filters.keyword" placeholder="物料名称 / 批次号" clearable />
          <el-select v-model="filters.type" clearable placeholder="类型">
            <el-option label="入库" value="INBOUND" />
            <el-option label="出库" value="OUTBOUND" />
            <el-option label="领用" value="ISSUE" />
          </el-select>
          <el-date-picker v-model="filters.bizDate" type="date" value-format="YYYY-MM-DD" placeholder="业务日期" />
          <el-button type="primary" @click="loadRowsFromServer">查询</el-button>
          <el-button @click="exportCsv">导出 CSV</el-button>
        </div>
      </div>

      <el-table :data="pagedRows" class="ledger-table">
        <el-table-column prop="recordNo" label="单号" min-width="150" />
        <el-table-column prop="recordType" label="类型" width="90">
          <template #default="{ row }">
            <el-tag :class="['type-tag', `type-${row.recordType.toLowerCase()}`]" effect="plain">{{ typeText(row.recordType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="materialName" label="物料名称" min-width="140" />
        <el-table-column prop="specification" label="规格型号" min-width="130" />
        <el-table-column prop="batchNo" label="批次号" min-width="140" />
        <el-table-column prop="quantity" label="数量" width="100" />
        <el-table-column prop="unit" label="单位" width="80" />
        <el-table-column prop="warehouse" label="仓库/库位" min-width="120" />
        <el-table-column prop="target" label="去向/用途" min-width="140" />
        <el-table-column prop="operator" label="经办人" width="90" />
        <el-table-column prop="bizDate" label="业务日期" width="110" />
        <el-table-column prop="remark" label="备注" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="140" fixed="right">
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

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑台账记录' : '新增台账记录'" width="640px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="记录类型">
          <el-select v-model="form.recordType" style="width: 100%">
            <el-option label="入库" value="INBOUND" />
            <el-option label="出库" value="OUTBOUND" />
            <el-option label="领用" value="ISSUE" />
          </el-select>
        </el-form-item>
        <el-form-item label="物料名称"><el-input v-model="form.materialName" /></el-form-item>
        <el-form-item label="规格型号"><el-input v-model="form.specification" /></el-form-item>
        <el-form-item label="批次号"><el-input v-model="form.batchNo" /></el-form-item>
        <el-form-item label="数量"><el-input-number v-model="form.quantity" :min="0" :precision="2" style="width: 100%" /></el-form-item>
        <el-form-item label="单位"><el-input v-model="form.unit" /></el-form-item>
        <el-form-item label="仓库/库位"><el-input v-model="form.warehouse" /></el-form-item>
        <el-form-item label="去向/用途"><el-input v-model="form.target" /></el-form-item>
        <el-form-item label="经办人"><el-input v-model="form.operator" /></el-form-item>
        <el-form-item label="业务日期">
          <el-date-picker v-model="form.bizDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" /></el-form-item>
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
  createStorageTransport,
  deleteStorageTransport,
  listStorageTransports,
  updateStorageTransport,
  type StorageTransportDto,
} from '../../api/coal-business'

type RecordType = 'INBOUND' | 'OUTBOUND' | 'ISSUE'
type LedgerRow = {
  id: number
  recordNo: string
  recordType: RecordType
  materialName: string
  specification: string
  batchNo: string
  quantity: number
  unit: string
  warehouse: string
  target: string
  operator: string
  bizDate: string
  remark: string
}

const rows = ref<LedgerRow[]>([])
const page = ref(1)
const pageSize = ref(10)
const filters = reactive({ keyword: '', type: '', bizDate: '' })
const dialogVisible = ref(false)
const editingId = ref<number | null>(null)

const createDefaultForm = (): Omit<LedgerRow, 'id' | 'recordNo'> => ({
  recordType: 'INBOUND',
  materialName: '',
  specification: '',
  batchNo: '',
  quantity: 0,
  unit: '吨',
  warehouse: '',
  target: '',
  operator: '',
  bizDate: new Date().toISOString().slice(0, 10),
  remark: '',
})

const form = ref<Omit<LedgerRow, 'id' | 'recordNo'>>(createDefaultForm())

const typeText = (value: RecordType) => ({ INBOUND: '入库', OUTBOUND: '出库', ISSUE: '领用' }[value] || value)
const mapTypeToApi = (value: RecordType) => ({ INBOUND: 'RAW_IN', OUTBOUND: 'PRODUCT_OUT', ISSUE: 'LOADING' }[value])
const mapTypeFromApi = (value: string): RecordType => {
  if (value === 'RAW_IN') return 'INBOUND'
  if (value === 'PRODUCT_OUT') return 'OUTBOUND'
  return 'ISSUE'
}

const encodeMeta = (row: Omit<LedgerRow, 'id' | 'recordNo'>) => `spec=${row.specification};batch=${row.batchNo};unit=${row.unit}`
const decodeMeta = (value?: string) => {
  const map = new Map<string, string>()
  ;(value || '').split(';').forEach((item) => {
    const [k, ...rest] = item.split('=')
    if (k && rest.length) map.set(k, rest.join('='))
  })
  return {
    specification: map.get('spec') || '',
    batchNo: map.get('batch') || '',
    unit: map.get('unit') || '吨',
  }
}

const mapApiToRow = (item: StorageTransportDto): LedgerRow => {
  const meta = decodeMeta(item.qualityIndex)
  return {
    id: Number(item.id || Date.now()),
    recordNo: item.recordNo || '',
    recordType: mapTypeFromApi(item.recordType || 'LOADING'),
    materialName: item.coalType || '',
    specification: meta.specification,
    batchNo: meta.batchNo,
    quantity: Number(item.quantity || 0),
    unit: meta.unit,
    warehouse: item.loadingStation || '',
    target: item.sourceOrDest || '',
    operator: item.operator || '',
    bizDate: (item.recordTime || '').slice(0, 10),
    remark: item.remark || '',
  }
}

const buildApiPayload = (row: Omit<LedgerRow, 'id' | 'recordNo'>, id?: number, recordNo?: string): StorageTransportDto => ({
  id,
  recordType: mapTypeToApi(row.recordType),
  recordNo: recordNo || nextRecordNo(),
  coalType: row.materialName,
  quantity: Number(row.quantity || 0),
  recordTime: `${row.bizDate}T08:00:00`,
  sourceOrDest: row.target,
  transportMode: 'TRUCK',
  loadingStation: row.warehouse,
  operator: row.operator || '系统用户',
  status: 'COMPLETED',
  qualityIndex: encodeMeta(row),
  remark: row.remark,
})

const filteredRows = computed(() =>
  rows.value.filter((item) => {
    const keyword = filters.keyword.trim()
    const matchKeyword =
      !keyword ||
      item.materialName.includes(keyword) ||
      item.batchNo.includes(keyword) ||
      item.recordNo.includes(keyword)
    const matchType = !filters.type || item.recordType === filters.type
    const matchDate = !filters.bizDate || item.bizDate === filters.bizDate
    return matchKeyword && matchType && matchDate
  }),
)

const pagedRows = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return filteredRows.value.slice(start, start + pageSize.value)
})

const stats = computed(() => {
  const sumByType = (type: RecordType) =>
    filteredRows.value.filter((item) => item.recordType === type).reduce((sum, item) => sum + item.quantity, 0)
  const inbound = sumByType('INBOUND')
  const outbound = sumByType('OUTBOUND')
  const issue = sumByType('ISSUE')
  return { inbound, outbound, issue, balance: inbound - outbound - issue }
})

const nextRecordNo = () => `RM${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${String(rows.value.length + 1).padStart(3, '0')}`

const loadRowsFromServer = async () => {
  try {
    const apiRows = await listStorageTransports({
      recordType: filters.type ? mapTypeToApi(filters.type as RecordType) : undefined,
      date: filters.bizDate || undefined,
    })
    rows.value = apiRows.map(mapApiToRow)
  } catch {
    rows.value = []
    ElMessage.error('后端台账不可用，请检查服务或数据库连接')
  }
}

const openCreateDialog = (type: RecordType) => {
  editingId.value = null
  form.value = { ...createDefaultForm(), recordType: type }
  dialogVisible.value = true
}

const openEditDialog = (row: LedgerRow) => {
  editingId.value = row.id
  form.value = {
    recordType: row.recordType,
    materialName: row.materialName,
    specification: row.specification,
    batchNo: row.batchNo,
    quantity: row.quantity,
    unit: row.unit,
    warehouse: row.warehouse,
    target: row.target,
    operator: row.operator,
    bizDate: row.bizDate,
    remark: row.remark,
  }
  dialogVisible.value = true
}

const saveRow = async () => {
  if (!form.value.materialName.trim()) {
    ElMessage.warning('请填写物料名称')
    return
  }
  if (!form.value.batchNo.trim()) {
    ElMessage.warning('请填写批次号')
    return
  }
  if (form.value.quantity <= 0) {
    ElMessage.warning('数量必须大于 0')
    return
  }

  try {
    if (editingId.value) {
      const current = rows.value.find((item) => item.id === editingId.value)
      if (!current) throw new Error('record not found')
      await updateStorageTransport(buildApiPayload(form.value, editingId.value, current.recordNo))
    } else {
      await createStorageTransport(buildApiPayload(form.value))
    }
    await loadRowsFromServer()
    dialogVisible.value = false
    ElMessage.success(editingId.value ? '台账记录已更新' : '台账记录已新增')
  } catch {
    ElMessage.error('保存失败，请检查后端服务')
  }
}

const removeRow = async (id: number) => {
  try {
    await ElMessageBox.confirm('确认删除该条台账记录？', '提示', { type: 'warning' })
    await deleteStorageTransport(id)
    await loadRowsFromServer()
    ElMessage.success('已删除')
  } catch {
    // ignore cancel
  }
}

const exportCsv = () => {
  const header = '单号,类型,物料名称,规格型号,批次号,数量,单位,仓库库位,去向用途,经办人,业务日期,备注'
  const body = filteredRows.value.map((row) =>
    [
      row.recordNo,
      typeText(row.recordType),
      row.materialName,
      row.specification,
      row.batchNo,
      row.quantity,
      row.unit,
      row.warehouse,
      row.target,
      row.operator,
      row.bizDate,
      row.remark,
    ].join(','),
  )
  const csv = [header, ...body].join('\n')
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `原材料跟踪台账_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('台账 CSV 已导出')
}

onMounted(async () => {
  await loadRowsFromServer()
})
</script>

<style scoped>
.material-page{height:100%;overflow:hidden;padding:0;background:#091019;color:#eef6ff}
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
.ledger-table{--el-table-bg-color:transparent;--el-table-tr-bg-color:rgba(11,32,49,.72);--el-table-header-bg-color:rgba(20,52,78,.92);--el-table-border-color:rgba(108,189,255,.12);--el-table-text-color:#e8f4ff;--el-table-header-text-color:#8dd6ff}
.type-tag{border-radius:999px}
.type-inbound{background:rgba(40,211,160,.16);border-color:rgba(40,211,160,.36);color:#7ff2c9}
.type-outbound{background:rgba(255,190,74,.16);border-color:rgba(255,190,74,.36);color:#ffd88e}
.type-issue{background:rgba(80,180,255,.16);border-color:rgba(80,180,255,.36);color:#9ad8ff}
.row-actions{display:flex;gap:8px}
.pagination-wrap{display:flex;justify-content:flex-end;margin-top:18px}
@media (max-width:1200px){.kpi-grid{grid-template-columns:repeat(2,1fr)}}
@media (max-width:900px){.kpi-grid{grid-template-columns:1fr}.tools{flex-direction:column}.tools :deep(.el-input),.tools :deep(.el-select),.tools :deep(.el-date-editor){width:100%}}
</style>
