<template>
  <div class="coal-page section-page smart-reagent-page">
    <CoalQuickBar
      title="智能加药"
      subtitle="保留卓朗2算法中的泵频预测、备用泵建议和阀门输出结构，先在扩展功能里形成统一入口。"
      :status="{ text: result?.mode || '演示回退', type: result?.mode === '模型服务' ? 'running' : 'idle' }"
    />

    <section class="page-shell">
      <section class="stats-grid">
        <article class="stat-card">
          <span>预测泵频</span>
          <strong>{{ result?.predPump ?? '--' }}</strong>
          <small>模型输出主泵建议</small>
        </article>
        <article class="stat-card">
          <span>备用泵建议</span>
          <strong>{{ result?.predBackupPump ?? '--' }}</strong>
          <small>0 表示无需切换</small>
        </article>
        <article class="stat-card">
          <span>阀门建议</span>
          <strong>{{ result?.valveMN ?? '--' }}</strong>
          <small>模型输出阀门开度</small>
        </article>
        <article class="stat-card">
          <span>当前状态</span>
          <strong>{{ result?.stateName ?? '--' }}</strong>
          <small>主泵与加药控制状态</small>
        </article>
      </section>

      <section class="panel-grid">
        <section class="section-panel">
          <div class="panel-head">
            <div>
              <h2>泵房智控参数面板</h2>
              <p>将底层数组和 JSON 参数转换为可读的泵频、阀门和运行状态卡片。</p>
            </div>
            <div class="panel-actions">
              <el-select v-model="selectedUnit" style="width: 160px" @change="applyTemplate">
                <el-option v-for="unit in reagentUnits" :key="unit.value" :label="unit.label" :value="unit.value" />
              </el-select>
              <el-button @click="applyTemplate">切换参数</el-button>
              <el-button type="primary" :loading="loading" @click="runPredict">调用模型</el-button>
            </div>
          </div>
          <div class="pump-overview">
            <article class="pump-card">
              <span>主泵频率</span>
              <strong>{{ result?.predPump ?? '--' }} <small>Hz</small></strong>
              <p>预测频率随矿浆密度动态调整</p>
            </article>
            <article class="pump-card">
              <span>阀门开度</span>
              <strong>{{ result?.valveMN ?? '--' }} <small>%</small></strong>
              <p>阀门输出与主泵联动</p>
            </article>
            <article class="pump-card">
              <span>备用泵切换</span>
              <strong class="switch-text" :class="{ 'is-on': Number(currentParams.backupPumpNumber) > 0 }">{{ Number(currentParams.backupPumpNumber) > 0 ? '已预备' : '未启用' }}</strong>
              <p>备用泵编号 {{ currentParams.backupPumpNumber ?? '--' }}</p>
            </article>
            <article class="pump-card">
              <span>智能联动</span>
              <strong class="switch-text" :class="{ 'is-on': Number(currentParams.update_ctrl) === 1 }">{{ Number(currentParams.update_ctrl) === 1 ? '开启' : '关闭' }}</strong>
              <p>{{ Number(currentParams.run_state) === 0 ? '自动模式' : '手动模式' }}</p>
            </article>
          </div>
        </section>

        <section class="section-panel">
          <div class="panel-head">
            <div>
              <h2>加药单元概览</h2>
              <p>展示四个加药单元的当前状态、泵频和备用泵信息。</p>
            </div>
            <el-button @click="loadOverview">刷新概览</el-button>
          </div>
          <el-table :data="overviewRows">
            <el-table-column prop="unit" label="单元" width="90" />
            <el-table-column prop="area" label="区域" min-width="140" />
            <el-table-column prop="status" label="状态" width="110" />
            <el-table-column prop="pump" label="泵频" width="100" />
            <el-table-column prop="backupPump" label="备用泵" width="100" />
            <el-table-column prop="valve" label="阀门" width="100" />
            <el-table-column prop="mode" label="模式" width="110" />
          </el-table>
        </section>
      </section>

      <section class="section-panel">
        <div class="panel-head">
          <div>
            <h2>加药结果可视化</h2>
            <p>主泵/备用泵加药量堆叠展示，同时叠加药剂成本趋势线。</p>
          </div>
        </div>
        <div ref="chartEl" class="chart-box"></div>
      </section>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
import { echarts, INDUSTRIAL_CHART_COLORS } from '../../utils/echarts'
import { useIotHub } from '../../composables/useIotHub'
import {
  getSmartReagentOverview,
  predictSmartReagent,
  type SmartReagentPredictResult,
  type SmartReagentUnitDto,
} from '../../api/coal-business'

const reagentUnits = [
  { label: '601 末煤一号', value: '601' },
  { label: '602 末煤二号', value: '602' },
  { label: '5201 块煤一号', value: '5201' },
  { label: '5202 块煤二号', value: '5202' },
]

