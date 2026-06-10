<template>
  <div class="business-page dashboard-page">
    <section class="page-header">
      <div>
        <p class="page-tag">综合数据</p>
        <h1>综合数据总览</h1>
        <p class="page-desc">保留业务总览页，用于日常查看指标、台账和调度信息；大屏展示单独通过入口打开。</p>
      </div>
      <div class="page-actions">
        <el-button @click="router.push('/jzt/coal/production')">生产分析</el-button>
        <el-button @click="router.push('/jzt/coal/dispatch')">调度管理</el-button>
        <el-button type="primary" @click="router.push('/jzt/coal/dashboard-screen')">查看综合大屏</el-button>
      </div>
    </section>

    <section class="kpi-grid">
      <article v-for="item in kpis" :key="item.label" class="kpi-card" :class="`kpi-card--${item.type}`">
        <div class="kpi-copy">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
          <small>{{ item.note }}</small>
          <p class="kpi-goal">目标 {{ item.target }}</p>
        </div>
        <div v-if="item.type === 'gauge'" class="kpi-gauge" :style="{ '--p': item.rate }">
          <b>{{ item.rate }}</b>
        </div>
        <div v-else class="kpi-rate-pill">
          达成 {{ item.rate }}
        </div>
      </article>
    </section>

    <section class="content-grid">
      <article class="panel panel--wide">
        <div class="panel-head">
          <div>
            <h2>入洗与产销趋势</h2>
            <p>最近 7 天的入洗量、精煤量和销量变化。</p>
          </div>
        </div>
        <div ref="trendChartRef" class="chart-box chart-box--trend"></div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <div>
            <h2>仓位状态</h2>
            <p>关键仓位当前占用情况。</p>
          </div>
        </div>
        <div ref="stockChartRef" class="chart-box chart-box--small"></div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <div>
            <h2>煤质指标</h2>
            <p>灰分、硫分和全水分趋势。</p>
          </div>
        </div>
        <div ref="qualityChartRef" class="chart-box chart-box--small"></div>
      </article>

      <article class="panel">
        <div class="panel-head">
          <div>
            <h2>调度日报</h2>
            <p>班组交接和日常调度摘要。</p>
          </div>
        </div>
        <el-table :data="dispatchRows" class="data-table">
          <el-table-column prop="time" label="时间" width="120" />
          <el-table-column prop="content" label="内容" min-width="220" />
          <el-table-column prop="reporter" label="汇报人" width="120" />
          <el-table-column prop="receiver" label="接班人" width="120" />
        </el-table>
      </article>

      <article class="panel">
        <div class="panel-head">
          <div>
            <h2>环境数据</h2>
            <p>重点仓位与区域环境监控。</p>
          </div>
        </div>
        <el-table :data="envRows" class="data-table">
          <el-table-column prop="name" label="监测点" min-width="140" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="value" label="当前值" width="120" />
          <el-table-column prop="status" label="状态" width="100" />
        </el-table>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { echarts } from '../../utils/echarts'
import { useIotHub } from '../../composables/useIotHub'

const router = useRouter()
const iotHub = useIotHub()
const analogTags = {
  rawFlow: 'coal.kep.analog.a39438b3226da48b', // 301原煤皮带秤瞬时流量
  productFlow: 'coal.kep.analog.7f4f2eafd4bd21ea', // 701AWTA瞬时流量
  freq338: 'coal.kep.analog.27426c0853a2b547', // 338清水泵频率反馈
  tempMotor: 'coal.kep.analog.b108db3d0488a7c0', // 314合介泵定子A相温度
  humidityLike: 'coal.kep.analog.070e59650bc4ce5f', // ND1X浓度1
  dustLike: 'coal.kep.analog.2770e3447a38c77b', // ZDJX浊度
}

const getRealtimeValue = (tagCode: string, fallback: number, digits = 1) => {
  const live = iotHub.getTagValue(tagCode)
  if (!live || typeof live.value !== 'number') return fallback.toFixed(digits)
  return live.value.toFixed(digits)
}

const abnormalCount = computed(
  () => Object.values(iotHub.realtimeMap.value).filter((item) => item.quality !== 'GOOD').length,
)

