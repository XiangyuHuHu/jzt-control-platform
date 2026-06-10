<template>
  <div class="storage-v2">
    <section class="hero">
      <div>
        <p class="eyebrow">coal / storage</p>
        <h1>储装运销协调面板</h1>
        <p class="hero-text">围绕原煤入库、产品外运和装车记录，统一查看储装周转节奏和出入库结构。</p>
      </div>
      <el-button type="primary" @click="openCreateDialog">
        <el-icon><Plus /></el-icon>
        新增记录
      </el-button>
    </section>

    <section class="stats-grid">
      <article class="stat-card">
        <div class="stat-main">
          <span>原煤入库</span>
          <strong>{{ statistics.rawCoalStock }}</strong>
          <small>当前筛选累计</small>
        </div>
        <div class="stat-side">
          <el-progress type="circle" :percentage="storageProgress.raw" :width="56" :stroke-width="7" color="#39d4ff">
            <template #default><span class="progress-text">{{ storageProgress.raw }}%</span></template>
          </el-progress>
          <p>对比外运基准</p>
        </div>
      </article>
      <article class="stat-card">
        <div class="stat-main">
          <span>产品外运</span>
          <strong>{{ statistics.productSales }}</strong>
          <small>累计外运吨数</small>
        </div>
        <div class="stat-side">
          <el-progress type="circle" :percentage="storageProgress.product" :width="56" :stroke-width="7" color="#3fe48b">
            <template #default><span class="progress-text">{{ storageProgress.product }}%</span></template>
          </el-progress>
          <p>入库{{ statistics.rawCoalStock || 0 }}吨 / 外运{{ statistics.productSales || 0 }}吨</p>
        </div>
      </article>
      <article class="stat-card">
        <div class="stat-main">
          <span>装车次数</span>
          <strong>{{ statistics.loadingCount }}</strong>
          <small>装车作业频次</small>
        </div>
        <div class="stat-side stat-side--badge">
          <i class="loading-dot" aria-hidden="true"></i>
          <em>今日装车</em>
        </div>
      </article>
      <article class="stat-card">
        <div class="stat-main">
          <span>记录总数</span>
          <strong>{{ filteredList.length }}</strong>
          <small>当前筛选结果</small>
        </div>
        <div class="stat-side">
          <el-tag class="soft-tag">动态更新</el-tag>
          <p>筛选条件实时生效</p>
        </div>
      </article>
    </section>

    <section class="panel level-panel">
      <div class="panel-head">
        <div>
          <p class="eyebrow">silo level</p>
          <h2>关键仓位实时料位</h2>
        </div>
        <small class="level-note">来源：KEPServer 模拟量点位</small>
      </div>
      <div class="level-grid">
        <article v-for="item in siloLevels" :key="item.label" class="level-item">
          <div class="level-head">
            <span>{{ item.label }}</span>
            <strong>{{ item.value.toFixed(1) }}%</strong>
          </div>
          <el-progress :percentage="Math.min(100, Math.max(0, item.value))" :stroke-width="10" :color="item.color" />
        </article>
      </div>
    </section>

    <section class="panel table-panel">
      <div class="panel-head table-head">
        <div>
          <p class="eyebrow">storage ledger</p>
          <h2>储装记录</h2>
        </div>
        <div class="tools">
          <el-select v-model="filterType" placeholder="记录类型" clearable>
            <el-option label="原煤入库" value="RAW_IN" />
            <el-option label="产品外运" value="PRODUCT_OUT" />
            <el-option label="装车记录" value="LOADING" />
          </el-select>
          <el-date-picker v-model="filterDate" type="date" value-format="YYYY-MM-DD" placeholder="选择日期" />
          <el-button @click="exportCsv">导出 CSV</el-button>
        </div>
      </div>

      <div class="mode-alert">
        <i class="mode-dot" aria-hidden="true"></i>
        <span>{{ mockMode ? '当前展示储装仿真台账，正在与生产接口进行联调校核。' : '当前页面已接入实时储装业务数据流。' }}</span>
      </div>

      <el-table :data="pagedList" class="records-table">
        <el-table-column prop="recordNo" label="记录编号" min-width="160" />
        <el-table-column prop="recordType" label="记录类型" width="120">
          <template #default="{ row }">
            <el-tag :class="['type-tag', getTypeClass(row.recordType)]" effect="plain">{{ getTypeText(row.recordType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="coalType" label="煤种" min-width="120" />
        <el-table-column prop="quantity" label="数量(吨)" width="110" />
        <el-table-column prop="transportMode" label="运输方式" width="110">
          <template #default="{ row }">{{ getTransportText(row.transportMode) }}</template>
        </el-table-column>
        <el-table-column prop="vehicleNo" label="车号" min-width="120" />
        <el-table-column prop="customerName" label="客户名称" min-width="150" />
        <el-table-column prop="recordTime" label="记录时间" min-width="170" />
        <el-table-column prop="remark" label="说明" min-width="160" show-overflow-tooltip />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <div class="action-icons">
              <el-button class="icon-btn icon-btn--edit" circle :icon="Edit" @click="openEditDialog(row)" />
              <el-button class="icon-btn icon-btn--delete" circle :icon="Delete" @click="removeItem(row.id)" />
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination v-model:current-page="page" v-model:page-size="pageSize" :total="filteredList.length" :page-sizes="[10,20,50]" layout="total, sizes, prev, pager, next" />
      </div>
    </section>

    <el-dialog v-model="showDialog" :title="editingId ? '编辑记录' : '新增记录'" width="620px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="记录类型">
          <el-select v-model="form.recordType" style="width: 100%">
            <el-option label="原煤入库" value="RAW_IN" />
            <el-option label="产品外运" value="PRODUCT_OUT" />
            <el-option label="装车记录" value="LOADING" />
          </el-select>
        </el-form-item>
        <el-form-item label="煤种"><el-input v-model="form.coalType" /></el-form-item>
        <el-form-item label="数量(吨)"><el-input-number v-model="form.quantity" :min="0" :precision="2" style="width: 100%" /></el-form-item>
        <el-form-item label="运输方式">
          <el-select v-model="form.transportMode" style="width: 100%">
            <el-option label="汽车" value="TRUCK" />
            <el-option label="火车" value="TRAIN" />
            <el-option label="皮带" value="BELT" />
          </el-select>
        </el-form-item>
        <el-form-item label="车号"><el-input v-model="form.vehicleNo" /></el-form-item>
        <el-form-item label="客户名称"><el-input v-model="form.customerName" /></el-form-item>
        <el-form-item label="说明"><el-input v-model="form.remark" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <template #footer><el-button @click="showDialog = false">取消</el-button><el-button type="primary" @click="saveItem">保存</el-button></template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, Edit, Plus } from '@element-plus/icons-vue'
import { createStorageRecords } from '../../mocks/coal'
import { createStorageTransport, deleteStorageTransport, listStorageTransports, updateStorageTransport, type StorageTransportDto } from '../../api/coal-business'
import { useIotHub } from '../../composables/useIotHub'

type StorageRow = { id?: number; recordType: string; recordNo?: string; coalType: string; quantity: number; recordTime?: string; transportMode: string; vehicleNo?: string; customerName?: string; status?: string; remark?: string }
type StorageRecordType = 'RAW_IN' | 'PRODUCT_OUT' | 'LOADING'
type StorageTransportMode = 'TRUCK' | 'TRAIN' | 'BELT'
const createLocalRecords = (): StorageRow[] => createStorageRecords() as StorageRow[]
const list = ref<StorageRow[]>(createLocalRecords()); const page = ref(1); const pageSize = ref(10); const filterType = ref(''); const filterDate = ref('')
const showDialog = ref(false); const editingId = ref<number | null>(null); const mockMode = ref(true)
const iotHub = useIotHub()
const levelTags = {
  rawBuffer: 'coal.kep.analog.ea7742adb16392da', // 原煤缓冲仓料位
  wasteBin: 'coal.kep.analog.3b8582dc37cbf92e', // 矸石仓料位
  product2a: 'coal.kep.analog.6c4126ef642162db', // 产品仓2料位1
  product2b: 'coal.kep.analog.3991180260ef4849', // 产品仓2料位2
  product3a: 'coal.kep.analog.2b3259f8bb6d4032', // 产品仓3料位1
  product3b: 'coal.kep.analog.0b826048d8acd95a', // 产品仓3料位2
  product4a: 'coal.kep.analog.ede73be7fd89e484', // 产品仓4料位1
  product4b: 'coal.kep.analog.41c3191b0b790fc3', // 产品仓4料位2
}
const createDefaultForm = (): StorageRow => ({ recordType: 'RAW_IN', coalType: '', quantity: 0, transportMode: 'TRUCK', vehicleNo: '', customerName: '', status: 'COMPLETED', remark: '' })
const form = ref<StorageRow>(createDefaultForm())
const getTypeText = (type: StorageRecordType | string) => ({ RAW_IN: '原煤入库', PRODUCT_OUT: '产品外运', LOADING: '装车记录' }[type] || type)
const getTypeClass = (type: StorageRecordType | string) => ({ RAW_IN: 'type-raw', PRODUCT_OUT: 'type-out', LOADING: 'type-loading' }[type] || 'type-raw')
const getTransportText = (mode: StorageTransportMode | string) => ({ TRUCK: '汽车', TRAIN: '火车', BELT: '皮带' }[mode] || mode)
const filteredList = computed(() => list.value.filter((item) => (!filterType.value || item.recordType === filterType.value) && (!filterDate.value || item.recordTime?.startsWith(filterDate.value))))
const pagedList = computed(() => filteredList.value.slice((page.value - 1) * pageSize.value, page.value * pageSize.value))
const statistics = computed(() => ({
  rawCoalStock: filteredList.value.filter((item) => item.recordType === 'RAW_IN').reduce((sum, item) => sum + Number(item.quantity || 0), 0),
  productSales: filteredList.value.filter((item) => item.recordType === 'PRODUCT_OUT').reduce((sum, item) => sum + Number(item.quantity || 0), 0),
  loadingCount: filteredList.value.filter((item) => item.recordType === 'LOADING').length,
}))
const storageProgress = computed(() => {
  const base = Math.max(statistics.value.rawCoalStock, statistics.value.productSales, 1)
  return {
    raw: Math.min(100, Math.round((statistics.value.rawCoalStock / base) * 100)),
    product: Math.min(100, Math.round((statistics.value.productSales / base) * 100)),
  }
})
const getNumericTag = (tagCode: string, fallback: number) => {
  const live = iotHub.getTagValue(tagCode)?.value
  return typeof live === 'number' && Number.isFinite(live) ? live : fallback
}
const avg = (a: number, b: number) => Number(((a + b) / 2).toFixed(1))
const siloLevels = computed(() => {
  const p2 = avg(getNumericTag(levelTags.product2a, 61), getNumericTag(levelTags.product2b, 58))
  const p3 = avg(getNumericTag(levelTags.product3a, 54), getNumericTag(levelTags.product3b, 51))
  const p4 = avg(getNumericTag(levelTags.product4a, 47), getNumericTag(levelTags.product4b, 45))
  return [
    { label: '原煤缓冲仓', value: getNumericTag(levelTags.rawBuffer, 66), color: '#3ec8ff' },
    { label: '矸石仓', value: getNumericTag(levelTags.wasteBin, 43), color: '#9fb0c6' },
    { label: '产品仓2', value: p2, color: '#49e39a' },
    { label: '产品仓3', value: p3, color: '#59dcb4' },
    { label: '产品仓4', value: p4, color: '#7fe1a7' },
  ]
})
const mapStorageResponse = (item: StorageTransportDto): StorageRow => ({ id: item.id, recordType: item.recordType, recordNo: item.recordNo, coalType: item.coalType, quantity: Number(item.quantity || 0), recordTime: item.recordTime?.replace('T',' ').slice(0,19), transportMode: item.transportMode, vehicleNo: item.vehicleNo || '', customerName: item.customerName || '', status: item.status || 'COMPLETED', remark: item.remark || '' })
const buildStoragePayload = (row: StorageRow): StorageTransportDto => ({ id: row.id, recordType: row.recordType, recordNo: row.recordNo || `SZ${new Date().toISOString().slice(0,10).replace(/-/g,'')}${String(list.value.length + 1).padStart(3,'0')}`, coalType: row.coalType, quantity: Number(row.quantity || 0), recordTime: (row.recordTime || new Date().toISOString().slice(0,19)).replace(' ','T'), transportMode: row.transportMode, vehicleNo: row.vehicleNo || '', customerName: row.customerName || '', status: row.status || 'COMPLETED', remark: row.remark || '' })
const loadStorageData = async () => { try { const response = await listStorageTransports(); list.value = response.map(mapStorageResponse); mockMode.value = false } catch { list.value = createLocalRecords(); mockMode.value = true } }
const openCreateDialog = () => { editingId.value = null; form.value = createDefaultForm(); showDialog.value = true }
const openEditDialog = (row: StorageRow) => { editingId.value = row.id ?? null; form.value = { ...row }; showDialog.value = true }
const saveItem = async () => {
  const payload = buildStoragePayload(form.value)
  try {
    if (mockMode.value) {
      const next = mapStorageResponse({ ...payload, id: editingId.value || Date.now() }); if (editingId.value) { const index = list.value.findIndex((item) => item.id === editingId.value); if (index !== -1) list.value[index] = next } else list.value.unshift(next)
    } else {
      const saved = editingId.value ? await updateStorageTransport({ ...payload, id: editingId.value }) : await createStorageTransport(payload)
      const next = mapStorageResponse(saved); if (editingId.value) { const index = list.value.findIndex((item) => item.id === editingId.value); if (index !== -1) list.value[index] = next } else list.value.unshift(next)
    }
    ElMessage.success(editingId.value ? '记录已更新' : '记录已新增'); showDialog.value = false
  } catch { ElMessage.error('记录保存失败') }
}
const removeItem = async (id?: number) => { if (!id) return; try { await ElMessageBox.confirm('确认删除该记录？', '提示', { type: 'warning' }); if (!mockMode.value) await deleteStorageTransport(id); list.value = list.value.filter((item) => item.id !== id); ElMessage.success('已删除') } catch (error) { if (error !== 'cancel') ElMessage.error('删除失败') } }

const exportCsv = () => {
  const header = '记录编号,记录类型,煤种,数量(吨),运输方式,车号,客户名称,记录时间,说明'
  const rows = filteredList.value.map((r: any) => `${r.recordNo},${getTypeText(r.recordType)},${r.coalType},${r.quantity},${getTransportText(r.transportMode)},${r.vehicleNo || ''},${r.customerName || ''},${r.recordTime},${r.remark || ''}`)
  const csv = [header, ...rows].join('\n')
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url; a.download = `储装记录_${new Date().toISOString().slice(0, 10)}.csv`; a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('储装记录 CSV 已下载')
}

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'storage-v2', intervalMs: 5000 })
  await iotHub.ensureFresh('storage-v2', 2000)
  loadStorageData()
})
</script>

