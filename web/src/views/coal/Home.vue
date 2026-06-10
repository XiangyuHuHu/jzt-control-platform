<template>
  <div class="coal-home">
    <img class="scene-bg" :src="plantBg" alt="" aria-hidden="true" />
    <div class="scene-overlay" aria-hidden="true"></div>

    <div class="tech-flow" aria-hidden="true">
      <svg class="tech-flow__svg" viewBox="0 0 1920 1080" preserveAspectRatio="none">
        <path class="tech-line tech-line--v" d="M 368 72 V 1000" />
        <path class="tech-line tech-line--v tech-line--delay-1" d="M 28 96 V 976" />
        <path class="tech-line tech-line--v" d="M 1552 72 V 1000" />
        <path class="tech-line tech-line--v tech-line--delay-2" d="M 1892 96 V 976" />
        <path class="tech-line tech-line--h" d="M 120 52 H 1800" />
        <path class="tech-line tech-line--h tech-line--delay-1" d="M 260 908 H 1660" />
        <path class="tech-line tech-line--arc" d="M 420 540 C 620 420, 760 420, 960 540 S 1300 660, 1500 540" />
        <path class="tech-line tech-line--corner" d="M 48 48 H 180 V 180" />
        <path class="tech-line tech-line--corner" d="M 1872 48 H 1740 V 180" />
        <path class="tech-line tech-line--corner" d="M 48 1032 H 180 V 900" />
        <path class="tech-line tech-line--corner" d="M 1872 1032 H 1740 V 900" />
      </svg>
      <span class="tech-beam tech-beam--top"></span>
      <span class="tech-beam tech-beam--bottom"></span>
      <span class="tech-beam tech-beam--left"></span>
      <span class="tech-beam tech-beam--right"></span>
    </div>

    <header class="platform-header">
      <div class="platform-header__wing platform-header__wing--left" aria-hidden="true"></div>
      <h1 class="platform-header__title">金正泰选煤厂智能管控平台</h1>
      <div class="platform-header__wing platform-header__wing--right" aria-hidden="true"></div>
      <div class="corner-meta">
        <span>{{ currentDate }}</span>
        <span>{{ currentTime }}</span>
      </div>
    </header>

    <aside class="side-panel side-panel--left">
      <section class="glass-panel">
        <div class="panel-head"><h2>生产统计</h2></div>
        <div class="kpi-strip">
          <div v-for="item in kpis.slice(0, 2)" :key="item.label" class="kpi-mini">
            <span>{{ item.label }}</span>
            <strong>{{ item.value }}</strong>
          </div>
        </div>
        <div ref="trendChartRef" class="chart-box"></div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>能耗统计</h2></div>
        <div ref="consumeRadarRef" class="chart-box"></div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>产品质量</h2></div>
        <div ref="qualityGaugeRef" class="chart-box"></div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>储存情况</h2></div>
        <div class="storage-grid">
          <div v-for="item in storageItems" :key="item.label" class="storage-item">
            <strong>{{ item.value }}</strong>
            <span>{{ item.label }}</span>
          </div>
        </div>
      </section>
    </aside>

    <aside class="side-panel side-panel--right">
      <section class="glass-panel">
        <div class="panel-head"><h2>设备状态</h2></div>
        <div ref="statusPieRef" class="chart-box"></div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>智能预警</h2></div>
        <div class="alarm-list">
          <div v-for="item in alarms" :key="item.id" class="alarm-item">
            <span class="alarm-index">{{ item.id }}</span>
            <span class="alarm-text">{{ item.text }}</span>
            <span class="alarm-level">{{ item.level }}</span>
          </div>
        </div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>运营概览</h2></div>
        <div class="summary-grid">
          <div v-for="item in summaryItems" :key="item.label" class="summary-item">
            <span>{{ item.label }}</span>
            <strong>{{ item.value }}</strong>
          </div>
        </div>
      </section>

      <section class="glass-panel">
        <div class="panel-head"><h2>历史回顾</h2></div>
        <p class="history-text">
          当日入洗 {{ kpis[0].value }}，精煤产量 {{ kpis[1].value }}，设备运行率 {{ kpis[2].value }}，系统运行平稳，各模块数据持续汇总。
        </p>
      </section>
    </aside>

    <nav class="bottom-nav" aria-label="功能导航">
      <button
        v-for="item in bottomNavItems"
        :key="item.path"
        type="button"
        class="nav-btn"
        :class="{ active: item.path === '/jzt/coal' }"
        @click="goPage(item.path)"
      >
        <span class="nav-icon" aria-hidden="true">{{ item.icon }}</span>
        <span class="nav-label">{{ item.label }}</span>
      </button>
    </nav>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import plantBg from '../../assets/jzt-plant-aerial.jpg'