const kpis = computed(() => [
  {
    label: '今日入洗原煤',
    value: `${(Number(getRealtimeValue(analogTags.rawFlow, 2900, 1)) * 24).toFixed(0)} 吨`,
    note: '由原煤皮带秤瞬时流量折算',
    target: '3,200吨',
    rate: '91%',
    type: 'bar',
  },
  {
    label: '今日精煤产量',
    value: `${(Number(getRealtimeValue(analogTags.productFlow, 2180, 1)) * 24).toFixed(0)} 吨`,
    note: '由产品皮带瞬时流量折算',
    target: '2,400吨',
    rate: '90%',
    type: 'bar',
  },
  {
    label: '综合单耗',
    value: getRealtimeValue(analogTags.freq338, 12.1, 1),
    note: '来自清水泵频率反馈',
    target: '≤ 12.5',
    rate: '74%',
    type: 'gauge',
  },
  {
    label: '待处理告警',
    value: `${abnormalCount.value || 2} 项`,
    note: '质量异常点位统计',
    target: '0项',
    rate: '34%',
    type: 'bar',
  },
])

const dispatchRows = [
  { time: '2025-01-13', content: '夜班正常交接，主洗系统运行稳定。', reporter: '刘丽媛', receiver: '杨慧洁' },
  { time: '2025-01-12', content: '中班产量达标，产品仓切换完成。', reporter: '张申立', receiver: '刘丽媛' },
  { time: '2025-01-12', content: '早班入洗原煤波动，已调整密度。', reporter: '杨慧洁', receiver: '张申立' },
]

const envRows = computed(() => {
  const temp = iotHub.getTagValue(analogTags.tempMotor)
  const humidity = iotHub.getTagValue(analogTags.humidityLike)
  const dust = iotHub.getTagValue(analogTags.dustLike)
  return [
    { name: '合介泵电机', type: '温度', value: `${temp?.value?.toFixed?.(1) || '26.4'}°C`, status: temp?.quality === 'GOOD' ? '正常' : '关注' },
    { name: '煤泥浓度', type: '浓度', value: `${humidity?.value?.toFixed?.(1) || '63'}%`, status: humidity?.quality === 'GOOD' ? '正常' : '关注' },
    { name: '工艺浊度', type: '浊度', value: `${dust?.value?.toFixed?.(2) || '0.12'} NTU`, status: dust?.quality === 'GOOD' ? '正常' : '关注' },
  ]
})

const trendChartRef = ref<HTMLElement | null>(null)
const stockChartRef = ref<HTMLElement | null>(null)
const qualityChartRef = ref<HTMLElement | null>(null)

let trendChart: any = null
let stockChart: any = null
let qualityChart: any = null