<style scoped>
.storage-v2{min-height:100%;width:min(100%,1800px);margin:0 auto;padding:20px 20px 28px;background:radial-gradient(circle at top right,rgba(73,173,255,.16),transparent 24%),radial-gradient(circle at left center,rgba(0,255,191,.08),transparent 22%),#06131f;color:#ecf6ff}
.hero,.panel,.stat-card{border:1px solid rgba(106,188,255,.14);background:rgba(7,22,36,.88);box-shadow:0 20px 50px rgba(0,0,0,.24),inset 0 1px 0 rgba(140,205,255,.08)}
.hero{display:grid;grid-template-columns:1.6fr auto;gap:24px;padding:24px 26px;border-radius:24px}.eyebrow{margin:0 0 8px;color:#7bc8ff;font-size:12px;letter-spacing:.22em;text-transform:uppercase}.hero h1,.panel-head h2{margin:0}.hero h1{font-size:32px;line-height:1.08}.hero-text{max-width:760px;color:rgba(229,243,255,.72);line-height:1.7}
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin-top:18px}
.stat-card{padding:14px 16px;border-radius:20px;background:rgba(11,32,49,.88);display:flex;justify-content:space-between;align-items:center;min-height:112px}
.stat-main{min-width:0}
.stat-card span{color:rgba(230,243,255,.58);font-size:12px}
.stat-card strong{display:block;margin-top:6px;font-size:30px;color:#8bd8ff;line-height:1}
.stat-card small{display:block;margin-top:6px;color:#61b8de;font-size:12px}
.stat-side{display:flex;flex-direction:column;align-items:center;gap:6px;min-width:92px}
.stat-side p{margin:0;font-size:11px;color:#87c5e8;text-align:center;line-height:1.2}
.progress-text{font-size:11px;color:#d5edff}
.stat-side--badge{justify-content:center}
.loading-dot{width:12px;height:12px;border-radius:50%;background:#ffd54c;box-shadow:0 0 14px rgba(255,213,76,.8);animation:pulse 1.5s ease-in-out infinite}
.stat-side--badge em{font-style:normal;color:#ffd972;font-size:12px}
.soft-tag{border-color:rgba(61,163,255,.35);background:rgba(35,82,123,.4);color:#9bd4ff}
.panel{padding:22px;border-radius:24px;margin-top:18px}.panel-head,.table-head{display:flex;justify-content:space-between;align-items:center;gap:16px;margin-bottom:18px}
.level-panel{margin-top:18px}
.level-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px}
.level-item{padding:12px;border-radius:12px;background:rgba(15,38,57,.74);border:1px solid rgba(116,192,255,.16)}
.level-head{display:flex;justify-content:space-between;gap:8px;margin-bottom:10px}
.level-head span{font-size:12px;color:#9fc8e6}
.level-head strong{font-size:16px;color:#d9f2ff}
.level-note{color:#84b9de;font-size:12px}
.tools{display:flex;gap:12px}.tools :deep(.el-select),.tools :deep(.el-date-editor){width:180px}
.mode-alert{margin-bottom:18px;display:flex;align-items:center;gap:10px;min-height:38px;padding:0 14px;border:1px solid rgba(97,182,255,.38);border-radius:10px;background:rgba(22,55,88,.35);color:#9fd5ff}
.mode-dot{width:8px;height:8px;border-radius:50%;background:#3dd8ff;box-shadow:0 0 10px rgba(61,216,255,.75);animation:pulse 1.8s ease-in-out infinite}
.records-table{--el-table-bg-color:transparent;--el-table-tr-bg-color:rgba(11,32,49,.72);--el-table-header-bg-color:rgba(20,52,78,.92);--el-table-border-color:rgba(108,189,255,.12);--el-table-text-color:#e8f4ff;--el-table-header-text-color:#8dd6ff}
.type-tag{border-radius:999px;padding:0 10px;height:24px;line-height:22px;border-width:1px}
.type-raw{background:rgba(148,169,194,.24);border-color:rgba(169,189,213,.35);color:#d9e5f2}
.type-out{background:rgba(16,122,80,.28);border-color:rgba(74,214,157,.42);color:#7ef4c8}
.type-loading{background:rgba(145,108,25,.28);border-color:rgba(239,194,77,.42);color:#ffd972}
.action-icons{display:flex;gap:8px}
.icon-btn{width:26px;height:26px;border:1px solid transparent;background:transparent}
.icon-btn--edit{color:#50bfff;border-color:rgba(80,191,255,.35);background:rgba(31,88,129,.22)}
.icon-btn--delete{color:#ff6a6a;border-color:rgba(255,106,106,.35);background:rgba(128,36,36,.22)}
.pagination-wrap{display:flex;justify-content:flex-end;margin-top:18px}
@keyframes pulse{0%,100%{transform:scale(.92);opacity:.68}50%{transform:scale(1.12);opacity:1}}
@media (max-width:1200px){.hero,.stats-grid{grid-template-columns:1fr}}
@media (max-width:1200px){.level-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media (max-width:768px){.storage-v2{padding:16px}.hero{padding:20px}.hero h1{font-size:28px}.tools,.table-head{flex-direction:column;align-items:stretch}.tools :deep(.el-select),.tools :deep(.el-date-editor){width:100%}}
</style>