import { getIotAlarms } from '../../api/iot'
import { echarts } from '../../utils/echarts'
import { useIotHub } from '../../composables/useIotHub'

const router = useRouter()
const iotHub = useIotHub()
const currentTime = ref('')
const currentDate = ref('')
let timer = 0

const bottomNavItems = [
  { label: '首页', path: '/jzt/coal', icon: '首' },
  { label: '生产运行', path: '/jzt/coal/production', icon: '产' },
  { label: '设备运维', path: '/jzt/coal/equipment', icon: '设' },
  { label: '质量能耗', path: '/jzt/coal/quality', icon: '质' },
  { label: '智能优化', path: '/jzt/coal/decision', icon: '智' },
  { label: '平台系统', path: '/jzt/coal/settings', icon: '系' },
]

const goPage = (path: string) => {
  router.push(path)
}

const getRealtimeValue = (tagCode: string, fallback: number, digits = 1) => {
  const live = iotHub.getTagValue(tagCode)?.value
  if (typeof live !== 'number' || !Number.isFinite(live)) return fallback.toFixed(digits)
  return live.toFixed(digits)
}

const abnormalCount = computed(() => Object.values(iotHub.realtimeMap.value).filter((item) => item.quality !== 'GOOD').length)
const equipRate = computed(() => (abnormalCount.value ? (97.2 - abnormalCount.value * 0.6).toFixed(1) : '97.4'))
const latestAlarmRows = ref<Array<{ id: number; text: string; level: string }>>([])

const kpis = computed(() => [
  { label: '今日入洗量', value: `${getRealtimeValue('coal.feed.daily', 12580, 0)}吨`, note: '↑ 3.2%' },
  { label: '精煤产量', value: `${getRealtimeValue('coal.product.daily', 8240, 0)}吨`, note: `产率 ${getRealtimeValue('coal.product.ratio', 65.5, 1)}%` },
  { label: '设备综合运行率', value: `${equipRate.value}%`, note: '在线状态稳定' },
  { label: '当日报警', value: `${abnormalCount.value || 3}条`, note: `${Math.max((abnormalCount.value || 3) - 1, 1)}条未处理` },
])

const summaryItems = computed(() => [
  { label: '设备运行率', value: `${equipRate.value}%` },
  { label: '当日报警', value: `${abnormalCount.value || 3}条` },
  { label: '介耗水平', value: '0.82 kg/t' },
  { label: '吨煤电耗', value: '2.1 kWh/t' },
])

const storageItems = computed(() => [
  { label: '原煤仓', value: '48.0%' },
  { label: '精煤仓', value: '62.5%' },
  { label: '矸石仓', value: '35.2%' },
])

const levelToZh = (level: string) => {
  const normalized = level.trim().toUpperCase()
  if (normalized.includes('HIGH') || normalized.includes('CRITICAL') || normalized.includes('紧急')) return '紧急'
  if (normalized.includes('MED') || normalized.includes('IMPORTANT') || normalized.includes('重要')) return '重要'
  if (normalized.includes('LOW') || normalized.includes('一般') || normalized.includes('INFO')) return '一般'
  return '一般'
}

