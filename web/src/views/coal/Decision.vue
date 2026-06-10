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
        <div v-for="item in suggestions" :key="item.title" class="suggestion" :class="`suggestion--${item.level}`">
          <div class="suggestion-head">
            <el-tag size="small" :class="['suggestion-tag', `suggestion-tag--${item.tagType}`]">{{ item.tagText }}</el-tag>
            <strong>{{ item.title }}</strong>
          </div>
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
          <el-table-column prop="status" label="状态" width="140">
            <template #default="{ row }">
              <span class="task-status" :class="statusClass(row.status)">
                <i class="status-dot" aria-hidden="true"></i>
                {{ row.status }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="deadline" label="截止时间" width="170" />
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="{ row }">
              <div class="task-actions">
                <el-button v-if="row.status === '待处理'" type="warning" link @click="dispatchTask(row)">一键派发</el-button>
                <el-button v-else-if="row.status === '处理中'" type="primary" link @click="processTask(row)">去处理</el-button>
                <el-button v-else type="info" link @click="viewTask(row)">查看</el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

const suggestions = ref([
  { title: '密度调整建议', content: '建议将悬浮液密度保持在 1.42-1.44，当前精煤灰分波动可控。', tagText: '模型联动', tagType: 'linkage', level: 'normal' },
  { title: '煤泥水关注', content: '煤泥水浓度偏高，建议检查浓缩机底流和絮凝剂添加量。', tagText: '异常预警', tagType: 'warning', level: 'warning' },
  { title: '水平衡建议', content: '清水补入和循环水回用处于平衡状态，继续跟踪夜班变化。', tagText: '流程建议', tagType: 'neutral', level: 'normal' },
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

const statusClass = (status: string) => {
  if (status === '待处理') return 'task-status--pending'
  if (status === '处理中') return 'task-status--running'
  return 'task-status--done'
}

const dispatchTask = (row: { topic: string }) => {
  ElMessage.success(`已派发任务：${row.topic}`)
}

const processTask = (row: { topic: string }) => {
  ElMessage.success(`已进入处理流程：${row.topic}`)
}

const viewTask = (row: { topic: string }) => {
  ElMessage.success(`已查看任务：${row.topic}`)
}
</script>

<style scoped>
.decision-page{height:100%;overflow:hidden;padding:0;background:#16202a;color:#eef6ff}.page-hero,.content-grid{width:min(100%,1680px);margin:0 auto 16px}.page-hero,.panel{border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:20px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff}.page-hero h1{margin:0}.page-hero p{color:#c8d6e3}.content-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.panel{padding:22px}.panel--wide{grid-column:1/-1}.panel h2{margin:0 0 16px}.suggestion,.fault{padding:16px;margin-bottom:12px;border-radius:8px;background:#17212b}.suggestion strong{color:#8bdfff}.suggestion p,.fault p{margin:8px 0;color:#c8d6e3}.fault small{color:#8bdfff}.fault.warn{box-shadow:inset 4px 0 0 #f6b94c}.fault.danger{box-shadow:inset 4px 0 0 #ff7878}@media(max-width:1100px){.decision-page{padding-top:24px}.page-hero,.content-grid{grid-template-columns:1fr;flex-direction:column}}
.suggestion{background:rgba(16,33,50,.8);border:1px solid rgba(126,195,255,.16)}
.suggestion-head{display:flex;align-items:center;gap:10px}
.suggestion-tag{border-radius:999px;border:0}
.suggestion-tag--linkage{background:rgba(55,173,255,.22);color:#7fd3ff}
.suggestion-tag--warning{background:rgba(255,180,71,.22);color:#ffc56e}
.suggestion-tag--neutral{background:rgba(128,154,183,.2);color:#c4d8eb}
.suggestion--warning{border-left:3px solid rgba(255,180,71,.88)}
.task-status{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:12px}
.status-dot{width:7px;height:7px;border-radius:50%}
.task-status--pending{color:#ffca74;background:rgba(255,153,0,.2)}
.task-status--pending .status-dot{background:#ff9b1a;box-shadow:0 0 8px rgba(255,155,26,.75);animation:pulse 1.4s ease-in-out infinite}
.task-status--running{color:#8fd2ff;background:rgba(45,140,240,.2)}
.task-status--running .status-dot{background:#48b1ff;box-shadow:0 0 8px rgba(72,177,255,.72);animation:pulse 1.7s ease-in-out infinite}
.task-status--done{color:#b8c8d7;background:rgba(128,154,183,.2)}
.task-status--done .status-dot{background:#8b9fb2}
.task-actions{display:flex;gap:8px}
@keyframes pulse{0%,100%{opacity:.55;transform:scale(.9)}50%{opacity:1;transform:scale(1.1)}}
</style>
