<template>
  <div class="energy-page energy-manage-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">能耗管理</p>
        <h1>生产消耗分析</h1>
      </div>
      <div class="hero-actions">
        <button v-for="item in ['今日', '本周', '本月', '自定义']" :key="item" type="button" class="chip-btn">{{ item }}</button>
      </div>
    </section>

    <section class="metric-strip">
      <article v-for="item in metricCards" :key="item.label" class="metric-card">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }} <em>{{ item.unit }}</em></strong>
        <small :class="item.trendType">{{ item.trend }}</small>
      </article>
    </section>

    <section class="analysis-grid">
      <article class="panel">
        <div class="panel-head"><h2>消耗趋势分析</h2></div>
        <div ref="trendChartRef" class="chart-box"></div>
      </article>
      <article class="panel">
        <div class="panel-head"><h2>占比分析</h2></div>
        <div ref="ratioChartRef" class="chart-box"></div>
      </article>
      <article class="panel">
        <div class="panel-head"><h2>消耗成本</h2></div>
        <div ref="costChartRef" class="chart-box"></div>
      </article>
      <article class="panel">
        <div class="panel-head"><h2>回收率趋势</h2></div>
        <div ref="recoveryChartRef" class="chart-box"></div>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { echarts } from '../../utils/echarts'
import { useIotHub } from '../../composables/useIotHub'

const form = reactive({ date: '2026-04-13', shift: '白班', output: 1482.5, power: 8420.5 })
const iotHub = useIotHub()
const smart200Tags = {
  scbsPressure: 'coal.kep.smart200.c5e56d9152889532', // 生产补水.压力
  scbsOutletPressure: 'coal.kep.smart200.a110c32c0c5619bb', // 生产补水.出口压力
  scbsDryAlarm: 'coal.kep.smart200.53ca0d6fcadf610e', // 生产补水.缺水
  scbsFault: 'coal.kep.smart200.9bae336ab5de0b6b', // 生产补水.总故障
  schyOutletPressure: 'coal.kep.smart200.997e2953e6c3869d', // 生产恒压.出口压力
  shhyOutletPressure: 'coal.kep.smart200.6e5c1d0e75a7400d', // 生活恒压.出口压力
  targetPressure: 'coal.kep.smart200.8741e1253719977d', // 生产补水.系统给定压力
}
const analogLevelTags = {
  clearTank: 'coal.kep.analog.fc9f475af9d8af89', // 清水桶液位
  recycleTank: 'coal.kep.analog.2ae59c1f38216109', // 循环水池液位
  pressTank: 'coal.kep.analog.65180382d269aba8', // 压榨水桶液位
  filterFeedTank: 'coal.kep.analog.0ab480bea65c93be', // 压滤机入料桶液位
  incidentPool: 'coal.kep.analog.82024c4333abc688', // 事故池液位
  firePool1: 'coal.kep.analog.2c228c673e1dbc1b', // 消防水池1
  firePool2: 'coal.kep.analog.1db4e874ba75af56', // 消防水池2
  lifeTank: 'coal.kep.analog.eea97857f277c848', // 生活水箱
}

const unitPower = computed(() => (form.output ? (form.power / form.output).toFixed(2) : '0.00'))
const getNumericTag = (tagCode: string, fallback: number, digits = 2) => {
  const live = iotHub.getTagValue(tagCode)?.value
  if (typeof live !== 'number' || !Number.isFinite(live)) return Number(fallback.toFixed(digits))
  return Number(live.toFixed(digits))
}
const getBoolTag = (tagCode: string, fallback = false) => {
  const live = iotHub.getTagValue(tagCode)?.value
  if (typeof live === 'boolean') return live
  if (typeof live === 'number') return live > 0
  return fallback
}
const powerPerTon = computed(() => Number(unitPower.value))
const waterPerTon = computed(() => Number((getNumericTag(smart200Tags.schyOutletPressure, 2.08) / 13.9).toFixed(2)))
const mediumPerTon = computed(() => Number((getNumericTag(analogLevelTags.recycleTank, 72.1, 1) / 60).toFixed(2)))
const reagentPerTon = computed(() => Number((getNumericTag(analogLevelTags.filterFeedTank, 66.8, 1) / 56).toFixed(2)))
const oilPerTon = computed(() => Number((getNumericTag(analogLevelTags.clearTank, 58.4, 1) / 68).toFixed(2)))
const airPerTon = computed(() => Number((getNumericTag(smart200Tags.scbsPressure, 1.82) * 6.8).toFixed(1)))
const steamPerTon = computed(() => Number((getNumericTag(analogLevelTags.lifeTank, 63.1, 1) / 780).toFixed(2)))
const recoveryRate = computed(() => Number((99.5 - (getBoolTag(smart200Tags.scbsFault, false) ? 1.2 : 0.3)).toFixed(1)))