const alarms = computed(() => {
  if (latestAlarmRows.value.length) return latestAlarmRows.value
  return [
    { id: 1, text: '主洗车间循环泵电流异常', level: '一般' },
    { id: 2, text: '原煤皮带机速度波动超限', level: '一般' },
    { id: 3, text: '压滤机入料压力偏高', level: '一般' },
  ]
})

const refreshAlarms = async () => {
  try {
    const response = await getIotAlarms({ alarmStatus: 'ACTIVE' })
    const rows = (response.data || []).slice(0, 4).map((item, index) => ({
      id: index + 1,
      text: item.alarmName?.trim() || `${item.deviceCode || '设备'}报警`,
      level: levelToZh(item.alarmLevel || ''),
    }))
    latestAlarmRows.value = rows
  } catch {
    latestAlarmRows.value = []
  }
}

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('zh-CN', { hour12: false })
  currentDate.value = now.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short',
  })
}

const trendChartRef = ref<HTMLElement | null>(null)
const qualityGaugeRef = ref<HTMLElement | null>(null)
const consumeRadarRef = ref<HTMLElement | null>(null)
const statusPieRef = ref<HTMLElement | null>(null)
let trendChart: any = null
let qualityChart: any = null
let consumeChart: any = null
let statusChart: any = null

const renderCharts = () => {
  if (trendChartRef.value) {
    trendChart ??= echarts.init(trendChartRef.value)
    trendChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { right: 0, top: 0, textStyle: { color: '#b8cbdd', fontSize: 10 } },
      grid: { top: 26, left: 32, right: 12, bottom: 18 },
      xAxis: { type: 'category', data: ['4', '8', '16', '24', '32', '40', '50'], axisLabel: { color: '#9fb4c8', fontSize: 9 } },
      yAxis: { type: 'value', axisLabel: { color: '#9fb4c8', fontSize: 9 }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } } },
      series: [
        { name: '入洗量', type: 'bar', barWidth: 10, data: [42, 58, 80, 66, 57, 39, 81], itemStyle: { color: '#4f8fd9', borderRadius: [3, 3, 0, 0] } },
        { name: '精煤', type: 'bar', barWidth: 10, data: [26, 34, 48, 38, 32, 28, 44], itemStyle: { color: '#6eb5de', borderRadius: [3, 3, 0, 0] } },
      ],
    })
  }

  if (qualityGaugeRef.value) {
    qualityChart ??= echarts.init(qualityGaugeRef.value)
    qualityChart.setOption({
      series: [
        {
          type: 'gauge', center: ['18%', '58%'], radius: '44%', min: 0, max: 20,
          progress: { show: true, width: 5, itemStyle: { color: '#93a9be' } },
          axisLine: { lineStyle: { width: 5, color: [[1, '#314150']] } },
          pointer: { show: false },
          detail: { formatter: '灰分\n8.2%', color: '#e9f3fa', fontSize: 10, offsetCenter: [0, '58%'] },
          data: [{ value: 8.2 }],
        },
        {
          type: 'gauge', center: ['50%', '58%'], radius: '44%', min: 0, max: 3,
          progress: { show: true, width: 5, itemStyle: { color: '#d2b34d' } },
          axisLine: { lineStyle: { width: 5, color: [[1, '#314150']] } },
          pointer: { show: false },
          detail: { formatter: '硫分\n0.6%', color: '#e9f3fa', fontSize: 10, offsetCenter: [0, '58%'] },
          data: [{ value: 0.6 }],
        },
        {
          type: 'gauge', center: ['82%', '58%'], radius: '44%', min: 0, max: 20,
          progress: { show: true, width: 5, itemStyle: { color: '#76b486' } },
          axisLine: { lineStyle: { width: 5, color: [[1, '#314150']] } },
          pointer: { show: false },
          detail: { formatter: '水分\n8.5%', color: '#e9f3fa', fontSize: 10, offsetCenter: [0, '58%'] },
          data: [{ value: 8.5 }],
        },
      ],
    })
  }

  if (consumeRadarRef.value) {
    consumeChart ??= echarts.init(consumeRadarRef.value)
    const consumeValues = [76, 68, 58, 44, 38, 71]
    consumeChart.setOption({
      radar: {
        radius: '58%', center: ['50%', '52%'],
        indicator: [
          { name: '电', max: 100 }, { name: '水', max: 100 }, { name: '介', max: 100 },
          { name: '药', max: 100 }, { name: '油', max: 100 }, { name: '风', max: 100 },
        ],
        axisName: { color: '#b7cadd', fontSize: 9 },
        splitLine: { lineStyle: { color: 'rgba(151, 185, 216, 0.26)' } },
        splitArea: { areaStyle: { color: ['rgba(83,120,151,0.08)', 'rgba(83,120,151,0.16)'] } },
      },
      series: [{ type: 'radar', data: [{ value: consumeValues, areaStyle: { color: 'rgba(86, 132, 188, 0.45)' }, lineStyle: { color: '#5d9ee3' } }] }],
    })
  }

  if (statusPieRef.value) {
    statusChart ??= echarts.init(statusPieRef.value)
    statusChart.setOption({
      graphic: [
        { type: 'text', left: 'center', top: '40%', style: { text: '32', fill: '#f2f8fd', font: '700 28px sans-serif', textAlign: 'center' } },
        { type: 'text', left: 'center', top: '56%', style: { text: '台运行', fill: '#c7d9e8', font: '11px sans-serif', textAlign: 'center' } },
      ],
      series: [{
        type: 'pie', radius: ['50%', '68%'],
        data: [
          { value: 18, name: '正常', itemStyle: { color: '#4f8fd9' } },
          { value: 9, name: '待机', itemStyle: { color: '#6eb5de' } },
          { value: 5, name: '故障', itemStyle: { color: '#c68948' } },
        ],
        label: { color: '#c7d9e8', fontSize: 9, formatter: '{b}' },
      }],
    })
  }
}

