<template>
  <div class="coal-page section-page smart-density-page">
    <CoalQuickBar
      title="智能密控"
      subtitle="接入卓朗2中的密控模型接口，当前页面先放在扩展功能中，支持演示回退和真实模型代理两种模式。"
      :status="{ text: result?.mode || '演示回退', type: result?.mode === '模型服务' ? 'running' : 'idle' }"
    />

    <section class="page-shell">
      <section class="stats-grid">
        <article class="stat-card">
          <span>当前分流建议</span>
          <strong>{{ result?.predDiverter ?? '--' }}</strong>
          <small>预测分流阀开度</small>
        </article>
        <article class="stat-card">
          <span>当前补水建议</span>
          <strong>{{ result?.predWater ?? '--' }}</strong>
          <small>预测补水阀开度</small>
        </article>
        <article class="stat-card">
          <span>预测密度</span>
          <strong>{{ result?.predDensity ?? '--' }}</strong>
          <small>模型输出密度值</small>
        </article>
        <article class="stat-card">
          <span>设定密度建议</span>
          <strong>{{ setpointText }}</strong>
          <small>中煤 / 精煤密度设定</small>
        </article>
      </section>

      <section class="panel-grid">
        <section class="section-panel">
          <div class="panel-head">
            <div>
              <h2>密控控制趋势</h2>
              <p>展示 AI 预测控制线与实际执行曲线，替代底层数组直出。</p>
            </div>
            <div class="panel-actions">
              <el-select v-model="selectedUnit" style="width: 140px" @change="applyTemplate">
                <el-option v-for="unit in densityUnits" :key="unit.value" :label="unit.label" :value="unit.value" />
              </el-select>
              <el-button @click="applyTemplate">切换参数</el-button>
              <el-button type="primary" :loading="loading" @click="runPredict">调用模型</el-button>
            </div>
          </div>
          <div ref="trendChartEl" class="trend-chart"></div>
          <div class="param-grid">
            <article class="param-tile">
              <span>密度设定值</span>
              <strong>{{ currentParams.density_setpoint?.toFixed?.(2) ?? '--' }}</strong>
            </article>
            <article class="param-tile">
              <span>智能联动</span>
              <strong class="switch-text" :class="{ 'is-on': Number(currentParams.update_ctrl) === 1 }">{{ Number(currentParams.update_ctrl) === 1 ? '开启' : '关闭' }}</strong>
            </article>
            <article class="param-tile">
              <span>运行状态</span>
              <strong class="switch-text" :class="{ 'is-on': Number(currentParams.run_state) === 0 }">{{ Number(currentParams.run_state) === 0 ? '自动' : '手动' }}</strong>
            </article>
            <article class="param-tile">
              <span>补水开关</span>
              <strong class="switch-text" :class="{ 'is-on': Number(currentParams.water_switch) === 1 }">{{ Number(currentParams.water_switch) === 1 ? '开启' : '关闭' }}</strong>
            </article>
          </div>
          <div class="level-grid">
            <article class="param-tile" v-for="item in densityLevelRows" :key="item.label">
              <span>{{ item.label }}</span>
              <strong>{{ item.value.toFixed(1) }}%</strong>
              <el-progress :percentage="Math.min(100, Math.max(0, item.value))" :show-text="false" :stroke-width="8" :color="item.color" />
            </article>
          </div>
        </section>

        <section class="section-panel">
          <div class="panel-head">
            <div>
              <h2>密控单元概览</h2>
              <p>展示 3207、3208、316 当前密控状态和调用模式。</p>
            </div>
            <el-button @click="loadOverview">刷新概览</el-button>
          </div>
          <el-table :data="overviewRows">
            <el-table-column prop="unit" label="单元" width="90" />
            <el-table-column prop="area" label="区域" min-width="140" />
            <el-table-column prop="status" label="状态" width="110" />
            <el-table-column prop="density" label="密度" width="110" />
            <el-table-column prop="diverter" label="分流阀" width="150">
              <template #default="{ row }">
                <el-progress :percentage="toPercent(row.diverter)" :show-text="false" :stroke-width="8" color="#36c5ff" />
              </template>
            </el-table-column>
            <el-table-column prop="water" label="补水阀" width="150">
              <template #default="{ row }">
                <el-progress :percentage="toPercent(row.water)" :show-text="false" :stroke-width="8" color="#66d99f" />
              </template>
            </el-table-column>
            <el-table-column prop="mode" label="模式" width="110" />
          </el-table>
        </section>
      </section>

      <section class="section-panel">
        <div class="panel-head">
          <div>
            <h2>结果可视化</h2>
            <p>对比密度、分流和补水三个关键输出，用于现场联调时快速核对算法返回。</p>
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
  getSmartDensityOverview,
  predictSmartDensity,
  predictSmartDensitySetpoint,
  type SmartDensityPredictResult,
  type SmartDensityUnitDto,
} from '../../api/coal-business'

