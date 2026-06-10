<template>
  <div class="coal-page-v2 monitor-page">
    <div class="page-layout">
      <main class="page-main">
        <section class="hero">
          <div>
            <p class="eyebrow">巡检监测</p>
            <h1>智能巡检与人员安全中心</h1>
            <p class="hero-text">集中展示巡检覆盖率、人员分布、AI 异常识别和任务执行状态，便于安全与调度协同处理。</p>
          </div>
          <div class="hero-tips">
            <div class="tip-card">
              <span>当前在线巡检员</span>
              <strong>8 人</strong>
            </div>
            <div class="tip-card">
              <span>待处理报警</span>
              <strong class="danger">3 条</strong>
            </div>
          </div>
        </section>

        <section class="stats-grid">
          <article v-for="item in stats" :key="item.label" class="stat-card" :class="item.className">
            <div>
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <small>{{ item.note }}</small>
            </div>
            <el-icon><component :is="item.icon" /></el-icon>
          </article>
        </section>

        <div class="monitor-body">
          <article class="panel map-panel">
            <div class="panel-head">
              <h3>厂区 2D 区域监控与人员分布</h3>
              <div class="map-tags">
                <span>作业人员：42</span>
                <span>巡检员：8</span>
              </div>
            </div>
            <div class="map-stage">
              <div class="map-placeholder">2D 厂区平面示意</div>
              <span class="pulse p1"></span>
              <span class="pulse p2 danger"></span>
              <span class="pulse p3 blue"></span>
              <div class="activity-list">
                <article v-for="item in activities" :key="item.time + item.title" class="activity-card" :class="item.level">
                  <div>
                    <strong>{{ item.title }}</strong>
                    <p>{{ item.name }}</p>
                  </div>
                  <span>{{ item.time }}</span>
                </article>
              </div>
            </div>
          </article>

          <article class="panel ai-panel">
            <div class="panel-head">
              <h3>AI 视觉异常识别</h3>
            </div>
            <div class="ai-cards">
              <article v-for="item in aiCards" :key="item.title" class="ai-card">
                <div class="ai-image" :class="item.imageClass"></div>
                <div class="ai-copy">
                  <div class="ai-top">
                    <strong>{{ item.title }}</strong>
                    <span>{{ item.time }}</span>
                  </div>
                  <p>{{ item.desc }}</p>
                  <span class="ai-tag" :class="item.level">{{ item.tag }}</span>
                </div>
              </article>
            </div>
          </article>

          <article class="panel alert-panel">
            <div class="panel-head">
              <h3>安全报警中心</h3>
            </div>
            <div class="alert-list">
              <article v-for="(item, idx) in alerts" :key="item.title + item.time" class="alert-card" :class="item.level">
                <div class="alert-top">
                  <strong>{{ item.title }}</strong>
                  <span>{{ item.time }}</span>
                </div>
                <p>{{ item.desc }}</p>
                <button v-if="item.level !== 'normal'" type="button" class="alert-ack-btn" @click="ackAlert(idx)">确认处理</button>
              </article>
            </div>
          </article>

          <article class="panel task-panel">
            <div class="panel-head">
              <h3>当前巡检任务</h3>
              <button type="button" class="ghost-btn" @click="notify('已打开全部巡检任务列表')">查看全部</button>
            </div>
            <div class="task-table-wrap">
              <table class="task-table">
                <thead>
                  <tr>
                    <th>任务名称</th>
                    <th>巡检员</th>
                    <th>进度</th>
                    <th>状态</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in tasks" :key="item.name">
                    <td>{{ item.name }}</td>
                    <td>{{ item.user }}</td>
                    <td>
                      <div class="progress"><div class="progress-fill" :style="{ width: item.progress }"></div></div>
                      <span>{{ item.progress }}</span>
                    </td>
                    <td>
                      <span v-if="item.status === '已完成'" class="task-status done">已完成</span>
                      <button v-else-if="item.status === '等待开始'" type="button" class="task-action" @click="startTask(item)">开始</button>
                      <button v-else type="button" class="task-action running" @click="completeTask(item)">完成</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </article>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Bell, Monitor, Setting, User } from '@element-plus/icons-vue'

type TaskItem = { name: string; user: string; progress: string; status: string; statusClass: string }
type AlertItem = { title: string; time: string; desc: string; level: string }

const tasks = ref<TaskItem[]>([
  { name: '三层原煤输送系统日检', user: '王克勤', progress: '75%', status: '正在执行', statusClass: 'running' },
  { name: '浮选机液位巡检', user: '赵大成', progress: '45%', status: '正在执行', statusClass: 'running' },
  { name: '变电站配电柜季检', user: '孙兴', progress: '0%', status: '等待开始', statusClass: 'idle' },
])

const alerts = ref<AlertItem[]>([
  { title: '区域闯入报警', time: '14:42:01', desc: '外来人员未授权进入高压电磁屏蔽区，系统已通知现场安保。', level: 'danger' },
  { title: '巡检超时预警', time: '14:15:33', desc: '4 号浓缩池巡检停留时间超过 20 分钟，请确认是否需要协助。', level: 'warn' },
  { title: '报警处理完成', time: '13:50:00', desc: '胶仓皮带偏斜报警已由现场人工复位，系统恢复正常监控。', level: 'normal' },
])