const templates: Record<string, { dataLong: number[]; dataShort: number[]; params: Record<string, any> }> = {
  '601': {
    dataLong: [1.43, 0.42, 18.5, 42, 1, 2850, 11.8],
    dataShort: [1.43, 0.41, 18, 40, 0],
    params: { pumpNumber: 1, backupPumpNumber: 0, density_setpoint: 1.43, update_ctrl: 1, run_state: 0 },
  },
  '602': {
    dataLong: [1.45, 0.44, 20.1, 45, 0, 2960, 12.6],
    dataShort: [1.45, 0.43, 20, 44, 0],
    params: { pumpNumber: 2, backupPumpNumber: 0, density_setpoint: 1.45, update_ctrl: 1, run_state: 0 },
  },
  '5201': {
    dataLong: [1.40, 0.38, 16.2, 38, 1, 2320, 9.6],
    dataShort: [1.40, 0.37, 16, 37, 1],
    params: { pumpNumber: 5, backupPumpNumber: 1, density_setpoint: 1.40, update_ctrl: 1, run_state: 0 },
  },
  '5202': {
    dataLong: [1.41, 0.39, 17.4, 40, 0, 2400, 9.8],
    dataShort: [1.41, 0.38, 17, 39, 0],
    params: { pumpNumber: 6, backupPumpNumber: 0, density_setpoint: 1.41, update_ctrl: 1, run_state: 0 },
  },
}

const selectedUnit = ref('601')
const overviewRows = ref<SmartReagentUnitDto[]>([])
const result = ref<SmartReagentPredictResult | null>(null)
const loading = ref(false)
const chartEl = ref<HTMLElement | null>(null)
let chart: any = null
const currentTemplate = computed(() => templates[selectedUnit.value])
const currentParams = computed(() => currentTemplate.value.params)
const iotHub = useIotHub()
const analogTags = {
  pumpFreq: 'coal.kep.analog.27426c0853a2b547', // 338清水泵频率反馈
  valve: 'coal.kep.analog.7014082b6f33a101', // 重介系统分流阀FK
  reagent1: 'coal.kep.analog.ea31bfc734c66c92', // 药剂消耗1瞬时量
  reagent2: 'coal.kep.analog.52868c9cdeb416f0', // 药剂消耗2瞬时量
}

function applyTemplate() {
  // 由模板直接驱动，避免底层 JSON 暴露在页面上
}
const getLiveValue = (tagCode: string, fallback: number) => {
  const live = iotHub.getTagValue(tagCode)?.value
  return typeof live === 'number' && Number.isFinite(live) ? live : fallback
}

async function loadOverview() {
  try {
    const data = await getSmartReagentOverview()
    overviewRows.value = data.units
  } catch {
    const pump = Number(getLiveValue(analogTags.pumpFreq, 42).toFixed(1))
    const valve = Number(getLiveValue(analogTags.valve, 18).toFixed(1))
    overviewRows.value = [
      { unit: '601', area: '末煤一号加药泵', status: '运行中', pump: `${pump}`, backupPump: '0', valve: `${valve}`, mode: '实时点位回退' },
      { unit: '602', area: '末煤二号加药泵', status: '运行中', pump: `${(pump + 2).toFixed(0)}`, backupPump: '0', valve: `${(valve + 2).toFixed(0)}`, mode: '实时点位回退' },
      { unit: '5201', area: '块煤一号加药泵', status: '待观察', pump: `${Math.max(0, pump - 4).toFixed(0)}`, backupPump: '1', valve: `${Math.max(0, valve - 2).toFixed(0)}`, mode: '实时点位回退' },
      { unit: '5202', area: '块煤二号加药泵', status: '运行中', pump: `${Math.max(0, pump - 2).toFixed(0)}`, backupPump: '0', valve: `${Math.max(0, valve - 1).toFixed(0)}`, mode: '实时点位回退' },
    ]
  }
}

async function runPredict() {
  try {
    loading.value = true
    const template = currentTemplate.value
    const payload = {
      unit: selectedUnit.value,
      dataLong: template.dataLong,
      dataShort: template.dataShort,
      params: template.params,
    }
    result.value = await predictSmartReagent(payload)
    await nextTick()
    renderChart()
    ElMessage.success(`智能加药 ${selectedUnit.value} 调用完成`)
  } catch (error: any) {
    const pump = Number(getLiveValue(analogTags.pumpFreq, 42).toFixed(1))
    const valve = Number(getLiveValue(analogTags.valve, 18).toFixed(1))
    const backup = Number(getLiveValue(analogTags.reagent2, 0).toFixed(1))
    result.value = {
      unit: selectedUnit.value,
      predPump: pump,
      numPump: 1,
      predBackupPump: backup,
      valveMN: valve,
      state: backup > 0 ? 1 : 0,
      stateName: backup > 0 ? '备用泵待命' : '备用泵未启用',
      mode: '实时点位回退',
    }
    await nextTick()
    renderChart()
    ElMessage.error(error?.message || '智能加药调用失败')
  } finally {
    loading.value = false
  }
}