const resizeCharts = () => {
  trendChart?.resize()
  qualityChart?.resize()
  consumeChart?.resize()
  statusChart?.resize()
}

onMounted(async () => {
  updateTime()
  timer = window.setInterval(updateTime, 1000)
  iotHub.subscribe({ pageKey: 'coal-home', intervalMs: 5000 })
  await iotHub.ensureFresh('coal-home', 2000)
  await refreshAlarms()
  await nextTick()
  renderCharts()
  window.addEventListener('resize', resizeCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeCharts)
  clearInterval(timer)
  trendChart?.dispose()
  qualityChart?.dispose()
  consumeChart?.dispose()
  statusChart?.dispose()
})
</script>

<style scoped>
.coal-home {
  position: relative;
  height: 100vh;
  min-height: 0;
  overflow: hidden;
  color: #eef6ff;
  background: #0b1826;
}

.scene-bg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 44%;
  image-rendering: auto;
  filter: saturate(1.08) contrast(1.06) brightness(1.04);
}

.scene-overlay {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(90deg, rgba(5, 12, 22, 0.24) 0%, transparent 18%, transparent 82%, rgba(5, 12, 22, 0.24) 100%),
    linear-gradient(180deg, rgba(5, 12, 22, 0.16) 0%, transparent 24%, transparent 76%, rgba(5, 12, 22, 0.36) 100%);
  pointer-events: none;
}

.tech-flow {
  position: absolute;
  inset: 0;
  z-index: 2;
  pointer-events: none;
  overflow: hidden;
}

.tech-flow__svg {
  width: 100%;
  height: 100%;
}

.tech-line {
  fill: none;
  stroke-linecap: round;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
}

.tech-line--v {
  stroke: rgba(77, 184, 255, 0.28);
  stroke-width: 1.2;
  stroke-dasharray: 6 18;
  animation: tech-flow-v 5s linear infinite;
}

.tech-line--h {
  stroke: rgba(77, 184, 255, 0.24);
  stroke-width: 1;
  stroke-dasharray: 10 22;
  animation: tech-flow-h 6s linear infinite;
}

