<template>
  <header class="coal-nav-shell">
    <div ref="navWrapRef" class="coal-nav">
      <button type="button" class="coal-nav__brand" @click="navigateAndClose('/coal')">
        <span class="coal-nav__logo" aria-hidden="true">金</span>
        <span class="coal-nav__brand-copy">金正泰智能化选煤厂</span>
      </button>

      <nav class="coal-nav__links" aria-label="管控平台导航">
        <div v-for="item in topNavItems" :key="item.path" class="coal-nav__menu-item">
          <button
            type="button"
            class="coal-nav__button"
            :class="{ active: isTopActive(item) }"
            @click="toggleTopMenu(item.path)"
          >
            <span class="coal-nav__icon" aria-hidden="true">{{ iconFor(item.path) }}</span>
            <span>{{ item.label }}</span>
          </button>

          <div v-if="openTopMenuPath === item.path && item.children.length" class="coal-nav__dropdown">
            <button
              v-for="child in item.children"
              :key="child.path"
              type="button"
              class="coal-nav__dropdown-item"
              :class="{ active: route.path === child.path }"
              @click="navigateAndClose(child.path)"
            >
              <strong>{{ child.label }}</strong>
              <small>{{ child.desc || '进入该功能页面' }}</small>
            </button>
          </div>
        </div>
      </nav>

      <div class="coal-nav__tools">
        <button type="button" class="coal-nav__tool" title="搜索" aria-label="搜索">⌕</button>
        <button type="button" class="coal-nav__tool coal-nav__tool--notice" title="消息通知" aria-label="消息通知">◎</button>
        <button type="button" class="coal-nav__tool" title="系统设置" aria-label="系统设置" @click="navigateAndClose('/coal/settings')">⚙</button>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { CoalNavItem } from '../../views/coal/coalNav'

type TopNavItem = CoalNavItem & { children: CoalNavItem[] }

const route = useRoute()
const router = useRouter()
const navWrapRef = ref<HTMLElement | null>(null)
const openTopMenuPath = ref<string | null>(null)

const topNavItems: TopNavItem[] = [
  {
    label: '首页',
    path: '/coal',
    desc: '平台总入口',
    children: [
      { label: '平台首页', path: '/coal', desc: '平台总入口与功能导航' },
      { label: '综合看板', path: '/coal/dashboard', desc: '生产、设备、告警和关键指标总览' },
      { label: '大屏总览', path: '/coal/dashboard-screen', desc: '管控平台大屏展示' },
      { label: '报表中心', path: '/coal/report', desc: '生产、质量、能耗和设备报表' },
    ],
  },
  {
    label: '生产运行',
    path: '/coal/production',
    desc: '生产和调度',
    children: [
      { label: '生产调度', path: '/coal/production', desc: '生产管理与调度管理整合入口' },
      { label: '生产计划', path: '/coal/planning', desc: '二班倒、三班倒和计划统计' },
      { label: '生产运行统计', path: '/coal/production-operation', desc: '产量、完成率和运行评价' },
      { label: '工艺流程', path: '/coal/process-flow', desc: '破碎、洗选、煤泥水和流程状态' },
      { label: '调度日志', path: '/coal/dispatch-log', desc: '启停机、停送电和当班记录' },
      { label: '排班管理', path: '/coal/shift-schedule', desc: '生产班、检修班和值班制度' },
    ],
  },
  {
    label: '设备运维',
    path: '/coal/equipment',
    desc: '设备和检修',
    children: [
      { label: '设备管理', path: '/coal/equipment', desc: '台账、电机电流、变频器电流和故障分析' },
      { label: '设备大屏', path: '/coal/equipment-screen', desc: '设备状态大屏展示' },
      { label: '机电设备', path: '/coal/mechanical', desc: '机电档案、运行数据和闭环处置' },
      { label: '巡检监测', path: '/coal/monitor', desc: '巡检、视频识别和安全联动' },
      { label: '协同管理', path: '/coal/collaboration', desc: '跨部门任务和闭环协同' },
    ],
  },
  {
    label: '质量能耗',
    path: '/coal/quality',
    desc: '煤质和消耗',
    children: [
      { label: '煤质管理', path: '/coal/quality', desc: '煤质分析、趋势和预警' },
      { label: '煤质录入', path: '/coal/quality-entry', desc: '化验数据录入和复核' },
      { label: '质量报表', path: '/coal/quality-report', desc: '日报、周报、月报和质量统计' },
      { label: '能耗管理', path: '/coal/energy', desc: '耗电量录入、水耗和水平衡' },
      { label: '储装销售', path: '/coal/storage', desc: '储煤、库存和销售联动' },
      { label: '销售统计', path: '/coal/sales', desc: '产品、客户和运输统计' },
    ],
  },
  {
    label: '智能优化',
    path: '/coal/decision',
    desc: '模型和决策',
    children: [
      { label: '智能决策', path: '/coal/decision', desc: '生产质量建议和设备故障分析' },
      { label: '建模分析', path: '/coal/model-analysis', desc: '质量预测、趋势和模型分析' },
      { label: '智能密控', path: '/coal/smart-density', desc: '密度预测和分流补水建议' },
      { label: '智能加药', path: '/coal/smart-reagent', desc: '加药频率预测和模型调用' },
    ],
  },
  {
    label: '平台系统',
    path: '/coal/settings',
    desc: '数据和配置',
    children: [
      { label: '系统设置', path: '/coal/settings', desc: '用户、角色、点位和参数' },
      { label: '数据接入', path: '/coal/data-access', desc: '数据源、接口清单和字段映射' },
      { label: '数据集成', path: '/coal/data-integration', desc: 'Kepserver、ETL 和同步任务' },
      { label: '数据治理', path: '/coal/data-governance', desc: '元数据、质量和模型治理' },
      { label: '安全健康', path: '/coal/safety-health', desc: '人员安全、健康指标和风险闭环' },
    ],
  },
]