const renderCharts = () => {
  if (trendChartRef.value) {
    trendChart ??= echarts.init(trendChartRef.value)
    const feedSeries = [2800, 2315, 2500, 2840, 2960, 2200, 2900]
    const productSeries = [2100, 1805, 1875, 2130, 2220, 1693, 2180]
    const ratioSeries = [82, 86, 79, 88, 91, 84, 90]
    const tonMin = Math.min(...feedSeries, ...productSeries)
    const tonMax = Math.max(...feedSeries, ...productSeries)
    trendChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { top: 2, itemWidth: 16, itemHeight: 8, textStyle: { color: '#dbe7ff', fontSize: 12 } },
      grid: { top: 18, left: 46, right: 46, bottom: 18 },
      xAxis: {
        type: 'category',
        data: ['01-06', '01-07', '01-08', '01-09', '01-10', '01-11', '01-12'],
        axisLabel: { color: '#9bb7d5', margin: 10 },
        axisLine: { lineStyle: { color: '#203447' } },
      },
      yAxis: [
        {
          type: 'value',
          name: '吨',
          min: Math.max(0, Math.floor((tonMin - 260) / 100) * 100),
          max: Math.ceil((tonMax + 220) / 100) * 100,
          splitNumber: 4,
          nameTextStyle: { color: 'rgba(225, 239, 255, 0.72)' },
          axisLabel: { color: '#9bb7d5' },
          splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } },
        },
        {
          type: 'value',
          name: '产销率',
          min: 70,
          max: 100,
          axisLabel: { color: '#ffdca1', formatter: '{value}%' },
          splitLine: { show: false },
        },
      ],
      series: [
        {
          name: '入洗量',
          type: 'bar',
          data: feedSeries,
          barWidth: 26,
          barGap: '20%',
          itemStyle: {
            borderRadius: [10, 10, 0, 0],
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: '#53f2ff' },
              { offset: 1, color: '#2185ff' },
            ]),
          },
        },
        {
          name: '精煤量',
          type: 'bar',
          data: productSeries,
          barWidth: 26,
          itemStyle: {
            borderRadius: [10, 10, 0, 0],
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: '#85ffcc' },
              { offset: 1, color: '#2ec9ff' },
            ]),
          },
        },
        {
          name: '产销率',
          type: 'line',
          smooth: true,
          yAxisIndex: 1,
          data: ratioSeries,
          symbolSize: 10,
          lineStyle: { width: 3.8, color: '#ffd75e' },
          itemStyle: { color: '#ffe28f' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(255, 215, 94, 0.42)' },
              { offset: 1, color: 'rgba(255, 215, 94, 0.03)' },
            ]),
          },
        },
      ],
    })
  }

  if (stockChartRef.value) {
    stockChart ??= echarts.init(stockChartRef.value)
    const stockValues = [72, 64, 24, 91]
    stockChart.setOption({
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
        formatter: (params: any) => {
          const target = params.find((item: any) => item.seriesName === '仓位')
          return `${target?.axisValue}<br/>仓位：${target?.value}%`
        },
      },
      grid: { top: 34, left: 38, right: 18, bottom: 28 },
      xAxis: {
        type: 'category',
        data: ['1#原煤仓', '1#产品仓', '3#产品仓', '2#精煤仓'],
        axisLabel: { color: '#9bb7d5', margin: 12 },
        axisLine: { lineStyle: { color: '#203447' } },
      },
      yAxis: {
        type: 'value',
        min: 0,
        max: 100,
        axisLabel: { color: '#9bb7d5' },
        splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } },
      },
      series: [
        {
          name: '容量',
          type: 'bar',
          data: [100, 100, 100, 100],
          barWidth: 36,
          barGap: '-100%',
          itemStyle: {
            color: 'rgba(84, 112, 143, 0.2)',
            borderRadius: [18, 18, 8, 8],
          },
          z: 1,
        },
        {
          name: '仓位',
          type: 'bar',
          data: stockValues,
          barWidth: 36,
          itemStyle: {
            color: (params: any) => {
              const value = stockValues[params.dataIndex]
              if (value >= 85) {
                return new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                  { offset: 0, color: '#ff8f7d' },
                  { offset: 1, color: '#ff4e5f' },
                ])
              }
              if (value <= 30) {
                return new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                  { offset: 0, color: '#ffe388' },
                  { offset: 1, color: '#f7b947' },
                ])
              }
              return new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#69f3ff' },
                { offset: 1, color: '#2a88ff' },
              ])
            },
            borderRadius: [18, 18, 8, 8],
          },
          label: {
            show: true,
            position: 'top',
            distance: 8,
            color: '#eaf6ff',
            fontWeight: 700,
            formatter: (params: any) => {
              const value = stockValues[params.dataIndex]
              if (value >= 90) return `{danger|${value}%}`
              if (value <= 30) return `{warn|${value}%}`
              return `{normal|${value}%}`
            },
            rich: {
              normal: { color: '#d7efff', fontSize: 12, fontWeight: 700 },
              warn: { color: '#ffd679', fontSize: 12, fontWeight: 700 },
              danger: { color: '#ff9ba0', fontSize: 12, fontWeight: 700 },
            },
          },
          z: 3,
        },
        {
          name: '仓位顶部',
          type: 'pictorialBar',
          data: stockValues,
          symbol: 'circle',
          symbolSize: [36, 12],
          symbolOffset: [0, -4],
          itemStyle: {
            color: '#b9f4ff',
            opacity: 0.4,
          },
          z: 4,
        },
        {
          name: '仓位底部',
          type: 'pictorialBar',
          data: [0, 0, 0, 0],
          symbol: 'circle',
          symbolSize: [36, 12],
          symbolOffset: [0, 6],
          itemStyle: {
            color: 'rgba(92, 116, 143, 0.42)',
          },
          z: 2,
        },
      ],
    })
  }

  if (qualityChartRef.value) {
    qualityChart ??= echarts.init(qualityChartRef.value)
    qualityChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { top: 2, itemWidth: 16, itemHeight: 8, textStyle: { color: '#dbe7ff' } },
      grid: { top: 24, left: 48, right: 44, bottom: 24 },
      xAxis: {
        type: 'category',
        data: ['01-06', '01-07', '01-08', '01-09', '01-10', '01-11', '01-12'],
        axisLabel: { color: '#9bb7d5' },
        axisLine: { lineStyle: { color: '#203447' } },
      },
      yAxis: [
        {
          type: 'value',
          min: 10,
          max: 32,
          axisLabel: { color: '#9bb7d5' },
          splitLine: { lineStyle: { color: 'rgba(255,255,255,0.08)' } },
        },
        {
          type: 'value',
          min: 0.9,
          max: 1.2,
          axisLabel: { color: '#8dff97', formatter: (value: number) => value.toFixed(2) },
          splitLine: { show: false },
        },
      ],
      series: [
        {
          name: '灰分',
          type: 'line',
          smooth: true,
          stack: 'qualityA',
          symbolSize: 7,
          lineStyle: { width: 3, color: '#48ccff' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(72, 204, 255, 0.44)' },
              { offset: 1, color: 'rgba(72, 204, 255, 0.08)' },
            ]),
          },
          data: [17.5, 17.2, 17.4, 17.8, 17.6, 17.3, 17.1],
        },
        {
          name: '灰分柱',
          type: 'bar',
          barWidth: 10,
          barGap: '-100%',
          tooltip: { show: false },
          itemStyle: {
            borderRadius: [6, 6, 0, 0],
            color: 'rgba(72, 204, 255, 0.18)',
          },
          data: [17.5, 17.2, 17.4, 17.8, 17.6, 17.3, 17.1],
          z: 1,
        },
        {
          name: '硫分',
          type: 'line',
          smooth: true,
          yAxisIndex: 1,
          stack: 'qualityB',
          symbolSize: 7,
          lineStyle: { width: 3, color: '#7eff8b' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(126, 255, 139, 0.36)' },
              { offset: 1, color: 'rgba(126, 255, 139, 0.08)' },
            ]),
          },
          data: [1.1, 1.05, 1.13, 1.09, 1.14, 1.12, 1.1],
        },
        {
          name: '全水分',
          type: 'line',
          smooth: true,
          stack: 'qualityA',
          symbolSize: 7,
          lineStyle: { width: 3, color: '#ffd75e' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(255, 215, 94, 0.42)' },
              { offset: 1, color: 'rgba(255, 215, 94, 0.08)' },
            ]),
          },
          data: [28.6, 28.9, 29.1, 29.3, 29.0, 28.8, 29.0],
        },
        {
          name: '全水分柱',
          type: 'bar',
          barWidth: 10,
          tooltip: { show: false },
          itemStyle: {
            borderRadius: [6, 6, 0, 0],
            color: 'rgba(255, 215, 94, 0.18)',
          },
          data: [28.6, 28.9, 29.1, 29.3, 29.0, 28.8, 29.0],
          z: 1,
        },
      ],
    })
  }
}