.tech-line--arc {
  stroke: rgba(77, 184, 255, 0.14);
  stroke-width: 1;
  stroke-dasharray: 4 16;
  animation: tech-flow-h 8s linear infinite reverse;
}

.tech-line--corner {
  stroke: rgba(120, 210, 255, 0.36);
  stroke-width: 1.4;
  stroke-dasharray: 120 280;
  animation: tech-flow-corner 7s linear infinite;
}

.tech-line--delay-1 { animation-delay: -1.6s; }
.tech-line--delay-2 { animation-delay: -3.2s; }

.tech-beam {
  position: absolute;
  border-radius: 999px;
  filter: blur(0.4px);
  opacity: 0;
  animation: tech-beam-pass 5.5s ease-in-out infinite;
}

.tech-beam--top {
  top: 52px;
  left: -20%;
  width: 18%;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(120, 220, 255, 0.9), transparent);
  animation-delay: 0s;
}

.tech-beam--bottom {
  bottom: 88px;
  right: -20%;
  width: 22%;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(120, 220, 255, 0.75), transparent);
  animation-delay: -2.4s;
  animation-direction: reverse;
}

.tech-beam--left {
  top: 18%;
  left: 20%;
  width: 2px;
  height: 14%;
  background: linear-gradient(180deg, transparent, rgba(120, 220, 255, 0.7), transparent);
  animation: tech-beam-pass-v 6s ease-in-out infinite;
  animation-delay: -1.2s;
}

.tech-beam--right {
  top: 42%;
  right: 20%;
  width: 2px;
  height: 12%;
  background: linear-gradient(180deg, transparent, rgba(120, 220, 255, 0.65), transparent);
  animation: tech-beam-pass-v 6.8s ease-in-out infinite;
  animation-delay: -3.6s;
}

@keyframes tech-flow-v {
  to { stroke-dashoffset: -96; }
}

@keyframes tech-flow-h {
  to { stroke-dashoffset: -128; }
}

@keyframes tech-flow-corner {
  to { stroke-dashoffset: -400; }
}

@keyframes tech-beam-pass {
  0%, 18% { opacity: 0; transform: translateX(0); }
  28% { opacity: 0.85; }
  72% { opacity: 0.85; }
  100% { opacity: 0; transform: translateX(720%); }
}

@keyframes tech-beam-pass-v {
  0%, 18% { opacity: 0; transform: translateY(0); }
  28% { opacity: 0.75; }
  72% { opacity: 0.75; }
  100% { opacity: 0; transform: translateY(420%); }
}

.platform-header {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  z-index: 4;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  height: 54px;
  pointer-events: none;
}

.platform-header__wing {
  position: relative;
  width: clamp(48px, 8vw, 120px);
  height: 2px;
  margin-bottom: 18px;
  overflow: hidden;
  background: linear-gradient(90deg, transparent, rgba(77, 184, 255, 0.45));
}

.platform-header__wing::after {
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent 0%, rgba(160, 230, 255, 0.95) 50%, transparent 100%);
  animation: tech-wing-flow 3.2s ease-in-out infinite;
  content: '';
}

.platform-header__wing--right {
  background: linear-gradient(270deg, transparent, rgba(77, 184, 255, 0.45));
}

.platform-header__wing--right::after {
  animation-direction: reverse;
}

@keyframes tech-wing-flow {
  0%, 100% { transform: translateX(-120%); opacity: 0; }
  35%, 65% { opacity: 1; }
  100% { transform: translateX(120%); }
}

.platform-header__title {
  margin: 0 10px;
  padding: 6px 36px 10px;
  font-size: clamp(18px, 2.2vw, 30px);
  font-weight: 700;
  letter-spacing: 0.14em;
  color: #ffffff;
  white-space: nowrap;
  text-shadow: 0 0 18px rgba(77, 184, 255, 0.45);
  background: linear-gradient(180deg, rgba(8, 28, 52, 0.72) 0%, rgba(8, 28, 52, 0.18) 100%);
  border: 1px solid rgba(77, 184, 255, 0.38);
  border-top: none;
  clip-path: polygon(6% 0, 94% 0, 100% 100%, 0 100%);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.28);
}