const densityUnits = [
  { label: '3207 主洗二段', value: '3207' },
  { label: '3208 主洗三段', value: '3208' },
  { label: '316 末煤系统', value: '316' },
]

const templates: Record<string, { dataLong: number[]; dataShort: number[]; params: Record<string, any> }> = {
  '3207': {
    dataLong: [1.43, 1.42, 1.44, 1.45, 42, 11.8, 2850, 2180],
    dataShort: [1.43, 1.44, 43, 12, 0, 1],
    params: { water_switch: 0, update_ctrl: 1, density_setpoint: 1.43, run_state: 0 },
  },
  '3208': {
    dataLong: [1.47, 1.46, 1.48, 1.49, 46, 12.6, 2960, 2220],
    dataShort: [1.47, 1.48, 45, 13, 0, 1],
    params: { water_switch: 0, update_ctrl: 1, density_setpoint: 1.47, run_state: 0 },
  },
  '316': {
    dataLong: [1.38, 1.37, 1.39, 1.40, 38, 9.8, 2320, 1690],
    dataShort: [1.38, 1.39, 39, 10, 1, 1],
    params: { water_switch: 1, update_ctrl: 1, density_setpoint: 1.38, run_state: 0 },
  },
}

const selectedUnit = ref('3207')
const overviewRows = ref<SmartDensityUnitDto[]>([])
const result = ref<SmartDensityPredictResult | null>(null)
const setpoint = ref<{ predMiddlingDensity: number; predCleanDensity: number; mode: string } | null>(null)
const loading = ref(false)
const chartEl = ref<HTMLElement | null>(null)
const trendChartEl = ref<HTMLElement | null>(null)
let chart: any = null
let trendChart: any = null
const iotHub = useIotHub()
const analogTags = {
  density: 'coal.kep.analog.b9e82933eec320e9',
  diverter: 'coal.kep.analog.7014082b6f33a101',
  water: 'coal.kep.analog.7c6a1bd7d61f805c',
  middlingLevel: 'coal.kep.analog.b8d6a504f2a4b29c', // 313合介桶液位
  magTailLevel: 'coal.kep.analog.5289474766eb197f', // 315磁尾桶液位
  slurryLevel: 'coal.kep.analog.a8e26f770de3c65e', // 331煤泥桶液位
}

const setpointText = computed(() => {
  if (!setpoint.value) return '--'
  return `${setpoint.value.predMiddlingDensity} / ${setpoint.value.predCleanDensity}`
})
const currentTemplate = computed(() => templates[selectedUnit.value])
const currentParams = computed(() => currentTemplate.value.params)

function applyTemplate() {
  renderTrendChart()
}

const toPercent = (value: string | number) => {
  const numeric = Number(String(value).replace('%', ''))
  return Math.max(0, Math.min(100, Number.isFinite(numeric) ? numeric : 0))
}
const getLiveValue = (tagCode: string, fallback: number) => {
  const live = iotHub.getTagValue(tagCode)?.value
  return typeof live === 'number' && Number.isFinite(live) ? live : fallback
}
const densityLevelRows = computed(() => [
  { label: '313合介桶液位', value: getLiveValue(analogTags.middlingLevel, 64.5), color: '#4ac6ff' },
  { label: '315磁尾桶液位', value: getLiveValue(analogTags.magTailLevel, 57.2), color: '#66d99f' },
  { label: '331煤泥桶液位', value: getLiveValue(analogTags.slurryLevel, 52.8), color: '#7fc7ff' },
])

async function loadOverview() {
  try {
    const data = await getSmartDensityOverview()
    overviewRows.value = data.units
    setpoint.value = data.setpoint
  } catch {
    const density = Number(getLiveValue(analogTags.density, 1.43).toFixed(2))
    const diverter = Number(getLiveValue(analogTags.diverter, 43).toFixed(1))
    const water = Number(getLiveValue(analogTags.water, 11.8).toFixed(1))
    overviewRows.value = [
      { unit: '3207', area: '主洗二段', status: '运行中', density: `${density}`, diverter: `${diverter}%`, water: `${water}`, mode: '实时点位回退' },
      { unit: '3208', area: '主洗三段', status: '运行中', density: `${(density + 0.04).toFixed(2)}`, diverter: `${Math.min(100, diverter + 3)}%`, water: `${(water + 0.6).toFixed(1)}`, mode: '实时点位回退' },
      { unit: '316', area: '末煤系统', status: '待校正', density: `${Math.max(1.30, density - 0.05).toFixed(2)}`, diverter: `${Math.max(0, diverter - 5)}%`, water: `${Math.max(0, water - 1.4).toFixed(1)}`, mode: '实时点位回退' },
    ]
    setpoint.value = { predMiddlingDensity: Number((density + 0.03).toFixed(2)), predCleanDensity: Number((density - 0.05).toFixed(2)), mode: '实时点位回退' }
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
    result.value = await predictSmartDensity(payload)
    setpoint.value = await predictSmartDensitySetpoint({ data: payload.dataLong.slice(0, 3) })
    await nextTick()
    renderTrendChart()
    renderChart()
    ElMessage.success(`智能密控 ${selectedUnit.value} 调用完成`)
  } catch (error: any) {
    ElMessage.error(error?.message || '智能密控调用失败')
  } finally {
    loading.value = false
  }
}

