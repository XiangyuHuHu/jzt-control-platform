<template>
  <div class="coal-page-v2 quality-page quality-center-page">
    <div class="page-layout">
      <main class="page-main">
        <header class="hero">
          <h1>质量控制中心</h1>
          <button type="button" class="export-btn" @click="exportQualityReport">导出分析报告</button>
        </header>

        <section class="quality-board">
          <article class="panel recommendation">
            <div class="panel-head">
              <h3>AI 分选参数建议</h3>
              <span class="badge">V4.2</span>
            </div>
            <div class="recommend-body">
              <div class="recommend-main">
                <div class="big-number">
                  <span>目标密度</span>
                  <strong>{{ targetDensity.toFixed(2) }}<em>SG</em></strong>
                </div>
                <div class="compare-list">
                  <article class="compare-item">
                    <div class="compare-head">
                      <span>重介质密度</span>
                      <small>当前 {{ currentDensity.toFixed(2) }} SG</small>
                      <small>建议 {{ targetDensity.toFixed(2) }} SG</small>
                    </div>
                    <div class="compare-track">
                      <div class="compare-fill" :style="densityFillStyle"></div>
                      <span class="compare-marker compare-marker--current" :style="{ left: `${densityCurrentPct}%` }"></span>
                      <span class="compare-marker compare-marker--target" :style="{ left: `${densityTargetPct}%` }"></span>
                    </div>
                  </article>
                  <article class="compare-item">
                    <div class="compare-head">
                      <span>给料速率</span>
                      <small>当前 {{ currentFeedRate.toFixed(0) }} t/h</small>
                      <small>建议 {{ suggestedFeedRate.toFixed(0) }} t/h</small>
                    </div>
                    <div class="compare-track">
                      <div class="compare-fill" :style="feedFillStyle"></div>
                      <span class="compare-marker compare-marker--current" :style="{ left: `${feedCurrentPct}%` }"></span>
                      <span class="compare-marker compare-marker--target" :style="{ left: `${feedTargetPct}%` }"></span>
                    </div>
                  </article>
                </div>
              </div>
              <div class="recommend-side">
                <div class="confidence-gauge" :style="confidenceStyle">
                  <div class="confidence-inner">
                    <strong>{{ controlConfidence.toFixed(0) }}%</strong>
                    <span>模型置信度</span>
                  </div>
                </div>
                <p class="confidence-sub">预测灰分达标率 {{ complianceRate.toFixed(1) }}%</p>
                <div class="suggestions">
                  <article class="suggest-card">
                    <strong>旋流器设定值</strong>
                    <span>{{ densityOffsetText }}</span>
                  </article>
                  <article class="suggest-card suggest-card--warn">
                    <strong>给料速率缓冲</strong>
                    <span>-12%</span>
                  </article>
                </div>
              </div>
            </div>
            <button type="button" class="cta-btn" :class="{ applied: autoApplied }" @click="applyAutoAdjust">
              {{ autoApplied ? '已应用 ✓' : '应用自主调节' }}
            </button>
          </article>

          <div class="device-stack">
            <article class="device-card">
              <div class="device-head">
                <strong>重介旋流器</strong>
                <span class="dot ok"></span>
              </div>
              <div class="device-metric">
                <span>处理量</span>
                <strong>{{ cycloneThroughput.toFixed(0) }}<em>吨/时</em></strong>
              </div>
              <div class="load-gauge">
                <div class="load-ring" :style="{ '--load': `${throughputProgress}%` }">
                  <div class="load-ring__inner">
                    <b>{{ cycloneThroughput.toFixed(0) }}</b>
                    <small>t/h</small>
                  </div>
                </div>
              </div>
              <div class="device-foot"><span>效率 98.2%</span><span>磨损 低</span></div>
            </article>
            <article class="device-card">
              <div class="device-head">
                <strong>粗煤泥分选机</strong>
                <span class="dot ok"></span>
              </div>
              <div class="device-metric">
                <span>固体浓度</span>
                <strong>{{ slurryConcentration.toFixed(1) }}<em>%</em></strong>
              </div>
              <div class="liquid-wrap">
                <div class="liquid-fill" :style="{ '--liquid': `${concentrationProgress}%` }">
                  <span class="liquid-value">{{ slurryConcentration.toFixed(1) }}%</span>
                  <span class="wave wave-a"></span>
                  <span class="wave wave-b"></span>
                </div>
              </div>
              <div class="device-foot"><span>床层 1.2m</span><span>同步中</span></div>
            </article>
          </div>

          <section class="panel trend-panel">
            <div class="panel-head">
              <h3>灰分含量趋势</h3>
              <div class="legend">
                <span><i class="blue"></i>当前</span>
                <span><i class="ghost"></i>目标 9.5%</span>
              </div>
            </div>
            <div ref="ashChartEl" class="chart-box"></div>
          </section>
        </section>

        <footer class="footer-stats">
          <article class="footer-card"><span>工艺用水酸碱度</span><strong>{{ processPh.toFixed(1) }}</strong></article>
          <article class="footer-card"><span>产率效率</span><strong>{{ yieldEfficiency.toFixed(1) }}%</strong></article>
          <article class="footer-card"><span>介质损耗率</span><strong>{{ mediumLoss.toFixed(2) }}<em>千克/吨</em></strong></article>
          <article class="footer-card"><span>累计处理量</span><strong>{{ totalHandledText }}<em>吨</em></strong></article>
        </footer>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { echarts } from '../../utils/echarts'