.corner-meta {
  position: absolute;
  top: 10px;
  right: 14px;
  display: flex;
  gap: 10px;
  font-size: 12px;
  color: rgba(215, 235, 251, 0.82);
}

.side-panel {
  position: absolute;
  top: 58px;
  bottom: 82px;
  z-index: 3;
  width: min(340px, 21vw);
  display: grid;
  grid-template-rows: repeat(4, 1fr);
  gap: 8px;
  min-height: 0;
}

.side-panel--left { left: 10px; }
.side-panel--right { right: 10px; }

.glass-panel {
  position: relative;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 8px 10px;
  border: 1px solid rgba(72, 180, 255, 0.28);
  border-radius: 4px;
  background: rgba(8, 22, 38, 0.48);
  backdrop-filter: blur(8px);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.04);
  overflow: hidden;
}

.glass-panel::before {
  position: absolute;
  top: 0;
  left: -40%;
  width: 36%;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(130, 220, 255, 0.9), transparent);
  animation: tech-panel-scan 4.8s ease-in-out infinite;
  content: '';
  pointer-events: none;
}

.side-panel .glass-panel:nth-child(2)::before { animation-delay: -1.2s; }
.side-panel .glass-panel:nth-child(3)::before { animation-delay: -2.4s; }
.side-panel .glass-panel:nth-child(4)::before { animation-delay: -3.6s; }

.panel-head {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
  padding-bottom: 4px;
  border-bottom: 1px solid rgba(72, 180, 255, 0.2);
}

.panel-head h2 {
  margin: 0;
  font-size: 14px;
  font-weight: 700;
  color: #d8ecfb;
}

.panel-head h2::before {
  content: '';
  display: inline-block;
  width: 3px;
  height: 12px;
  margin-right: 6px;
  background: #4db8ff;
  box-shadow: 0 0 8px rgba(77, 184, 255, 0.65);
  vertical-align: -1px;
}

@keyframes tech-panel-scan {
  0%, 12% { left: -40%; opacity: 0; }
  22% { opacity: 0.9; }
  78% { opacity: 0.9; }
  100% { left: 104%; opacity: 0; }
}

.kpi-strip {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 6px;
  margin-bottom: 4px;
}

.kpi-mini span {
  display: block;
  color: #9fc4e2;
  font-size: 10px;
}

.kpi-mini strong {
  display: block;
  margin-top: 2px;
  font-size: 15px;
}

.chart-box {
  flex: 1;
  min-height: 0;
}

.storage-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  align-items: center;
}

.storage-item {
  text-align: center;
  padding: 8px 4px;
  border-radius: 50%;
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border: 2px solid rgba(77, 184, 255, 0.35);
  background: rgba(255, 255, 255, 0.04);
}

.storage-item strong {
  font-size: 14px;
  color: #7ecfff;
}

.storage-item span {
  margin-top: 4px;
  font-size: 10px;
  color: #9fc4e2;
}

.alarm-list {
  flex: 1;
  min-height: 0;
  display: grid;
  gap: 5px;
  overflow: hidden;
}

.alarm-item {
  display: grid;
  grid-template-columns: 20px 1fr auto;
  gap: 6px;
  align-items: center;
  min-height: 26px;
  padding: 0 6px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.05);
  font-size: 11px;
}

.alarm-index {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 10px;
  background: #c44f4f;
}

.alarm-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: #d6e4ef;
}

.alarm-level { color: #d9c6a8; font-size: 10px; }

.summary-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 6px;
}

.summary-item {
  padding: 8px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.04);
}

.summary-item span {
  display: block;
  color: #9fc4e2;
  font-size: 10px;
}

.summary-item strong {
  display: block;
  margin-top: 4px;
  font-size: 16px;
}