const activeAlertCount = computed(() => alerts.value.filter(a => a.level !== 'normal').length)

const stats = computed(() => [
  { label: '人员到岗率', value: '98.4%', note: '较昨日提升 1.2%', className: 'green', icon: User },
  { label: '巡检覆盖率', value: `${Math.round(tasks.value.filter(t => t.status === '已完成').length / tasks.value.length * 100) || 100}%`, note: `${tasks.value.filter(t => t.status === '已完成').length}/${tasks.value.length} 项已完成`, className: 'blue', icon: Monitor },
  { label: '运行设备', value: '124 台', note: '3 台正在检修中', className: 'yellow', icon: Setting },
  { label: '异常告警', value: `${String(activeAlertCount.value).padStart(2, '0')} 条`, note: `${alerts.value.length} 条记录`, className: 'red', icon: Bell },
])

const activities = [
  { title: '作业中', name: '张伟 - 3 号洗选池', time: '14:52', level: 'ok' },
  { title: '巡检中', name: '王克勤 - 2 号皮带', time: '14:50', level: 'info' },
  { title: '警报', name: '李明 - 限制区域', time: '14:48', level: 'danger' },
  { title: '作业中', name: '赵强 - 压滤车间', time: '14:45', level: 'ok' },
  { title: '作业中', name: '孙大志 - 1 号转载点', time: '14:42', level: 'ok' },
]

const aiCards = [
  { title: '2 号传送带区域', desc: '检测到人员进入作业区域但未正确佩戴防护装备，需要现场复核。', time: '14:23:45', tag: '未戴安全帽', level: 'danger', imageClass: 'image-warn' },
  { title: '压滤机 4 号阀门', desc: '检测到设备附近存在异常高温点，建议立即安排巡检人员复查。', time: '14:10:12', tag: '疑似高温异常', level: 'warn', imageClass: 'image-heat' },
]

function startTask(item: TaskItem) {
  item.status = '正在执行'
  item.statusClass = 'running'
  item.progress = '10%'
  ElMessage.success(`${item.name} 已开始执行`)
}

function completeTask(item: TaskItem) {
  item.status = '已完成'
  item.statusClass = 'done'
  item.progress = '100%'
  ElMessage.success(`${item.name} 已标记完成`)
}