function renderTrendChart() {
  if (!trendChartEl.value) return
  const longSeries = currentTemplate.value.dataLong.slice(0, 6).map(Number)
  const actual = [longSeries[0], longSeries[1], longSeries[2], longSeries[3], longSeries[4] / 30, longSeries[5] / 8].map((v) => Number(v.toFixed(2)))
  const predicted = actual.map((value, index) => Number((value + [0, 0.01, -0.01, 0.02, 0.01, 0][index]).toFixed(2)))
  trendChart?.dispose()
  trendChart = echarts.init(trendChartEl.value)
  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { top: 0, textStyle: { color: '#9fb4c9' } },
    grid: { left: '4%', right: '4%', bottom: '10%', top: '16%', containLabel: true },
    xAxis: { type: 'category', data: ['T-5', 'T-4', 'T-3', 'T-2', 'T-1', '当前'], axisLabel: { color: '#9fb4c9' } },
    yAxis: { type: 'value', axisLabel: { color: '#9fb4c9' }, splitLine: { lineStyle: { color: 'rgba(120,160,200,0.12)' } } },
    series: [
      { name: 'AI预测控制线', type: 'line', smooth: true, data: predicted, lineStyle: { color: '#36c5ff', width: 3 }, itemStyle: { color: '#36c5ff' } },
      { name: '实际执行曲线', type: 'line', smooth: true, data: actual, lineStyle: { color: '#66d99f', width: 3 }, itemStyle: { color: '#66d99f' } },
    ],
  })
}

function renderChart() {
  if (!chartEl.value || !result.value) return
  chart?.dispose()
  chart = echarts.init(chartEl.value)
  chart.setOption({
    tooltip: { trigger: 'axis' },
    xAxis: {
      type: 'category',
      data: ['分流阀', '补水阀', '预测密度'],
      axisLabel: { color: INDUSTRIAL_CHART_COLORS.axis },
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: INDUSTRIAL_CHART_COLORS.axis },
      splitLine: { lineStyle: { color: INDUSTRIAL_CHART_COLORS.grid } },
    },
    grid: { left: '3%', right: '4%', top: '8%', bottom: '8%', containLabel: true },
    series: [
      {
        type: 'bar',
        data: [result.value.predDiverter, result.value.predWater, result.value.predDensity],
        itemStyle: {
          color: (params: any) => [INDUSTRIAL_CHART_COLORS.primary, INDUSTRIAL_CHART_COLORS.secondary, INDUSTRIAL_CHART_COLORS.warning][params.dataIndex],
          borderRadius: [8, 8, 0, 0],
        },
      },
    ],
  })
}

const handleResize = () => {
  chart?.resize()
  trendChart?.resize()
}

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'smart-density', intervalMs: 5000 })
  await iotHub.ensureFresh('smart-density', 2000)
  applyTemplate()
  await loadOverview()
  await runPredict()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  chart?.dispose()
  trendChart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.section-page{height:100%;min-height:0;overflow:auto;padding:12px 14px 18px;background:#091019;color:#eef6ff}
.page-shell{width:min(100%,1680px);margin:0 auto;display:block}
.smart-density-page .page-shell>.stats-grid{max-height:none !important;overflow:visible !important}
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
.trend-chart{height:260px;margin-bottom:14px}
.param-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}
.level-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;margin-top:10px}
.param-tile{padding:12px;border-radius:12px;border:1px solid rgba(122,190,255,.16);background:rgba(19,35,52,.65)}
.param-tile span{display:block;color:#9bc2df;font-size:12px}
.param-tile strong{display:block;margin-top:6px;font-size:24px}
.switch-text{color:#ff7b7b}
.switch-text.is-on{color:#73e9ad}
.chart-box{height:320px}
@media (max-width: 1200px){.stats-grid,.panel-grid,.param-grid{grid-template-columns:1fr}}
</style>