onMounted(() => {
  iotHub.subscribe({ pageKey: 'coal-dashboard', intervalMs: 5000 })
  renderCharts()
  window.addEventListener('resize', renderCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', renderCharts)
  trendChart?.dispose()
  stockChart?.dispose()
  qualityChart?.dispose()
})
</script>

<style scoped>
.business-page {
  height: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 6px 10px 10px;
  background: #091019;
  color: #eef6ff;
}

.page-header,
.kpi-grid,
.content-grid {
  width: min(100%, 1780px);
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 12px 16px;
  border: 1px solid rgba(106, 188, 255, 0.2);
  border-radius: 14px;
  background:
    linear-gradient(135deg, rgba(60, 134, 190, 0.14), transparent 38%),
    rgba(8, 19, 30, 0.94);
  box-shadow: 0 12px 28px rgba(3, 12, 22, 0.26);
}

.page-tag {
  margin: 0 0 4px;
  color: #7ad8ff;
  font-size: 11px;
  letter-spacing: 0.12em;
}

.page-header h1,
.panel-head h2 {
  margin: 0;
}

.page-header h1 {
  font-size: 34px;
  line-height: 1.08;
  letter-spacing: 0.02em;
}

.page-desc,
.panel-head p {
  margin: 4px 0 0;
  color: rgba(227, 239, 250, 0.62);
  line-height: 1.45;
  font-size: 12px;
}

.page-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.page-actions :deep(.el-button) {
  min-width: 88px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid rgba(112, 197, 255, 0.36);
  background: rgba(16, 34, 52, 0.88);
  color: #dff5ff;
  font-size: 12px;
  font-weight: 600;
}

.page-actions :deep(.el-button:hover) {
  border-color: rgba(154, 223, 255, 0.65);
  color: #ffffff;
}

.page-actions :deep(.el-button--primary) {
  border-color: rgba(126, 208, 255, 0.65);
  background: linear-gradient(135deg, #2ea4ff 0%, #2a73ff 100%);
  color: #f8fcff;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.dashboard-page .kpi-grid {
  flex: 0 0 auto !important;
  min-height: auto !important;
  overflow: visible !important;
}

.kpi-card,
.panel {
  border: 1px solid rgba(96, 220, 255, 0.17);
  border-radius: 14px;
  background:
    linear-gradient(135deg, rgba(59, 101, 130, 0.18), transparent 45%),
    rgba(8, 19, 30, 0.95);
  box-shadow:
    inset 0 1px 0 rgba(199, 246, 255, 0.06),
    0 10px 24px rgba(3, 12, 22, 0.24);
}

.kpi-card {
  position: relative;
  overflow: hidden;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 6px;
  min-height: 70px;
  padding: 8px 10px;
}

.kpi-card::before {
  position: absolute;
  top: 0;
  left: 14px;
  right: 14px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(106, 215, 255, 0.65), transparent);
  content: '';
}

.kpi-card::after {
  position: absolute;
  inset: auto 14px 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(125, 217, 255, 0.35), transparent);
  content: '';
}