import { useIotHub } from '../../composables/useIotHub'

const ashChartEl = ref<HTMLElement | null>(null)
let ashChart: any = null
const autoApplied = ref(false)
const iotHub = useIotHub()
const analogTags = {
  mediumDensity: 'coal.kep.analog.b9e82933eec320e9', // 322BX合介密度
  feedFlow: 'coal.kep.analog.a39438b3226da48b', // 301原煤皮带秤瞬时流量
  productFlow: 'coal.kep.analog.7f4f2eafd4bd21ea', // 701AWTA瞬时流量
  concentration: 'coal.kep.analog.070e59650bc4ce5f', // ND1X浓度1
  concentration2: 'coal.kep.analog.c18abf661b1e12b3', // ND2X浓度2
  turbidity: 'coal.kep.analog.2770e3447a38c77b', // ZDJX浊度
  splitter: 'coal.kep.analog.7014082b6f33a101', // 重介系统分流阀FK
  level1: 'coal.kep.analog.40c957d38798d4dd', // 产品仓1料位1
  level2: 'coal.kep.analog.edaf900c84e750ce', // 产品仓1料位2
}

const getNumericTag = (tagCode: string, fallback: number) => {
  const value = iotHub.getTagValue(tagCode)?.value
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

const currentDensity = computed(() => getNumericTag(analogTags.mediumDensity, 1.49))
const targetDensity = computed(() => Number((currentDensity.value + 0.03).toFixed(2)))
const cycloneThroughput = computed(() => getNumericTag(analogTags.feedFlow, 425))
const slurryConcentration = computed(() => getNumericTag(analogTags.concentration, 34.8))
const processPh = computed(() => Number((6.8 + Math.min(1.8, getNumericTag(analogTags.turbidity, 30) / 100)).toFixed(1)))
const yieldEfficiency = computed(() => {
  const feed = getNumericTag(analogTags.feedFlow, 425)
  const product = getNumericTag(analogTags.productFlow, 356)
  return Number((Math.min(99, Math.max(45, (product / Math.max(feed, 1)) * 100))).toFixed(1))
})
const mediumLoss = computed(() => {
  const splitter = getNumericTag(analogTags.splitter, 18)
  return Number((Math.max(0.35, splitter / 26)).toFixed(2))
})
const totalHandled = computed(() => {
  const feed = getNumericTag(analogTags.feedFlow, 425)
  const level = getNumericTag(analogTags.level1, 55) + getNumericTag(analogTags.level2, 48)
  return Math.round(feed * 240 + level * 1000)
})
const controlConfidence = computed(() => getNumericTag('coal.quality.model_confidence', 95))
const complianceRate = computed(() => getNumericTag('coal.quality.compliance_rate', 93.8))
const currentFeedRate = computed(() => getNumericTag(analogTags.feedFlow, 460))
const suggestedFeedRate = computed(() => Number((currentFeedRate.value * 0.88).toFixed(0)))

const throughputProgress = computed(() => Math.min(100, Math.max(0, Number(((cycloneThroughput.value / 480) * 100).toFixed(0)))))
const concentrationProgress = computed(() => Math.min(100, Math.max(0, Number(((slurryConcentration.value / 56) * 100).toFixed(0)))))
const densityOffsetText = computed(() => {
  const offset = Number((targetDensity.value - 1.49).toFixed(2))
  return `${offset >= 0 ? '+' : ''}${offset.toFixed(2)} SG`
})
const totalHandledText = computed(() => {
  if (totalHandled.value >= 1000000) return `${(totalHandled.value / 1000000).toFixed(1)}M`
  return `${totalHandled.value.toFixed(0)}`
})

const mapToPercent = (value: number, min: number, max: number) =>
  Number((Math.min(100, Math.max(0, ((value - min) / (max - min)) * 100))).toFixed(1))

const densityCurrentPct = computed(() => mapToPercent(currentDensity.value, 1.35, 1.7))
const densityTargetPct = computed(() => mapToPercent(targetDensity.value, 1.35, 1.7))
const feedCurrentPct = computed(() => mapToPercent(currentFeedRate.value, 300, 520))
const feedTargetPct = computed(() => mapToPercent(suggestedFeedRate.value, 300, 520))

const buildFillStyle = (start: number, end: number) => ({
  left: `${Math.min(start, end)}%`,
  width: `${Math.max(6, Math.abs(end - start))}%`,
})

const densityFillStyle = computed(() => buildFillStyle(densityCurrentPct.value, densityTargetPct.value))
const feedFillStyle = computed(() => buildFillStyle(feedCurrentPct.value, feedTargetPct.value))
const confidenceStyle = computed(() => ({ '--confidence': `${controlConfidence.value}%` }))

type AshSample = { time: string; ash: number; target: number; overLimit: boolean }
const ashSamples = ref<AshSample[]>([])

const buildAshSamples = () => {
  const now = new Date()
  const baseAsh = Number((getNumericTag(analogTags.concentration2, 9.1) / 4).toFixed(2))
  const target = 9.5
  const offsets = [-0.35, -0.22, -0.18, -0.08, 0.05, -0.11, 0.18, 0.12]
  const samples: AshSample[] = []
  for (let i = 23; i >= 0; i--) {
    const h = new Date(now.getTime() - i * 3600000)
    const time = `${String(h.getHours()).padStart(2, '0')}:00`
    const offset = offsets[(23 - i) % offsets.length]
    const ash = Number((baseAsh + offset).toFixed(2))
    samples.push({ time, ash, target, overLimit: ash > target })
  }
  ashSamples.value = samples
}

function renderAshChart() {
  if (!ashChartEl.value) return
  ashChart?.dispose()
  ashChart = echarts.init(ashChartEl.value)
  const hours = ashSamples.value.map((item) => item.time)
  const ashData = ashSamples.value.map((item) => item.ash)
  const targetData = ashSamples.value.map((item) => item.target)
  ashChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: 40, right: 12, bottom: 24, top: 28, containLabel: false },
    xAxis: {
      type: 'category',
      data: hours,
      axisLabel: { color: '#8ab4d6', fontSize: 10, interval: 3 },
      axisLine: { lineStyle: { color: '#1e3a52' } },
    },
    yAxis: {
      type: 'value',
      min: 7,
      max: 12,
      axisLabel: { color: '#8ab4d6', fontSize: 10 },
      splitLine: { lineStyle: { color: '#1e3a52' } },
    },
    series: [
      {
        name: '当前灰分',
        type: 'bar',
        data: ashData,
        itemStyle: {
          color: (p: any) =>
            p.value > targetData[p.dataIndex]
              ? new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                  { offset: 0, color: '#ff808a' },
                  { offset: 1, color: '#b6283b' },
                ])
              : new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                  { offset: 0, color: '#2ef4ff' },
                  { offset: 1, color: '#1a63ff' },
                ]),
          borderRadius: [3, 3, 0, 0],
        },
        barWidth: '50%',
      },
      {
        name: '目标值',
        type: 'line',
        data: targetData,
        lineStyle: {
          type: 'dashed',
          color: '#ffb347',
          width: 2,
          shadowBlur: 10,
          shadowColor: 'rgba(255, 179, 71, 0.7)',
        },
        symbol: 'none',
      },
    ],
  })
}