function ackAlert(idx: number) {
  const item = alerts.value[idx]
  const now = new Date()
  const timeStr = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}:${String(now.getSeconds()).padStart(2,'0')}`
  alerts.value.splice(idx, 1, { ...item, level: 'normal', title: item.title + '（已处理）', time: timeStr, desc: item.desc + ' —— 已确认处理。' })
  ElMessage.success('报警已确认处理')
}

const notify = (message: string) => ElMessage.success(message)
</script>

<style scoped>
.coal-page-v2 {
  height: 100%;
  overflow: hidden;
  background: #091019;
  color: #eef6ff;
}

.page-main {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow: hidden;
}

.panel,
.stat-card {
  border: 1px solid rgba(122, 190, 255, 0.1);
  background: rgba(12, 20, 31, 0.92);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.18);
  border-radius: 14px;
  padding: 12px 14px;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.stats-grid {
  flex: 0 0 auto;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.stat-card {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 10px 12px;
}

.stat-card span {
  font-size: 12px;
  color: #97a4b4;
}

.stat-card strong {
  display: block;
  margin: 6px 0 4px;
  font-size: 22px;
  line-height: 1;
}

.stat-card small {
  font-size: 11px;
  color: #c4d0db;
}

.stat-card :deep(.el-icon) {
  font-size: 20px;
  color: #67d8ff;
  opacity: 0.7;
}

.monitor-body {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 1.35fr 1fr;
  grid-template-rows: minmax(0, 1fr) minmax(0, 1fr);
  gap: 8px;
  overflow: hidden;
}

.map-panel {
  grid-column: 1;
  grid-row: 1;
}

.alert-panel {
  grid-column: 1;
  grid-row: 2;
}

.ai-panel {
  grid-column: 2;
  grid-row: 1;
}

.task-panel {
  grid-column: 2;
  grid-row: 2;
}

.hero-tips {
  display: flex;
  gap: 8px;
}

.tip-card {
  min-width: 120px;
  padding: 10px 12px;
  border-radius: 12px;
  background: #141f2d;
}

.tip-card span {
  display: block;
  color: #92a6bc;
  font-size: 11px;
}

.tip-card strong {
  display: block;
  margin-top: 4px;
  font-size: 18px;
}

.tip-card strong.danger {
  color: #ff7a82;
}

.panel-head h3 {
  margin: 0;
  font-size: 15px;
}

.map-tags {
  display: flex;
  gap: 8px;
}

.map-tags span {
  padding: 4px 10px;
  border-radius: 999px;
  background: #1e2631;
  color: #afc1d0;
  font-size: 11px;
}

.map-stage {
  position: relative;
  flex: 1;
  min-height: 0;
  border-radius: 12px;
  background: #0f141b;
  overflow: hidden;
}
.map-placeholder{position:absolute;left:18px;top:16px;color:#8895a7;font-size:18px}
.pulse{position:absolute;width:18px;height:18px;border-radius:50%;background:#19f0c1;box-shadow:0 0 0 6px rgba(25,240,193,.12),0 0 16px rgba(25,240,193,.8)}.pulse.blue{background:#68d8ff;box-shadow:0 0 0 6px rgba(104,216,255,.12),0 0 16px rgba(104,216,255,.8)}.pulse.danger{background:#ff6f73;box-shadow:0 0 0 6px rgba(255,111,115,.12),0 0 16px rgba(255,111,115,.8)}
.p1{left:38%;top:34%}.p2{left:63%;top:66%}.p3{left:70%;top:82%}
.activity-list {
  position: absolute;
  right: 8px;
  top: 0;
  width: 180px;
  height: 100%;
  padding: 8px;
  background: rgba(27, 34, 44, 0.92);
  overflow: hidden;
}

.activity-card {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  padding: 8px;
  margin-bottom: 6px;
  border-left: 3px solid #3adcb7;
  background: #202732;
  font-size: 11px;
}

.activity-card.info {
  border-left-color: #68d8ff;
}

.activity-card.danger {
  border-left-color: #ff6f73;
}

.activity-card strong {
  display: block;
  margin-bottom: 2px;
  font-size: 12px;
}

.activity-card p {
  margin: 0;
  color: #dbe6f1;
}

.ai-cards {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-rows: repeat(2, minmax(0, 1fr));
  gap: 8px;
  overflow: hidden;
}

.ai-card {
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  overflow: hidden;
  background: #1b222c;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.ai-image {
  flex: 0 0 56px;
  min-height: 56px;
}

.ai-image.image-warn {
  background: radial-gradient(circle at 58% 40%, #f9cb68, #8d5516 36%, #23160f 70%);
}

.ai-image.image-heat {
  background: radial-gradient(circle at 35% 28%, #676767, #111 56%, #321818 100%);
}

.ai-copy {
  padding: 8px 10px;
  flex: 1;
  min-height: 0;
}

.ai-top {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 4px;
  font-size: 12px;
}

.ai-copy p {
  margin: 0 0 6px;
  color: #cad6e0;
  line-height: 1.4;
  font-size: 11px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.ai-tag {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
}

.ai-tag.danger {
  background: #ff7b7f;
  color: #fff;
}

.ai-tag.warn {
  background: #f7c463;
  color: #3b2800;
}

.ghost-btn {
  height: 28px;
  padding: 0 10px;
  border: 1px solid rgba(104, 216, 255, 0.35);
  border-radius: 8px;
  background: transparent;
  color: #68d8ff;
  cursor: pointer;
  font-size: 12px;
}

.task-table-wrap {
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

.task-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.task-table th,
.task-table td {
  padding: 8px 10px;
  text-align: left;
}

.task-table thead th {
  background: #111821;
  color: #96a4b7;
}

.progress {
  display: inline-block;
  width: 72px;
  height: 6px;
  margin-right: 6px;
  border-radius: 999px;
  background: #2b3240;
  vertical-align: middle;
}

.progress-fill {
  height: 100%;
  border-radius: inherit;
  background: #78dcff;
}

.task-status {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
}

.task-status.done {
  background: rgba(103, 216, 255, 0.15);
  color: #67d8ff;
}

.task-action {
  height: 28px;
  padding: 0 10px;
  border: 1px solid #2f93ba;
  background: transparent;
  color: #86dfff;
  border-radius: 8px;
  cursor: pointer;
  font-size: 11px;
}

.task-action.running {
  border-color: #18f0bf;
  color: #18f0bf;
}

.alert-list {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow: hidden;
}

.alert-card {
  flex: 1;
  min-height: 0;
  padding: 10px 12px;
  border-radius: 12px;
  background: #1b222c;
  overflow: hidden;
}

.alert-card.danger {
  box-shadow: inset 4px 0 0 #ff6f73;
}

.alert-card.warn {
  box-shadow: inset 4px 0 0 #f7c463;
}

.alert-card.normal {
  box-shadow: inset 4px 0 0 #8f99a6;
}

.alert-top {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 6px;
  font-size: 12px;
}

.alert-card p {
  margin: 0;
  color: #cad6e0;
  line-height: 1.45;
  font-size: 11px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.alert-ack-btn {
  margin-top: 8px;
  height: 28px;
  padding: 0 12px;
  border: 1px solid rgba(255, 111, 115, 0.4);
  border-radius: 8px;
  background: transparent;
  color: #ff8b90;
  cursor: pointer;
  font-size: 11px;
}

@media (max-width: 1200px) {
  .monitor-body {
    grid-template-columns: 1fr;
    grid-template-rows: repeat(4, minmax(0, 1fr));
  }

  .map-panel,
  .alert-panel,
  .ai-panel,
  .task-panel {
    grid-column: 1;
    grid-row: auto;
  }
}
</style>
