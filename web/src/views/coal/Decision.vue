<template>
  <div class="decision-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">智能决策</p>
        <h1>智能决策与设备故障分析</h1>
        <p>在原有质量预测和工艺建议基础上，增加设备故障分析、破碎站风险和检修建议。</p>
      </div>
      <el-button type="primary" @click="runAnalysis">生成建议</el-button>
    </section>

    <section class="content-grid">
      <article class="panel">
        <h2>生产质量建议</h2>
        <div v-for="item in suggestions" :key="item.title" class="suggestion">
          <strong>{{ item.title }}</strong>
          <p>{{ item.content }}</p>
        </div>
      </article>

      <article class="panel">
        <h2>设备故障分析</h2>
        <div v-for="item in faultAnalysis" :key="item.device" class="fault" :class="item.level">
          <strong>{{ item.device }}</strong>
          <p>{{ item.reason }}</p>
          <small>处置建议：{{ item.action }}</small>
        </div>
      </article>

      <article class="panel panel--wide">
        <h2>决策任务台账</h2>
        <el-table :data="tasks">
          <el-table-column prop="topic" label="主题" min-width="220" />
          <el-table-column prop="source" label="来源" width="160" />
          <el-table-column prop="owner" label="责任岗位" width="140" />
          <el-table-column prop="status" label="状态" width="120" />
          <el-table-column prop="deadline" label="截止时间" width="170" />
        </el-table>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

const suggestions = ref([
  { title: '密度调整建议', content: '建议将悬浮液密度保持在 1.42-1.44，当前精煤灰分波动可控。' },
  { title: '煤泥水关注', content: '煤泥水浓度偏高，建议检查浓缩机底流和絮凝剂添加量。' },
  { title: '水平衡建议', content: '清水补入和循环水回用处于平衡状态，继续跟踪夜班变化。' },
])

const faultAnalysis = ref([
  { device: '311 中煤离心机', level: 'warn', reason: '振动值升高且电机电流波动，疑似轴承或筛篮磨损。', action: '安排检修班复核轴承温度、筛篮磨损和基础螺栓。' },
  { device: '润华破碎站二号机', level: 'warn', reason: '破碎站电流偏高，负荷高于 80%。', action: '降低给料量 5%，检查破碎腔堵料和入料粒度。' },
  { device: '压滤机进料泵', level: 'danger', reason: '变频器电流峰值超过阈值。', action: '检查管路结垢、阀门开度和泵入口压力。' },
])

const tasks = ref([
  { topic: '破碎站二号机电流偏高排查', source: '设备故障分析', owner: '机电班', status: '待处理', deadline: '2026-04-13 18:00' },
  { topic: '煤泥水浓度优化', source: '水平衡分析', owner: '生产一班', status: '处理中', deadline: '2026-04-13 20:00' },
  { topic: '精煤灰分波动跟踪', source: '质量预测', owner: '化验室', status: '已派发', deadline: '2026-04-14 09:00' },
])

function runAnalysis() {
  ElMessage.success('已刷新智能建议和设备故障分析')
}
</script>

<style scoped>
.decision-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}.page-hero,.content-grid{width:min(100%,1680px);margin:0 auto 16px}.page-hero,.panel{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:20px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff}.page-hero h1{margin:0}.page-hero p{color:#c8d6e3}.content-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel h2{margin:0 0 16px}.suggestion,.fault{padding:16px;margin-bottom:12px;border-radius:8px;background:#17212b}.suggestion strong{color:#8bdfff}.suggestion p,.fault p{margin:8px 0;color:#c8d6e3}.fault small{color:#8bdfff}.fault.warn{box-shadow:inset 4px 0 0 #f6b94c}.fault.danger{box-shadow:inset 4px 0 0 #ff7878}@media(max-width:1100px){.decision-page{padding-top:24px}.page-hero,.content-grid{grid-template-columns:1fr;flex-direction:column}}
</style>