const metricCards = computed(() => [
  { label: '吨煤电耗', value: powerPerTon.value.toFixed(1), unit: 'kWh/t', trend: '↓ 2.1%', trendType: 'down' },
  { label: '吨煤水耗', value: waterPerTon.value.toFixed(2), unit: 'm3/t', trend: '→ 持平', trendType: 'flat' },
  { label: '吨煤介耗', value: mediumPerTon.value.toFixed(1), unit: 'kg/t', trend: '↓ 5.3%', trendType: 'down' },
  { label: '吨煤药耗', value: reagentPerTon.value.toFixed(2), unit: 'kg/t', trend: '↓ 1.7%', trendType: 'down' },
  { label: '吨煤油耗', value: oilPerTon.value.toFixed(2), unit: 'kg/t', trend: '↑ 0.9%', trendType: 'up' },
  { label: '吨煤风耗', value: airPerTon.value.toFixed(1), unit: 'm3/t', trend: '↑ 1.8%', trendType: 'up' },
  { label: '吨煤汽耗', value: steamPerTon.value.toFixed(2), unit: 't/t', trend: '↓ 3.6%', trendType: 'down' },
])

const xLabels = ['30天', '40天', '50天', '140天', '107天', '185天', '225天', '30日']
const powerSeries = [610, 550, 830, 710, 840, 730, 790, 880]
const waterSeries = [320, 300, 610, 480, 570, 520, 640, 700]
const mediumSeries = [410, 380, 740, 620, 580, 560, 690, 760]
const reagentSeries = [290, 272, 520, 468, 442, 438, 488, 540]
const oilSeries = [240, 228, 430, 396, 378, 364, 412, 450]
const airSeries = [280, 260, 510, 290, 420, 380, 520, 590]
const steamSeries = [360, 330, 680, 540, 500, 470, 600, 650]

const trendChartRef = ref<HTMLElement | null>(null)
const ratioChartRef = ref<HTMLElement | null>(null)
const costChartRef = ref<HTMLElement | null>(null)
const recoveryChartRef = ref<HTMLElement | null>(null)
let trendChart: any = null
let ratioChart: any = null
let costChart: any = null
let recoveryChart: any = null

const renderCharts = () => {
  if (trendChartRef.value) {
    trendChart ??= echarts.init(trendChartRef.value)
    trendChart.setOption({
      grid: { top: 26, left: 46, right: 16, bottom: 24 },
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'category', data: xLabels, axisLabel: { color: '#9fb4c8' }, axisLine: { lineStyle: { color: '#2f3d4e' } } },
      yAxis: { type: 'value', axisLabel: { color: '#9fb4c8' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } } },
      series: [
        { name: '电', type: 'line', smooth: true, data: powerSeries, lineStyle: { width: 2.5, color: '#365ad8' }, itemStyle: { color: '#365ad8' } },
        { name: '水', type: 'line', smooth: true, data: waterSeries, lineStyle: { width: 2.5, color: '#53c4ff' }, itemStyle: { color: '#53c4ff' } },
        { name: '介', type: 'line', smooth: true, data: mediumSeries, lineStyle: { width: 2.5, color: '#8ad0ff' }, itemStyle: { color: '#8ad0ff' } },
        { name: '药', type: 'line', smooth: true, data: reagentSeries, lineStyle: { width: 2.5, color: '#6bb7f3' }, itemStyle: { color: '#6bb7f3' } },
        { name: '油', type: 'line', smooth: true, data: oilSeries, lineStyle: { width: 2.5, color: '#b2d8f1' }, itemStyle: { color: '#b2d8f1' } },
        { name: '风', type: 'line', smooth: true, data: airSeries, lineStyle: { width: 2.5, color: '#79b7e9' }, itemStyle: { color: '#79b7e9' } },
        { name: '汽', type: 'line', smooth: true, data: steamSeries, lineStyle: { width: 2.5, color: '#b4dcff' }, itemStyle: { color: '#b4dcff' } },
      ],
    })
  }

  if (ratioChartRef.value) {
    ratioChart ??= echarts.init(ratioChartRef.value)
    const total = 186520
    ratioChart.setOption({
      tooltip: { trigger: 'item', formatter: '{b}: {d}%' },
      graphic: [
        { type: 'text', left: 'center', top: '43%', style: { text: '总消耗成本', fill: '#d8e7f5', font: '14px sans-serif', textAlign: 'center' } },
        { type: 'text', left: 'center', top: '53%', style: { text: `¥${total.toLocaleString()}`, fill: '#eaf5ff', font: '700 32px sans-serif', textAlign: 'center' } },
      ],
      series: [
        {
          type: 'pie',
          radius: ['48%', '72%'],
          data: [
            { value: 30, name: '电', itemStyle: { color: '#3b61db' } },
            { value: 19, name: '水', itemStyle: { color: '#52c6ff' } },
            { value: 14, name: '介', itemStyle: { color: '#89d4ff' } },
            { value: 11, name: '药', itemStyle: { color: '#6bb7f3' } },
            { value: 8, name: '油', itemStyle: { color: '#b2d8f1' } },
            { value: 9, name: '风', itemStyle: { color: '#8bb3d0' } },
            { value: 9, name: '汽', itemStyle: { color: '#b1c7d9' } },
          ],
          label: { color: '#d8e7f5', formatter: '{b}' },
        },
      ],
    })
  }

  if (costChartRef.value) {
    costChart ??= echarts.init(costChartRef.value)
    costChart.setOption({
      grid: { top: 20, left: 44, right: 20, bottom: 24 },
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'category', data: ['电', '水', '介', '药', '油', '风', '汽'], axisLabel: { color: '#9fb4c8' } },
      yAxis: { type: 'value', axisLabel: { color: '#9fb4c8' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } } },
      series: [
        {
          type: 'bar',
          barWidth: 24,
          data: [840, 690, 760, 540, 470, 620, 650],
          itemStyle: {
            borderRadius: [8, 8, 0, 0],
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: '#2e58d0' },
              { offset: 1, color: '#56c8ff' },
            ]),
          },
        },
      ],
    })
  }

  if (recoveryChartRef.value) {
    recoveryChart ??= echarts.init(recoveryChartRef.value)
    const recovery = [41, 48, 37, 55, 66, 84, 96, recoveryRate.value]
    recoveryChart.setOption({
      grid: { top: 24, left: 44, right: 28, bottom: 24 },
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'category', data: ['30天', '37天', '20天', '27天', '28天', '27天', '30天', '今日'], axisLabel: { color: '#9fb4c8' } },
      yAxis: { type: 'value', min: 0, max: 110, axisLabel: { color: '#9fb4c8' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } } },
      series: [
        {
          type: 'line',
          smooth: true,
          symbolSize: 8,
          data: recovery,
          lineStyle: { width: 3, color: '#3f7ff0' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(63, 127, 240, 0.38)' },
              { offset: 1, color: 'rgba(63, 127, 240, 0.04)' },
            ]),
          },
          markLine: {
            silent: true,
            symbol: 'none',
            lineStyle: { color: '#e07084', type: 'dashed' },
            data: [{ yAxis: 99.5, label: { formatter: '回收率', color: '#e9b7c1' } }],
          },
          markPoint: {
            symbol: 'circle',
            symbolSize: 66,
            data: [{ coord: ['27天', 55], value: `${recoveryRate.value}%` }],
            itemStyle: { color: 'rgba(237, 90, 114, 0.16)', borderColor: '#d85f73', borderWidth: 2 },
            label: { color: '#ffe7eb', formatter: '{c}', fontSize: 22, fontWeight: 700 },
          },
        },
      ],
    })
  }
}

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'energy-manage', intervalMs: 5000 })
  await iotHub.ensureFresh('energy-manage', 2000)
  renderCharts()
  window.addEventListener('resize', renderCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', renderCharts)
  trendChart?.dispose()
  ratioChart?.dispose()
  costChart?.dispose()
  recoveryChart?.dispose()
})
</script>

