<template>
  <div class="mobile-home">
    <header class="header">
      <strong>金正泰管控平台</strong>
      <span>移动端</span>
    </header>

    <main class="main">
      <button v-for="item in menus" :key="item.path" type="button" class="menu-card" @click="navigate(item.path)">
        <strong>{{ item.title }}</strong>
        <span>{{ item.desc }}</span>
      </button>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
const menus = [
  { path: '/dashboard', title: '数据总览', desc: '生产、能耗、告警总览' },
  { path: '/monitor', title: '实时监控', desc: '设备运行和现场状态' },
  { path: '/alarm', title: '报警中心', desc: '异常报警和处理进度' },
  { path: '/device', title: '设备管理', desc: '台账、电流、故障信息' },
  { path: '/report', title: '报表中心', desc: '中文月份和星期查询' },
  { path: '/workorder', title: '工单管理', desc: '检修和闭环任务' },
]

const navigate = (path: string) => {
  router.push(path)
}
</script>

<style scoped>
.mobile-home {
  min-height: 100vh;
  background: #edf2f7;
  color: #17212b;
}

.header {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background: #1d2b38;
  color: #fff;
}

.header strong {
  font-size: 18px;
}

.header span {
  color: #9ddfff;
  font-size: 13px;
}

.main {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  padding: 14px;
}

.menu-card {
  min-height: 118px;
  padding: 16px;
  border: 1px solid #d7e0e8;
  border-radius: 10px;
  background: #fff;
  color: #17212b;
  text-align: left;
  box-shadow: 0 8px 22px rgba(25, 38, 52, 0.08);
}

.menu-card strong,
.menu-card span {
  display: block;
}

.menu-card strong {
  font-size: 17px;
}

.menu-card span {
  margin-top: 10px;
  color: #607080;
  line-height: 1.45;
}

@media (max-width: 420px) {
  .main {
    grid-template-columns: 1fr;
  }
}
</style>