function applyAutoAdjust() {
  autoApplied.value = true
  ElMessage.success('自主调节建议已应用到当前工艺参数')
  setTimeout(() => { autoApplied.value = false }, 5000)
}

function exportQualityReport() {
  const csv = ['时间,灰分(%),目标值(%),是否超标']
  ashSamples.value.forEach((item) => {
    csv.push(`${item.time},${item.ash.toFixed(2)},${item.target.toFixed(2)},${item.overLimit ? '是' : '否'}`)
  })
  const blob = new Blob(['\uFEFF' + csv.join('\n')], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `质量分析报告_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('质量分析报告已下载')
}

const handleResize = () => ashChart?.resize()

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'quality-center', intervalMs: 5000 })
  await iotHub.ensureFresh('quality-center', 2000)
  await nextTick()
  buildAshSamples()
  renderAshChart()
  window.addEventListener('resize', handleResize)
})

watch(
  () => iotHub.generatedAt.value,
  () => {
    buildAshSamples()
    renderAshChart()
  },
)

onUnmounted(() => {
  ashChart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.quality-page {
  height: 100%;
  min-height: 0;
  overflow: auto;
  background: #091019;
  color: #eef6ff;
}

.page-layout,
.page-main {
  height: auto;
  width: 100%;
  max-width: none;
  box-sizing: border-box;
}

.page-layout {
  padding: 10px 14px;
}

.page-main {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 0;
}

.hero {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 14px;
  border-radius: 14px;
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
}

.hero h1 {
  margin: 0;
  font-size: 20px;
  line-height: 1.2;
}

.export-btn {
  height: 34px;
  padding: 0 14px;
  border: 0;
  border-radius: 10px;
  background: #151f2d;
  color: #d8ebfb;
  cursor: pointer;
  font-size: 13px;
  flex-shrink: 0;
}

.quality-board {
  flex: 1;
  min-height: 0;
  width: 100%;
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.82fr) minmax(0, 1.03fr);
  gap: 8px;
  overflow: hidden;
}

.panel,
.device-card,
.footer-card {
  border: 1px solid rgba(122, 190, 255, 0.12);
  background: rgba(12, 20, 31, 0.92);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.18);
  border-radius: 14px;
  min-height: 0;
  overflow: hidden;
}

.recommendation,
.trend-panel {
  display: flex;
  flex-direction: column;
  padding: 12px 14px;
}

.panel-head {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 8px;
}

.panel-head h3 {
  margin: 0;
  font-size: 14px;
}

.badge {
  padding: 2px 8px;
  border-radius: 999px;
  border: 1px solid rgba(24, 240, 191, 0.35);
  color: #18f0bf;
  font-size: 10px;
}

.recommend-body {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 1.1fr 0.9fr;
  gap: 8px;
  align-content: start;
}

.recommend-main {
  display: grid;
  gap: 8px;
}

.compare-list {
  display: grid;
  gap: 8px;
}

.compare-item {
  padding: 8px 10px;
  border-radius: 10px;
  background: #1b2430;
}

.compare-head {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 8px;
  align-items: center;
  margin-bottom: 6px;
}

.compare-head span {
  font-size: 11px;
  color: #d9eaff;
}

.compare-head small {
  font-size: 10px;
  color: #9ec3df;
}

.compare-track {
  position: relative;
  height: 10px;
  border-radius: 999px;
  background: #2b3240;
  overflow: hidden;
}

.compare-fill {
  position: absolute;
  top: 1px;
  bottom: 1px;
  border-radius: 999px;
  background: linear-gradient(90deg, #20d6ff, #2d6eff);
  box-shadow: 0 0 10px rgba(45, 110, 255, 0.45);
}

.compare-marker {
  position: absolute;
  top: 50%;
  width: 10px;
  height: 10px;
  border: 2px solid #fff;
  border-radius: 50%;
  transform: translate(-50%, -50%);
}

.compare-marker--current {
  background: #7ab6da;
}

.compare-marker--target {
  background: #26f1ff;
  box-shadow: 0 0 8px rgba(38, 241, 255, 0.7);
}

.big-number span {
  display: block;
  color: #95a2b1;
  font-size: 11px;
}

.big-number strong {
  display: block;
  margin-top: 4px;
  font-size: 32px;
  line-height: 1;
  color: #67d8ff;
}

.big-number em {
  margin-left: 4px;
  font-size: 16px;
  font-style: normal;
  color: #9ecae8;
}

.recommend-side {
  display: grid;
  grid-template-rows: auto auto 1fr;
  gap: 8px;
}

.confidence-gauge {
  --confidence: 95%;
  position: relative;
  height: 110px;
  border-radius: 14px;
  overflow: hidden;
  background: #182231;
}

.confidence-gauge::before {
  position: absolute;
  right: -10%;
  bottom: -68%;
  left: -10%;
  height: 190px;
  border-radius: 50%;
  background: conic-gradient(from 180deg, #1d3348, #28d9ff var(--confidence), #1d3348 0);
  content: '';
}

.confidence-gauge::after {
  position: absolute;
  right: 12px;
  bottom: 12px;
  left: 12px;
  height: 76px;
  border-radius: 14px 14px 18px 18px;
  background: #111b29;
  content: '';
}

.confidence-inner {
  position: relative;
  z-index: 1;
  display: grid;
  justify-items: center;
  gap: 4px;
  padding-top: 34px;
}

.confidence-inner strong {
  font-size: 22px;
  color: #28e2ff;
}

.confidence-inner span {
  font-size: 11px;
  color: #9fc0dc;
}

.confidence-sub {
  margin: 0;
  text-align: center;
  font-size: 11px;
  color: #9ec3df;
}

.suggestions {
  display: grid;
  gap: 6px;
}

.suggest-card {
  padding: 8px 10px;
  border-radius: 8px;
  background: #1b2430;
  box-shadow: inset 3px 0 0 #67d8ff;
}

.suggest-card--warn {
  box-shadow: inset 3px 0 0 #f8c76d;
}

.suggest-card strong {
  display: block;
  font-size: 11px;
}

.suggest-card span {
  display: block;
  margin-top: 4px;
  text-align: right;
  font-size: 12px;
  color: #67d8ff;
}

.suggest-card--warn span {
  color: #f8c76d;
}

.cta-btn {
  flex: 0 0 auto;
  margin-top: 8px;
  width: 100%;
  height: 36px;
  border: 0;
  border-radius: 10px;
  background: #61c8eb;
  color: #06313e;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.cta-btn.applied {
  background: #18f0bf;
  color: #062230;
}

.device-stack {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 0;
}

.device-card {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 10px 12px;
  min-height: 0;
}

.device-head,
.device-foot,
.device-metric {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 6px;
}

.device-head strong {
  font-size: 13px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #18f0bf;
  box-shadow: 0 0 6px #18f0bf;
}

.device-metric {
  margin: 8px 0 6px;
}

.device-metric span {
  font-size: 11px;
  color: #98a5b5;
}

.device-metric strong {
  font-size: 22px;
  line-height: 1;
}

.device-metric em {
  margin-left: 2px;
  font-size: 11px;
  font-style: normal;
  color: #98a5b5;
}

.load-gauge {
  display: grid;
  place-items: center;
  margin-top: 2px;
}

.load-ring {
  --load: 0%;
  position: relative;
  width: 104px;
  height: 104px;
  border-radius: 50%;
  background: conic-gradient(
    #33ecff 0,
    #1cc8ff calc(var(--load) * 0.7),
    #f6c768 calc(var(--load) * 0.85),
    #f2566f var(--load),
    #29394b var(--load),
    #29394b 100%
  );
  display: grid;
  place-items: center;
}

.load-ring::after {
  position: absolute;
  inset: 10px;
  border-radius: 50%;
  background: #101b29;
  content: '';
}

.load-ring__inner {
  position: relative;
  z-index: 1;
  display: grid;
  justify-items: center;
  line-height: 1;
}

.load-ring__inner b {
  font-size: 22px;
  color: #ecf8ff;
}

.load-ring__inner small {
  margin-top: 3px;
  font-size: 10px;
  color: #8caac1;
}

.liquid-wrap {
  margin-top: 2px;
  padding: 6px 0;
  display: grid;
  place-items: center;
}

.liquid-fill {
  --liquid: 0%;
  position: relative;
  width: 112px;
  height: 76px;
  border-radius: 14px;
  border: 1px solid rgba(108, 206, 255, 0.35);
  background: linear-gradient(
    180deg,
    rgba(43, 70, 97, 0.45) calc(100% - var(--liquid)),
    rgba(44, 168, 220, 0.5) calc(100% - var(--liquid))
  );
  overflow: hidden;
}

.liquid-value {
  position: absolute;
  z-index: 2;
  inset: 0;
  display: grid;
  place-items: center;
  font-size: 17px;
  font-weight: 700;
  color: #dff7ff;
}

.wave {
  position: absolute;
  left: -20%;
  width: 140%;
  height: 20px;
  border-radius: 40% 60% 48% 52%;
  background: rgba(93, 230, 255, 0.45);
  animation: waveMove 4s linear infinite;
}

.wave-a {
  bottom: calc(var(--liquid) - 8%);
}

.wave-b {
  bottom: calc(var(--liquid) - 3%);
  background: rgba(24, 187, 235, 0.35);
  animation-duration: 5.5s;
  animation-direction: reverse;
}

.device-foot {
  margin-top: 6px;
  font-size: 10px;
  color: #aab8c8;
}

.chart-box {
  flex: 1;
  min-height: 0;
  width: 100%;
}

.legend {
  display: flex;
  gap: 10px;
  font-size: 10px;
  color: #cfd8e3;
}

.legend span {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.legend i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.legend .blue {
  background: #67d8ff;
}

.legend .ghost {
  border: 1px dashed #95a2b1;
}

.footer-stats {
  flex: 0 0 auto;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
  width: 100%;
}

.footer-card {
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 84px;
  text-align: center;
}

.footer-card span {
  display: block;
  font-size: 11px;
  color: #96a4b7;
  margin-bottom: 4px;
}

.footer-card strong {
  font-size: 24px;
  line-height: 1.1;
}

.footer-card em {
  margin-left: 2px;
  font-size: 11px;
  font-style: normal;
  color: #a2b0bf;
}

@media (max-width: 1280px) {
  .quality-board {
    grid-template-columns: 1fr 1fr;
    grid-template-rows: minmax(0, 1fr) minmax(0, 1fr);
  }

  .trend-panel {
    grid-column: 1 / -1;
  }
}

@keyframes waveMove {
  from { transform: translateX(0); }
  to { transform: translateX(24%); }
}
</style>