.history-text {
  flex: 1;
  margin: 0;
  color: rgba(214, 230, 244, 0.82);
  font-size: 11px;
  line-height: 1.6;
}

.bottom-nav {
  position: absolute;
  left: 50%;
  bottom: 14px;
  z-index: 5;
  transform: translateX(-50%);
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
  max-width: min(96vw, 1200px);
  padding: 10px 16px;
  border: 1px solid rgba(88, 168, 230, 0.28);
  border-radius: 12px;
  background: rgba(8, 20, 36, 0.72);
  backdrop-filter: blur(10px);
  overflow: hidden;
}

.bottom-nav::before {
  position: absolute;
  top: 0;
  left: -30%;
  width: 28%;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(130, 220, 255, 0.85), transparent);
  animation: tech-nav-scan 5.6s ease-in-out infinite;
  content: '';
  pointer-events: none;
}

@keyframes tech-nav-scan {
  0%, 10% { left: -30%; opacity: 0; }
  20% { opacity: 1; }
  80% { opacity: 1; }
  100% { left: 102%; opacity: 0; }
}

.nav-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 42px;
  padding: 0 12px;
  border: 1px solid rgba(118, 204, 255, 0.18);
  border-radius: 8px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.1), transparent 36%),
    rgba(7, 21, 39, 0.28);
  color: rgba(232, 242, 251, 0.82);
  font-size: 15px;
  font-weight: 800;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    inset 0 -3px 0 rgba(0, 0, 0, 0.18),
    0 7px 14px rgba(0, 0, 0, 0.16);
  cursor: pointer;
  transition: transform 0.18s ease, background 0.18s ease, border-color 0.18s ease, color 0.18s ease, box-shadow 0.18s ease;
}

.nav-btn::after {
  position: absolute;
  right: 8px;
  bottom: 2px;
  left: 8px;
  height: 3px;
  border-radius: 999px;
  background: linear-gradient(90deg, #ffd56d, #f4a525);
  opacity: 0;
  transform: scaleX(0.45);
  transition: 0.18s ease;
  box-shadow: 0 0 12px rgba(255, 190, 52, 0.62);
  content: '';
}

.nav-btn:hover,
.nav-btn.active {
  transform: translateY(-1px);
  border-color: rgba(255, 210, 105, 0.72);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.22), transparent 35%),
    linear-gradient(180deg, rgba(73, 67, 45, 0.68), rgba(31, 26, 19, 0.62));
  color: #ffffff;
}

.nav-btn.active {
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.36), transparent 34%),
    linear-gradient(180deg, #ffdc7a 0%, #d79a2b 54%, #835215 100%);
  color: #241300;
  text-shadow: 0 1px 0 rgba(255, 237, 180, 0.58);
}

.nav-btn:hover::after,
.nav-btn.active::after {
  opacity: 1;
  transform: scaleX(1);
}

.nav-icon {
  display: grid;
  place-items: center;
  width: 25px;
  height: 25px;
  border: 1px solid rgba(114, 220, 255, 0.18);
  border-radius: 6px;
  background: rgba(114, 220, 255, 0.13);
  color: #a8edff;
  font-size: 13px;
  font-weight: 900;
}

.nav-btn.active .nav-icon {
  border-color: rgba(70, 42, 4, 0.28);
  background: rgba(255, 255, 255, 0.28);
  color: #4a2f00;
}

.nav-label {
  white-space: nowrap;
}

@media (max-width: 1200px) {
  .side-panel { width: min(300px, 26vw); }
  .platform-header__title { font-size: 18px; letter-spacing: 0.08em; padding-inline: 24px; }
  .bottom-nav { gap: 8px; padding: 8px 10px; }
  .nav-btn { height: 38px; padding: 0 10px; font-size: 13px; }
  .nav-icon { width: 22px; height: 22px; font-size: 11px; }
}

@media (prefers-reduced-motion: reduce) {
  .tech-line,
  .tech-beam,
  .platform-header__wing::after,
  .glass-panel::before,
  .bottom-nav::before {
    animation: none !important;
  }
}
</style>