function renderChart() {
  if (!chartEl.value || !result.value) return
  chart?.dispose()
  chart = echarts.init(chartEl.value)
  const unitList = ['主泵一线', '主泵二线', '主泵三线', '主泵四线']
  const mainDose = unitList.map((_, index) => Number((Number(result.value!.predPump) * (0.8 + index * 0.06)).toFixed(1)))
  const backupDose = unitList.map((_, index) => Number((Number(result.value!.predBackupPump) * (0.4 + index * 0.08)).toFixed(1)))
  const costLine = unitList.map((_, index) => Number((mainDose[index] * 0.42 + backupDose[index] * 0.3 + Number(result.value!.valveMN) * 0.18).toFixed(1)))
  chart.setOption({
    tooltip: { trigger: 'axis' },
    xAxis: {
      type: 'category',
      data: unitList,
      axisLabel: { color: INDUSTRIAL_CHART_COLORS.axis },
    },
    yAxis: [
      {
        type: 'value',
        name: '加药量',
        axisLabel: { color: INDUSTRIAL_CHART_COLORS.axis },
        splitLine: { lineStyle: { color: INDUSTRIAL_CHART_COLORS.grid } },
      },
      {
        type: 'value',
        name: '成本',
        axisLabel: { color: INDUSTRIAL_CHART_COLORS.axis },
        splitLine: { show: false },
      },
    ],
    grid: { left: '3%', right: '4%', top: '8%', bottom: '8%', containLabel: true },
    series: [
      {
        name: '主泵加药量',
        type: 'bar',
        stack: 'dose',
        data: mainDose,
        itemStyle: {
          color: INDUSTRIAL_CHART_COLORS.primary,
          borderRadius: [8, 8, 0, 0],
        },
      },
      {
        name: '备用泵加药量',
        type: 'bar',
        stack: 'dose',
        data: backupDose,
        itemStyle: {
          color: INDUSTRIAL_CHART_COLORS.warning,
          borderRadius: [8, 8, 0, 0],
        },
      },
      {
        name: '总药剂成本',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: costLine,
        lineStyle: { color: INDUSTRIAL_CHART_COLORS.secondary, width: 3 },
        itemStyle: { color: INDUSTRIAL_CHART_COLORS.secondary },
      },
    ],
  })
}

const handleResize = () => chart?.resize()

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'smart-reagent', intervalMs: 5000 })
  await iotHub.ensureFresh('smart-reagent', 2000)
  applyTemplate()
  await loadOverview()
  await runPredict()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  chart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.section-page{height:100%;min-height:0;overflow:auto;padding:12px 14px 18px;background:#091019;color:#eef6ff}
.page-shell{width:min(100%,1680px);margin:0 auto;display:block}
.smart-reagent-page .page-shell>.stats-grid{max-height:none !important;overflow:visible !important}
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px}
.stat-card,.section-panel{padding:22px;border-radius:20px;border:1px solid rgba(122,190,255,.12);background:rgba(12,20,31,.92);box-shadow:0 18px 40px rgba(0,0,0,.16)}
.stat-card{display:flex;flex-direction:column;gap:8px;justify-content:space-between;min-height:118px}
.stat-card span{display:block;color:#97aabc;font-size:12px}
.stat-card strong{display:block;font-size:30px;line-height:1.15}
.stat-card small{display:block;color:#6ec8ff;font-size:12px;line-height:1.4}
.panel-grid{display:grid;grid-template-columns:1.2fr .9fr;gap:20px;margin-bottom:20px}
.panel-head{display:flex;justify-content:space-between;align-items:flex-start;gap:20px;margin-bottom:16px}
.panel-head h2{margin:0;font-size:24px}
.panel-head p{margin:8px 0 0;color:#8fa8bc}
.panel-actions{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.pump-overview{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.pump-card{padding:14px;border-radius:12px;border:1px solid rgba(122,190,255,.16);background:rgba(16,33,50,.72)}
.pump-card span{display:block;color:#9bc2df;font-size:12px}
.pump-card strong{display:block;margin-top:8px;font-size:30px}
.pump-card strong small{font-size:14px;color:#9bc2df}
.pump-card p{margin:8px 0 0;color:#8fb5d3;font-size:12px}
.switch-text{color:#ff7b7b}
.switch-text.is-on{color:#73e9ad}
.chart-box{height:320px}
@media (max-width: 1200px){.stats-grid,.panel-grid,.pump-overview{grid-template-columns:1fr}}
</style>