.kpi-card span {
  display: block;
  color: rgba(227, 239, 250, 0.62);
  font-size: 11px;
}

.kpi-card strong {
  display: block;
  margin-top: 2px;
  font-size: 24px;
  line-height: 1.05;
  color: #f3faff;
  text-shadow: 0 6px 16px rgba(75, 183, 255, 0.25);
}

.kpi-card small {
  display: none;
  margin-top: 0;
  color: rgba(127, 223, 255, 0.82);
  font-size: 10px;
}

.kpi-goal {
  margin: 1px 0 0;
  color: #d6eeff;
  font-size: 10px;
  font-weight: 400;
}

.kpi-copy {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-height: 0;
}

.kpi-rate-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 24px;
  padding: 0 8px;
  border-radius: 999px;
  font-size: 10px;
  color: #fff7d8;
  font-weight: 600;
  background: linear-gradient(135deg, rgba(245, 193, 90, 0.34), rgba(255, 226, 143, 0.2));
  border: 1px solid rgba(255, 225, 154, 0.45);
}

.kpi-gauge {
  display: grid;
  place-items: center;
  width: 58px;
  height: 58px;
  border-radius: 50%;
  background:
    radial-gradient(circle at center, rgba(8, 19, 30, 0.98) 0 55%, transparent 56%),
    conic-gradient(#2df2ff var(--p), #f6c253 calc(var(--p) + 1%), rgba(255,255,255,0.12) 0);
  box-shadow: 0 0 22px rgba(45, 242, 255, 0.28);
}

.kpi-gauge b {
  color: #dffcff;
  font-size: 12px;
}

.content-grid {
  display: grid;
  grid-template-columns: 1.25fr 0.75fr;
  grid-template-rows: minmax(0, 2.6fr) minmax(0, 1.25fr) minmax(0, 1.25fr);
  gap: 12px;
  flex: 1;
  min-height: 0;
}

.dashboard-page .content-grid {
  flex: 1 1 auto !important;
  min-height: 0 !important;
  grid-template-columns: 1.25fr 0.75fr !important;
  grid-template-rows: minmax(0, 2.6fr) minmax(0, 1.25fr) minmax(0, 1.25fr) !important;
}

.panel {
  padding: 14px 16px;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.panel--wide {
  grid-column: 1 / -1;
}

.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
  flex: 0 0 auto;
}

.panel-head h2 {
  font-size: 17px;
  letter-spacing: 0.01em;
}

.chart-box {
  height: 100%;
  flex: 1;
  min-height: 0;
}

.chart-box--small {
  min-height: 210px;
}

.chart-box--trend {
  min-height: 320px;
}

.data-table :deep(.el-table),
.data-table :deep(.el-table__inner-wrapper),
.data-table :deep(.el-table tr),
.data-table :deep(.el-table th.el-table__cell),
.data-table :deep(.el-table td.el-table__cell) {
  background: transparent;
  color: #eef6ff;
}

.data-table :deep(.el-table__body-wrapper) {
  max-height: 100%;
  overflow: auto;
}

.data-table :deep(.el-table__header th.el-table__cell) {
  color: #7ecfff;
}

.data-table :deep(.el-table__cell) {
  padding: 9px 0;
}

.data-table :deep(.cell) {
  font-size: 13px;
}

.data-table :deep(.el-table__body tr:nth-child(odd) > td.el-table__cell) {
  background: rgba(18, 39, 59, 0.46);
}

.data-table :deep(.el-table__body tr:nth-child(even) > td.el-table__cell) {
  background: rgba(13, 28, 43, 0.24);
}

@media (max-width: 1200px) {
  .kpi-grid,
  .content-grid {
    grid-template-columns: 1fr;
  }

  .content-grid {
    grid-template-rows: repeat(5, minmax(0, 1fr));
  }
}

@media (max-width: 900px) {
  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .page-actions {
    flex-wrap: wrap;
  }

  .kpi-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
