<template>
  <div class="coal-home">
    <header class="hero-shell">
      <div class="hero-copy">
        <p class="eyebrow">平台总入口</p>
        <h1>金正泰智能化选煤厂管控平台</h1>

        <div class="metric-row">
          <article v-for="item in coreMetrics" :key="item.label" class="metric-card" :class="`metric-card--${item.tone}`">
            <div class="metric-head">
              <span class="metric-icon" aria-hidden="true">{{ item.icon }}</span>
              <span class="metric-label">{{ item.label }}</span>
            </div>
            <div class="metric-mainline">
              <strong>{{ item.value }}</strong>
              <span>{{ item.unit }}</span>
            </div>
            <svg class="metric-sparkline" viewBox="0 0 120 30" preserveAspectRatio="none" aria-hidden="true">
              <polygon :points="`0,30 ${item.sparkline} 120,30`" />
              <polyline :points="item.sparkline" />
            </svg>
            <small>{{ item.note }}</small>
          </article>
        </div>
      </div>

      <div class="hero-panel">
        <div class="panel-topline">
          <span class="status-dot"></span>
          <span>实时运行总览</span>
        </div>
        <div class="time-cluster">
          <div class="time-text">{{ currentTime }}</div>
          <div class="date-text">{{ currentDate }}</div>
        </div>
        <div class="quick-status">
          <div v-for="item in runtimeStatus" :key="item.label" class="runtime-pill" :class="`runtime-pill--${item.tone}`">
            <div class="runtime-row">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
            </div>
            <div class="runtime-bar" aria-hidden="true">
              <i :style="{ width: item.progress }"></i>
            </div>
          </div>
        </div>
      </div>
    </header>

    <main class="content-shell">
      <section class="section-card">
        <div class="section-head">
          <div>
            <span class="section-tag">核心入口</span>
            <h2>业务总览</h2>
          </div>
          <p>按导航收敛后的六类业务组织入口，减少页面堆叠。</p>
        </div>
        <div class="entry-grid">
          <router-link v-for="item in simpleEntries" :key="item.path" :to="item.path" class="entry-card">
            <span class="entry-icon" aria-hidden="true">{{ item.icon }}</span>
            <strong>{{ item.title }}</strong>
            <span>{{ item.desc }}</span>
          </router-link>
        </div>
      </section>

      <section class="section-card">
        <div class="section-head">
          <div>
            <span class="section-tag">现场数据</span>
            <h2>当班运行明细</h2>
          </div>
          <p>补充现场验收时最容易关注的生产、设备、煤质和能耗数据。</p>
        </div>
        <div class="data-grid">
          <article v-for="item in operationCards" :key="item.title" class="data-card">
            <div>
              <strong>{{ item.title }}</strong>
              <span>{{ item.subtitle }}</span>
            </div>
            <b>{{ item.value }}</b>
            <small>{{ item.note }}</small>
          </article>
        </div>
      </section>

      <section class="section-card">
        <div class="section-head">
          <div>
            <span class="section-tag">快捷专题</span>
            <h2>常用页面</h2>
          </div>
          <p>把常用页面保留在首页下方，顶部导航只展示归纳后的一级分类。</p>
        </div>
        <div class="topic-grid">
          <router-link v-for="item in shortcutEntries" :key="item.path" :to="item.path" class="topic-card">
            <div class="topic-title">{{ item.title }}</div>
            <p>{{ item.desc }}</p>
          </router-link>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

const currentTime = ref('')
const currentDate = ref('')

const coreMetrics = [
  { icon: '入', label: '今日入洗量', value: '5,280', unit: 't', note: '较昨日 +4.2%', tone: 'cyan', sparkline: '0,23 12,19 24,21 36,15 48,17 60,11 72,13 84,8 96,10 108,6 120,9' },
  { icon: '精', label: '精煤产量', value: '3,410', unit: 't', note: '达成率 97.1%', tone: 'green', sparkline: '0,21 12,20 24,16 36,18 48,13 60,12 72,10 84,13 96,9 108,8 120,7' },
  { icon: '电', label: '实时总功率', value: '850', unit: 'kW', note: '峰段负荷可控', tone: 'violet', sparkline: '0,19 12,17 24,14 36,16 48,13 60,15 72,11 84,9 96,13 108,10 120,8' },
]