<style scoped>
.energy-page{height:100%;min-height:0;overflow:auto;padding:12px 14px 18px;background:#16202a;color:#eef6ff}
.page-hero,.metric-strip,.analysis-grid{width:min(100%,1680px);margin:0 auto 10px}
.page-hero,.panel,.metric-card{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}
.page-hero{display:flex;justify-content:space-between;align-items:center;gap:18px;padding:14px 18px}
.eyebrow{margin:0 0 6px;color:#8bdfff;font-size:12px}
.page-hero h1{margin:0;font-size:34px;line-height:1.1}
.hero-actions{display:flex;gap:6px}
.chip-btn{height:32px;padding:0 12px;border:1px solid rgba(173,196,218,.32);border-radius:999px;background:rgba(26,38,51,.8);color:#dce8f4;cursor:pointer}
.metric-strip{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:10px}
.metric-card{padding:12px 14px}
.metric-card span{display:block;color:#9fb4c8;font-size:13px}
.metric-card strong{display:block;margin-top:10px;font-size:34px;line-height:1;font-family:"DIN Alternate","Roboto Condensed","Arial Narrow","Microsoft YaHei",sans-serif}
.metric-card em{font-size:.55em;font-style:normal;color:#d6e6f2;margin-left:4px}
.metric-card small{display:block;margin-top:8px;font-size:15px}
.metric-card small.down{color:#90bdf0}
.metric-card small.up{color:#b8d8ff}
.metric-card small.flat{color:#c9d7e2}
.analysis-grid{display:grid;grid-template-columns:1fr 1fr;grid-template-rows:320px 320px;gap:10px}
.panel{padding:10px 14px;min-height:0;display:flex;flex-direction:column}
.panel-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.panel-head h2{margin:0;font-size:28px;line-height:1.1}
.chart-box{flex:1;min-height:0}
@media(max-width:1200px){
  .metric-strip{grid-template-columns:repeat(4,minmax(0,1fr))}
  .analysis-grid{grid-template-columns:1fr;grid-template-rows:repeat(4,300px)}
}
@media(max-width:900px){
  .metric-strip{grid-template-columns:repeat(2,minmax(0,1fr))}
}
</style>