const navIcons: Record<string, string> = {
  '/coal': '首',
  '/coal/production': '产',
  '/coal/equipment': '设',
  '/coal/quality': '质',
  '/coal/decision': '智',
  '/coal/settings': '系',
}

function iconFor(path: string) {
  return navIcons[path] || '·'
}

function isTopActive(item: TopNavItem) {
  return route.path === item.path || item.children.some((child) => route.path === child.path)
}

function navigateAndClose(path: string) {
  router.push(path)
  openTopMenuPath.value = null
}

function toggleTopMenu(path: string) {
  openTopMenuPath.value = openTopMenuPath.value === path ? null : path
}

function handleDocumentClick(event: MouseEvent) {
  if (!navWrapRef.value) return
  const target = event.target as Node
  if (!navWrapRef.value.contains(target)) openTopMenuPath.value = null
}

onMounted(() => document.addEventListener('click', handleDocumentClick))
onUnmounted(() => document.removeEventListener('click', handleDocumentClick))
</script>

<style scoped>
.coal-nav-shell {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 4000;
  width: 100%;
  padding: 8px 16px;
  background:
    linear-gradient(180deg, rgba(18, 31, 43, 0.96), rgba(15, 26, 37, 0.92));
  border-bottom: 1px solid rgba(170, 220, 255, 0.18);
  backdrop-filter: blur(16px);
  box-shadow: 0 12px 28px rgba(4, 12, 20, 0.22);
}

.coal-nav {
  display: flex;
  align-items: center;
  gap: 30px;
  width: min(100%, 1840px);
  min-height: 64px;
  margin: 0 auto;
}

.coal-nav__brand {
  display: inline-flex;
  align-items: center;
  flex: 0 0 auto;
  gap: 12px;
  min-width: 288px;
  border: 0;
  background: transparent;
  color: #f7fbff;
  cursor: pointer;
}

.coal-nav__logo {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border: 1px solid rgba(116, 209, 255, 0.46);
  border-radius: 8px;
  background: linear-gradient(135deg, rgba(67, 190, 255, 0.42), rgba(43, 213, 166, 0.2));
  color: #e8fbff;
  font-weight: 900;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.16), 0 0 18px rgba(62, 190, 255, 0.16);
}