const runtimeStatus = [
  { label: '设备完好率', value: '97.4%', progress: '97.4%', tone: 'green' },
  { label: '质量达标率', value: '96.8%', progress: '96.8%', tone: 'cyan' },
  { label: '能耗偏差', value: '-1.9%', progress: '82%', tone: 'violet' },
  { label: '未闭环告警', value: '3 项', progress: '35%', tone: 'amber' },
]

const simpleEntries = [
  { icon: '产', title: '生产运行', path: '/coal/production', desc: '生产调度、计划排班、工艺流程和调度日志。' },
  { icon: '设', title: '设备运维', path: '/coal/equipment', desc: '设备台账、电机电流、变频器电流和故障分析。' },
  { icon: '质', title: '质量能耗', path: '/coal/quality', desc: '煤质化验、耗电录入、水平衡和储装销售。' },
  { icon: '智', title: '智能优化', path: '/coal/decision', desc: '智能决策、建模分析、密控和加药模型。' },
  { icon: '报', title: '报表中心', path: '/coal/report', desc: '生产、质量、能耗、设备报表和实时打印。' },
  { icon: '系', title: '平台系统', path: '/coal/settings', desc: '系统设置、数据接入、集成和治理。' },
]

const operationCards = [
  { title: '破碎站', subtitle: '润华设备接入', value: '78%', note: '主破碎机电流 68.2 A' },
  { title: '煤泥水', subtitle: '浓度监测', value: '34%', note: '沉降和回收持续关注' },
  { title: '水平衡', subtitle: '循环水回用', value: '92%', note: '差额 +2.6%，可控' },
  { title: '电耗单耗', subtitle: '当班录入', value: '5.68', note: 'kWh/t，低于考核线' },
  { title: '精煤灰分', subtitle: '质量指标', value: '8.3%', note: '预测结果稳定' },
  { title: '设备故障', subtitle: '智能分析', value: '3 项', note: '破碎站、离心机、压滤泵' },
]

const shortcutEntries = [
  { title: '综合看板', path: '/coal/dashboard', desc: '查看综合指标和运行状态。' },
  { title: '设备大屏', path: '/coal/equipment-screen', desc: '查看设备状态大屏。' },
  { title: '工艺流程', path: '/coal/process-flow', desc: '查看破碎、洗选和煤泥水流程。' },
  { title: '排班管理', path: '/coal/shift-schedule', desc: '配置二班倒、三班倒和检修班。' },
  { title: '能耗管理', path: '/coal/energy', desc: '录入耗电量并查看水平衡。' },
  { title: '数据接入', path: '/coal/data-access', desc: '维护点位、接口和字段映射。' },
]

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('zh-CN', { hour12: false })
  currentDate.value = now.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'long',
  })
}

let timer = 0

onMounted(() => {
  updateTime()
  timer = window.setInterval(updateTime, 1000)
})

onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.coal-home {
  min-height: 100vh;
  padding: 92px 20px 28px;
  background:
    radial-gradient(circle at 12% 14%, rgba(92, 184, 236, 0.18), transparent 25%),
    radial-gradient(circle at 86% 8%, rgba(43, 213, 166, 0.13), transparent 22%),
    linear-gradient(180deg, #61798f 0%, #40566b 100%);
  color: #f2f7fb;
}

.hero-shell,
.section-card {
  position: relative;
  width: min(100%, 1800px);
  margin: 0 auto 18px;
  overflow: hidden;
  border: 1px solid rgba(236, 247, 255, 0.13);
  border-radius: 12px;
  background:
    linear-gradient(135deg, rgba(255, 255, 255, 0.06), transparent 36%),
    rgba(31, 48, 63, 0.9);
  box-shadow:
    0 22px 54px rgba(7, 16, 25, 0.34),
    inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.hero-shell::before,
.section-card::before {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(rgba(170, 218, 246, 0.055) 1px, transparent 1px),
    linear-gradient(90deg, rgba(170, 218, 246, 0.045) 1px, transparent 1px);
  background-size: 34px 34px;
  opacity: 0.55;
  pointer-events: none;
  content: '';
}

.hero-copy,
.hero-panel,
.section-head,
.entry-grid,
.data-grid,
.topic-grid {
  position: relative;
  z-index: 1;
}

.hero-shell {
  display: grid;
  grid-template-columns: 1.45fr 0.85fr;
  gap: 18px;
  padding: 28px 30px;
}

.eyebrow,
.section-tag {
  display: block;
  margin: 0 0 10px;
  color: #9fe8ff;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.14em;
}

.hero-copy h1 {
  margin: 0;
  color: #ffffff;
  font-size: 40px;
  line-height: 1.15;
  text-shadow: 0 8px 24px rgba(3, 12, 20, 0.38);
}

.section-head p,
.entry-card span,
.topic-card p,
.data-card span,
.data-card small,
.metric-card small {
  color: rgba(231, 240, 247, 0.72);
}

.metric-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-top: 24px;
}

.metric-card,
.entry-card,
.topic-card,
.data-card {
  position: relative;
  border: 1px solid rgba(236, 247, 255, 0.14);
  clip-path: polygon(0 0, calc(100% - 11px) 0, 100% 11px, 100% 100%, 11px 100%, 0 calc(100% - 11px));
  background: rgba(95, 119, 140, 0.34);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
  transition: border-color 0.18s ease, box-shadow 0.18s ease, transform 0.18s ease, background 0.18s ease;
}

.metric-card:hover,
.entry-card:hover,
.topic-card:hover,
.data-card:hover {
  border-color: rgba(120, 220, 255, 0.36);
  background: rgba(104, 131, 153, 0.42);
  box-shadow: 0 14px 28px rgba(5, 15, 24, 0.24), inset 0 1px 0 rgba(255, 255, 255, 0.11);
  transform: translateY(-2px);
}

.metric-card {
  padding: 16px;
}

.metric-head {
  display: flex;
  align-items: center;
  gap: 10px;
}

.metric-icon,
.entry-icon {
  display: grid;
  place-items: center;
  flex: 0 0 auto;
  width: 30px;
  height: 30px;
  border: 1px solid rgba(137, 226, 255, 0.24);
  border-radius: 7px;
  background: linear-gradient(135deg, rgba(76, 210, 255, 0.18), rgba(44, 224, 174, 0.1));
  color: #bff2ff;
  font-size: 14px;
  font-weight: 800;
}

.metric-label,
.metric-card small,
.metric-mainline {
  display: block;
}

.metric-mainline {
  margin-top: 12px;
}

.metric-mainline strong {
  color: #9be8ff;
  font-family: "DIN Alternate", "Roboto Condensed", "Arial Narrow", "Microsoft YaHei", sans-serif;
  font-size: 34px;
  font-weight: 900;
  letter-spacing: 0;
}

.metric-mainline span {
  margin-left: 6px;
  color: rgba(231, 240, 247, 0.7);
}

.metric-sparkline {
  width: 100%;
  height: 36px;
  margin: 9px 0 7px;
}

.metric-sparkline polygon {
  fill: rgba(64, 206, 255, 0.13);
}

.metric-sparkline polyline {
  fill: none;
  stroke: #36c8f2;
  stroke-width: 3;
  stroke-linecap: round;
  stroke-linejoin: round;
  filter: drop-shadow(0 0 5px rgba(54, 200, 242, 0.45));
}

.metric-card--green .metric-mainline strong { color: #64f0bb; }
.metric-card--green .metric-sparkline polygon { fill: rgba(70, 224, 174, 0.13); }
.metric-card--green .metric-sparkline polyline { stroke: #30d59d; }
.metric-card--amber .metric-mainline strong { color: #ffd18a; }
.metric-card--amber .metric-sparkline polygon { fill: rgba(255, 168, 54, 0.14); }
.metric-card--amber .metric-sparkline polyline { stroke: #f2a531; }
.metric-card--violet .metric-mainline strong { color: #b8c7ff; }
.metric-card--violet .metric-sparkline polygon { fill: rgba(139, 155, 255, 0.14); }
.metric-card--violet .metric-sparkline polyline { stroke: #8f9eff; }

.hero-panel {
  padding: 22px;
  border: 1px solid rgba(236, 247, 255, 0.14);
  border-radius: 10px;
  background:
    linear-gradient(180deg, rgba(112, 137, 159, 0.26) 0%, rgba(25, 39, 54, 0.54) 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.panel-topline {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #9fe8ff;
  font-weight: 800;
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #22d6a6;
  box-shadow: 0 0 0 5px rgba(34, 214, 166, 0.12), 0 0 16px rgba(34, 214, 166, 0.7);
  animation: pulse 1.8s ease-in-out infinite;
}

.time-cluster {
  margin: 24px 0;
}

.time-text {
  color: #ffffff;
  font-family: "DIN Alternate", "Roboto Condensed", "Arial Narrow", "Microsoft YaHei", sans-serif;
  font-size: 42px;
  font-weight: 900;
}

.date-text {
  margin-top: 10px;
  color: rgba(231, 240, 247, 0.72);
}

.quick-status {
  display: grid;
  gap: 10px;
}

.runtime-pill {
  padding: 12px 13px;
  border: 1px solid rgba(236, 247, 255, 0.14);
  border-radius: 8px;
  background: rgba(92, 114, 134, 0.34);
}

.runtime-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.runtime-pill strong {
  color: #ffffff;
}

.runtime-bar {
  position: relative;
  height: 4px;
  margin-top: 10px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.11);
}

.runtime-bar i {
  position: absolute;
  inset: 0 auto 0 0;
  border-radius: inherit;
  background: linear-gradient(90deg, #39d5ff, #3ee0b0);
  box-shadow: 0 0 12px rgba(73, 219, 255, 0.48);
}

.runtime-pill--amber .runtime-bar i { background: linear-gradient(90deg, #ffd18a, #f2a531); }
.runtime-pill--violet .runtime-bar i { background: linear-gradient(90deg, #99a8ff, #63d5ff); }

.content-shell {
  width: min(100%, 1800px);
  margin: 0 auto;
}

.section-card {
  padding: 24px 28px 28px;
}

.section-head {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  align-items: flex-end;
  margin-bottom: 18px;
}

.section-head h2 {
  margin: 0;
  color: #ffffff;
}

.section-head p {
  max-width: 520px;
  margin: 0;
  line-height: 1.65;
}

.entry-grid,
.topic-grid,
.data-grid {
  display: grid;
  gap: 14px;
}

.entry-grid {
  grid-template-columns: repeat(3, 1fr);
}

.topic-grid,
.data-grid {
  grid-template-columns: repeat(6, 1fr);
}

.entry-card,
.topic-card {
  display: grid;
  gap: 10px;
  padding: 18px 16px;
  color: inherit;
  text-decoration: none;
}

.entry-card strong,
.topic-title,
.data-card strong {
  color: #ffffff;
  font-size: 18px;
}

.entry-card span,
.topic-card p {
  margin: 0;
  line-height: 1.6;
}

.data-card {
  display: grid;
  gap: 12px;
  min-height: 150px;
  padding: 18px 16px;
}

.data-card div {
  display: grid;
  gap: 6px;
}

.data-card b {
  color: #9be8ff;
  font-family: "DIN Alternate", "Roboto Condensed", "Arial Narrow", "Microsoft YaHei", sans-serif;
  font-size: 30px;
  line-height: 1;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
    opacity: 1;
  }

  50% {
    transform: scale(0.78);
    opacity: 0.68;
  }
}

@media (max-width: 1280px) {
  .hero-shell {
    grid-template-columns: 1fr;
  }

  .metric-row,
  .entry-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .topic-grid,
  .data-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 760px) {
  .coal-home {
    padding: 20px 12px;
  }

  .hero-shell,
  .section-card {
    padding: 18px;
  }

  .hero-copy h1 {
    font-size: 30px;
  }

  .metric-row,
  .entry-grid,
  .topic-grid,
  .data-grid {
    grid-template-columns: 1fr;
  }

  .section-head {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