.coal-nav__brand-copy {
  color: #f7fbff;
  font-size: 20px;
  font-weight: 800;
  white-space: nowrap;
}

.coal-nav__links {
  display: flex;
  flex: 1;
  justify-content: center;
  gap: 24px;
  min-width: 0;
}

.coal-nav__menu-item {
  position: relative;
}

.coal-nav__button {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 9px;
  height: 42px;
  padding: 0 11px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: rgba(232, 242, 251, 0.82);
  font-size: 17px;
  font-weight: 800;
  cursor: pointer;
  transition: background 0.18s ease, border-color 0.18s ease, color 0.18s ease;
}

.coal-nav__button::after {
  position: absolute;
  right: 8px;
  bottom: 2px;
  left: 8px;
  height: 3px;
  border-radius: 999px;
  background: linear-gradient(90deg, #66e0ff, #3ee0b0);
  opacity: 0;
  transform: scaleX(0.45);
  transition: 0.18s ease;
  box-shadow: 0 0 12px rgba(102, 224, 255, 0.58);
  content: '';
}

.coal-nav__button.active,
.coal-nav__button:hover {
  border-color: rgba(114, 220, 255, 0.18);
  background: rgba(114, 220, 255, 0.1);
  color: #ffffff;
}

.coal-nav__button.active::after,
.coal-nav__button:hover::after {
  opacity: 1;
  transform: scaleX(1);
}

.coal-nav__icon {
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

.coal-nav__dropdown {
  position: absolute;
  top: calc(100% + 12px);
  left: 50%;
  z-index: 20;
  display: grid;
  gap: 8px;
  width: 330px;
  max-height: 58vh;
  padding: 12px;
  overflow-y: auto;
  border: 1px solid rgba(143, 196, 238, 0.26);
  border-radius: 10px;
  background:
    linear-gradient(180deg, rgba(42, 63, 82, 0.98), rgba(20, 32, 45, 0.98));
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.38);
  transform: translateX(-50%);
}

.coal-nav__dropdown-item {
  display: grid;
  gap: 4px;
  padding: 12px 14px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.045);
  color: #eef6ff;
  text-align: left;
  cursor: pointer;
}

.coal-nav__dropdown-item strong {
  font-size: 15px;
}

.coal-nav__dropdown-item small {
  color: #b6c7d4;
  line-height: 1.45;
}

.coal-nav__dropdown-item.active,
.coal-nav__dropdown-item:hover {
  border-color: rgba(118, 206, 255, 0.36);
  background: rgba(85, 153, 212, 0.18);
}

.coal-nav__tools {
  display: inline-flex;
  align-items: center;
  flex: 0 0 auto;
  gap: 8px;
}

.coal-nav__tool {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  border: 1px solid rgba(143, 196, 238, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.055);
  color: #eff8ff;
  font-size: 17px;
  cursor: pointer;
}

.coal-nav__tool--notice {
  position: relative;
}

.coal-nav__tool--notice::after {
  position: absolute;
  top: 8px;
  right: 9px;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #28d7a6;
  box-shadow: 0 0 10px rgba(40, 215, 166, 0.8);
  content: '';
}

@media (max-width: 1280px) {
  .coal-nav {
    align-items: flex-start;
    flex-direction: column;
    gap: 10px;
  }

  .coal-nav__links {
    justify-content: flex-start;
    flex-wrap: wrap;
    width: 100%;
  }

  .coal-nav__tools {
    width: 100%;
    justify-content: flex-end;
  }
}

@media (max-width: 760px) {
  .coal-nav-shell {
    position: sticky;
    padding: 8px;
  }

  .coal-nav__brand {
    min-width: 0;
  }

  .coal-nav__brand-copy {
    font-size: 17px;
    white-space: normal;
  }

  .coal-nav__dropdown {
    left: 0;
    width: min(92vw, 360px);
    transform: none;
  }
}
</style>
