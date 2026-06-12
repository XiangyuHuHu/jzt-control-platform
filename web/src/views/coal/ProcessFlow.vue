<template>
  <div class="coal-page section-page process-flow-page">
    <CoalQuickBar
      title="工艺流程专项"
      subtitle="按设备流程图梳理核心生产链路，仅保留带电运行信号点位。"
      :status="quickStatus"
    />

    <section class="page-shell">
      <section class="section-hero">
        <div>
          <p class="section-eyebrow">工艺流程</p>
          <h1>带电运行信号流程图</h1>
          <p class="section-text">设备名称按“洗煤厂设备新.csv”带电点表校正；后台资产台账当前为空，实时点位仍以 IoT 点表接入情况为准。</p>
        </div>
      </section>

      <section class="section-panel filters">
        <el-select v-model="filterStatus" clearable placeholder="运行状态" style="width: 180px">
          <el-option label="运行" value="运行" />
          <el-option label="停止" value="停止" />
          <el-option label="待接入" value="待接入" />
        </el-select>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleRefresh">刷新</el-button>
        <span class="refresh-note">仅保留带电信号，最近更新：{{ lastUpdatedText }}</span>
      </section>

      <section class="stats-grid">
        <article class="stat-card" v-for="item in stats" :key="item.label">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
          <small>{{ item.note }}</small>
        </article>
      </section>

      <div class="viewport-main-grid process-layout">
        <section class="section-panel flow-panel">
          <div class="panel-head">
            <div>
              <h2>核心工艺流程图</h2>
              <p>绿色为实时带电，灰色为停止，蓝色为点位待接入。</p>
            </div>
            <div class="panel-actions">
              <el-button size="small" @click="zoomFlow(0.1)">放大</el-button>
              <el-button size="small" @click="zoomFlow(-0.1)">缩小</el-button>
              <el-button size="small" @click="resetFlowTransform">重置</el-button>
              <el-button size="small" @click="handleExport">导出 CSV</el-button>
              <el-button size="small" type="primary" @click="handlePrint">打印</el-button>
            </div>
          </div>

          <div
            class="flow-map-wrap"
            :class="{ dragging: flowDragging }"
            @wheel.prevent="onFlowWheel"
            @mousedown="onFlowDragStart"
            @mousemove="onFlowDragMove"
            @mouseup="onFlowDragEnd"
            @mouseleave="onFlowDragEnd"
          >
            <svg viewBox="0 0 1500 1080" class="flow-map" role="img" aria-label="带电运行信号流程图">
              <g :transform="flowTransform">
                <defs>
                  <marker id="arrowHeadCoal" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#4ec9ff" />
                  </marker>
                  <marker id="arrowHeadMedium" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#23d890" />
                  </marker>
                  <marker id="arrowHeadWater" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#f6ca54" />
                  </marker>
                  <marker id="arrowHeadWaste" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#d7e2ea" />
                  </marker>
                </defs>

                <g v-for="zone in flowZones" :key="zone.name" class="flow-zone">
                  <rect :x="zone.x" :y="zone.y" :width="zone.width" :height="zone.height" rx="18" />
                </g>

                <g v-for="edge in flowEdges" :key="edge.key">
                  <path
                    class="flow-edge-glow"
                    :class="`flow-edge-glow--${edge.kind}`"
                    :d="edge.path"
                  />
                  <path
                    class="flow-edge"
                    :class="`flow-edge--${edge.kind}`"
                    :d="edge.path"
                    :marker-end="edgeMarker(edge.kind)"
                  />
                  <path
                    class="flow-edge-spark"
                    :class="`flow-edge-spark--${edge.kind}`"
                    :d="edge.path"
                  />
                </g>

                <g v-for="edge in labeledFlowEdges" :key="`${edge.key}-label`" class="flow-edge-label">
                  <rect :x="edge.labelX - 44" :y="edge.labelY - 14" width="88" height="22" rx="11" />
                  <text :x="edge.labelX" :y="edge.labelY">{{ edge.label }}</text>
                </g>

                <g v-for="node in referenceNodes" :key="node.key" class="reference-node">
                  <rect :x="node.x" :y="node.y" width="118" height="62" rx="8" class="reference-hit" />
                  <image :href="node.iconHref" :x="node.x + 29" :y="node.y + 4" width="60" height="30" preserveAspectRatio="xMidYMid meet" class="reference-image" />
                  <text :x="node.x + 59" :y="node.y + 43" text-anchor="middle" class="reference-code">{{ node.code }}</text>
                  <text :x="node.x + 59" :y="node.y + 56" text-anchor="middle" class="reference-name">{{ node.name }}</text>
                </g>

                <g
                  v-for="node in processNodes"
                  :key="node.key"
                  class="flow-node"
                  :class="`flow-node--${node.state}`"
                  @click="focusNode(node.key)"
                >
                  <rect :x="node.x" :y="node.y" width="118" height="74" rx="8" class="node-hit" />
                  <ellipse :cx="node.x + 59" :cy="node.y + 53" rx="42" ry="10" class="node-shadow" />
                  <image :href="node.iconHref" :x="node.x + 22" :y="node.y + 2" width="74" height="40" preserveAspectRatio="xMidYMid meet" class="node-image" />
                  <circle :cx="node.x + 14" :cy="node.y + 12" r="6" class="node-status" />
                  <text :x="node.x + 59" :y="node.y + 50" text-anchor="middle" class="node-code">{{ node.code }}</text>
                  <text :x="node.x + 59" :y="node.y + 65" text-anchor="middle" class="node-name">{{ node.name }}</text>
                </g>
              </g>
            </svg>

            <aside v-if="detailVisible && selectedRow" class="detail-popover">
              <div class="detail-popover-head">
                <div>
                  <span>{{ selectedRow.section }}</span>
                  <strong>{{ selectedRow.nodeName }}</strong>
                </div>
                <button type="button" @click="detailVisible = false">×</button>
              </div>
              <div class="detail-status-row">
                <span>运行状态</span>
                <el-tag :type="statusTagType(selectedRow.status)" effect="dark">{{ selectedRow.status }}</el-tag>
              </div>
              <dl class="detail-grid">
                <dt>信号名称</dt>
                <dd>{{ selectedRow.load }}</dd>
                <dt>点位地址</dt>
                <dd>{{ selectedRow.alarm }}</dd>
                <dt>点位编码</dt>
                <dd>{{ selectedRow.ticketNo }}</dd>
                <dt>采集口径</dt>
                <dd>{{ selectedRow.reviewConclusion }}</dd>
                <dt>更新时间</dt>
                <dd>{{ selectedRow.updateTime }}</dd>
              </dl>
              <p class="detail-note">{{ selectedRow.suggestion }}</p>
            </aside>
          </div>
        </section>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import CoalQuickBar from '../../components/coal/CoalQuickBar.vue'
import { exportRowsToCsv, printRowsAsTable } from '../../utils/report-export'
import type { ProcessFlowDto } from '../../api/coal-business'
import { useIotHub } from '../../composables/useIotHub'
import beltIcon from '../../assets/process/belt.svg'
import centrifugeIcon from '../../assets/process/centrifuge.svg'
import crusherIcon from '../../assets/process/crusher.svg'
import fanIcon from '../../assets/process/fan.svg'
import feederIcon from '../../assets/process/feeder.svg'
import filterPressIcon from '../../assets/process/filter-press.svg'
import magnetIcon from '../../assets/process/magnet.svg'
import pumpIcon from '../../assets/process/pump.svg'
import reagentIcon from '../../assets/process/reagent.svg'
import scraperIcon from '../../assets/process/scraper.svg'
import screenIcon from '../../assets/process/screen.svg'
import tankIcon from '../../assets/process/tank.svg'

type PoweredNodeConfig = {
  key: string
  code: string
  name: string
  section: string
  signalName: string
  tagCode: string
  address: string
  x: number
  y: number
}

type FlowNode = PoweredNodeConfig & {
  state: 'running' | 'stopped' | 'unknown'
  status: '运行' | '停止' | '待接入'
  iconHref: string
}

type FlowEdgeKind = 'coal' | 'medium' | 'water' | 'waste'

type FlowEdge = {
  key: string
  path: string
  kind: FlowEdgeKind
  label?: string
  labelX?: number
  labelY?: number
}

type LabeledFlowEdge = FlowEdge & {
  label: string
  labelX: number
  labelY: number
}

type ReferenceNode = {
  key: string
  code: string
  name: string
  x: number
  y: number
  iconHref: string
}

const filterStatus = ref('')
const selectedRow = ref<ProcessFlowDto | null>(null)
const detailVisible = ref(false)
const lastUpdatedText = ref('--')
let refreshTimer = 0
const iotHub = useIotHub()
const flowScale = ref(1)
const flowOffsetX = ref(0)
const flowOffsetY = ref(0)
const flowDragging = ref(false)
const flowDragStartX = ref(0)
const flowDragStartY = ref(0)
const flowTransform = computed(
  () => `translate(${flowOffsetX.value}, ${flowOffsetY.value}) scale(${flowScale.value})`,
)

const poweredNodeConfigs: PoweredNodeConfig[] = [
  { key: 'prep-belt', code: '121/122/141', name: '转载皮带', section: '原煤准备', signalName: '121.带电 / 122.带电 / 141.带电', tagCode: '121.带电', address: 'DB185,D54.1 / D270.1 / D72.1', x: 45, y: 70 },
  { key: 'feeder', code: '127-132', name: '原煤给煤机', section: '入洗', signalName: '127.带电 / 128.带电 / 129.带电 / 130.带电 / 131.带电 / 132.带电', tagCode: '127.带电', address: 'DB185,D1404.1-D1494.1', x: 185, y: 70 },
  { key: 'raw-belt', code: '301', name: '原煤皮带', section: '入洗', signalName: '301.带电', tagCode: '301.带电', address: '点表 301.带电', x: 325, y: 70 },
  { key: 'mag-separator', code: '302', name: '电磁除铁器', section: '入洗', signalName: '302.带电', tagCode: '302.带电', address: '点表 302.带电', x: 465, y: 70 },
  { key: 'grading-screen', code: '303/304', name: '分级筛', section: '筛分', signalName: '303.带电 / 304.带电', tagCode: '303.带电', address: 'DB185,D738.1 / D720.1', x: 605, y: 70 },
  { key: 'deslime-screen', code: '305/306', name: '脱泥筛', section: '筛分', signalName: '305.带电 / 306.带电', tagCode: '305.带电', address: 'DB185,D1044.1 / D1026.1', x: 745, y: 70 },
  { key: 'shallow-separator', code: '307', name: '浅槽', section: '块煤分选', signalName: '307.带电', tagCode: '307.带电', address: 'DB185,D1008.1', x: 885, y: 70 },
  { key: 'raw-crusher', code: '324a/b', name: '原煤破碎机', section: '破碎', signalName: '324a.带电 / 324b.带电', tagCode: '324a.带电', address: 'DB185,D162.1 / D180.1', x: 605, y: 180 },
  { key: 'cyclone-feed', code: '332', name: '旋流器入料泵', section: '主洗', signalName: '332.带电', tagCode: '332.带电', address: 'DB185,D1620.1', x: 745, y: 180 },

  { key: 'clean-drain', code: '308A/B', name: '精煤脱介筛', section: '精煤', signalName: '308A.带电 / 308B.带电', tagCode: '308A.带电', address: 'DB185,D1206.1 / D1188.1', x: 1030, y: 70 },
  { key: 'clean-centrifuge', code: '309/310', name: '离心机主电机', section: '精煤', signalName: '309.带电 / 310.带电', tagCode: '309.带电', address: 'DB185,D846.1 / D828.1', x: 1170, y: 70 },
  { key: 'clean-crusher', code: '311a/b', name: '精煤破碎机', section: '精煤', signalName: '311a.带电 / 311b.带电', tagCode: '311a.带电', address: 'DB185,D108.1 / D126.1', x: 1310, y: 70 },
  { key: 'mag-tail-pump', code: '316', name: '块煤磁尾泵', section: '介质回收', signalName: '316.带电', tagCode: '316.带电', address: 'DB185,D1602.1', x: 885, y: 180 },
  { key: 'magnetic', code: '317-319', name: '磁选机', section: '介质回收', signalName: '317.带电 / 318.带电 / 319.带电', tagCode: '317.带电', address: 'DB185,D918.1 / D900.1 / D882.1', x: 1030, y: 180 },
  { key: 'clean-scraper', code: '320/321', name: '刮板机', section: '精煤', signalName: '320.带电 / 321.带电', tagCode: '320.带电', address: 'DB185,D936.1 / D954.1', x: 1170, y: 180 },
  { key: 'medium-pump', code: '323A/B', name: '加介泵', section: '介质回收', signalName: '323A.带电 / 323B.带电', tagCode: '323A.带电', address: 'DB185,D1080.1 / D1062.1', x: 1310, y: 180 },
  { key: 'shaft-water', code: '328', name: '轴封水泵', section: '介质回收', signalName: '328.带电', tagCode: '328.带电', address: 'DB185,D2160.1', x: 885, y: 840 },

  { key: 'gangue-drain', code: '312', name: '矸石脱介筛', section: '矸石', signalName: '312.带电', tagCode: '312.带电', address: 'DB185,D1170.1', x: 1030, y: 290 },
  { key: 'gangue-belt', code: '901/911', name: '矸石皮带', section: '矸石输送', signalName: '901.带电 / 911.带电', tagCode: '901.带电', address: 'DB185,D378.1 / D252.1', x: 1170, y: 290 },
  { key: 'gangue-feeder', code: '902/903', name: '矸石给煤机', section: '矸石装车', signalName: '902.带电 / 903.带电', tagCode: '902.带电', address: 'DB185,D1368.1 / D1386.1', x: 1310, y: 290 },
  { key: 'product-belt', code: '701/702', name: '带式输送机', section: '产品输送', signalName: '701.带电 / 702.带电', tagCode: '701.带电', address: 'DB185,D1728.1 / D1710.1', x: 1030, y: 400 },
  { key: 'product-screen', code: '711a/b', name: '分级筛', section: '产品仓', signalName: '711a.带电 / 711b.带电', tagCode: '711a.带电', address: 'DB185,D2394.1 / D2376.1', x: 1170, y: 400 },
  { key: 'bin-scraper', code: '712/713', name: '刮板输送机', section: '产品仓', signalName: '712.带电 / 713.带电', tagCode: '712.带电', address: 'DB185,D1656.1 / D1638.1', x: 1310, y: 400 },
  { key: 'bin-feeder-clean', code: '721-728', name: '给煤机', section: '产品仓', signalName: '721.带电 / 722.带电 / 723.带电 / 724.带电 / 725.带电 / 726.带电 / 727.带电 / 728.带电', tagCode: '721.带电', address: 'DB185,D3618.1-D3744.1', x: 1170, y: 510 },
  { key: 'bin-feeder-mix', code: '729-736', name: '给煤机', section: '产品仓', signalName: '729.带电 / 730.带电 / 731.带电 / 732.带电 / 733.带电 / 734.带电 / 735.带电 / 736.带电', tagCode: '729.带电', address: 'DB185,D3762.1-D3888.1', x: 1310, y: 510 },

  { key: 'stack-screen', code: '334', name: '高频叠层筛', section: '煤泥水', signalName: '334.带电', tagCode: '334.带电', address: 'DB185,D1890.1', x: 605, y: 400 },
  { key: 'slime-centrifuge', code: '336', name: '离心机主电机', section: '煤泥水', signalName: '336.带电', tagCode: '336.带电', address: 'DB185,D1944.1', x: 745, y: 400 },
  { key: 'clean-water-pump', code: '338', name: '清水泵', section: '水系统', signalName: '338.带电', tagCode: '338.带电', address: 'DB185,D2556.1', x: 745, y: 840 },
  { key: 'stirrer', code: '341', name: '搅拌电机', section: '煤泥水', signalName: '341.带电', tagCode: '341.带电', address: 'DB185,D1746.1', x: 325, y: 560 },
  { key: 'filter-feed', code: '342/343', name: '压滤机入料泵', section: '煤泥水', signalName: '342.带电 / 343.带电', tagCode: '342.带电', address: 'DB185,D1692.1 / D1674.1', x: 465, y: 560 },
  { key: 'press-water', code: '345', name: '压榨水泵电源', section: '煤泥水', signalName: '345.带电', tagCode: '345.带电', address: 'DB185,D2340.1', x: 605, y: 560 },
  { key: 'filter-press', code: '347/348', name: '中高压压滤机', section: '煤泥水', signalName: '347.带电 / 348.带电', tagCode: '347.带电', address: 'DB185,D1782.1 / D1764.1', x: 745, y: 560 },
  { key: 'slime-scraper', code: '349-351', name: '煤泥刮板输送机', section: '煤泥水', signalName: '349.带电 / 350.带电 / 351.带电', tagCode: '349.带电', address: 'DB185,D1836.1 / D1818.1 / D1800.1', x: 885, y: 560 },

  { key: 'slime-crusher', code: '352', name: '煤泥破碎机', section: '煤泥水', signalName: '352.带电', tagCode: '352.带电', address: 'DB185,D2016.1', x: 325, y: 700 },
  { key: 'slime-belt', code: '353', name: '煤泥转载皮带', section: '煤泥水', signalName: '353.带电', tagCode: '353.带电', address: 'DB185,D2142.1', x: 465, y: 700 },
  { key: 'reagent', code: '371/372', name: '加药装置', section: '加药', signalName: '371.带电 / 372.带电', tagCode: '371.带电', address: 'DB185,D2070.1 / D2052.1', x: 605, y: 700 },
  { key: 'thickener', code: '401-403', name: '浓缩机/底流泵', section: '煤泥水', signalName: '401.带电 / 402.带电 / 403.带电', tagCode: '401.带电', address: 'DB185,D2196.1 / D2250.1 / D2232.1', x: 325, y: 840 },
  { key: 'nsj-run', code: 'NSJ', name: '浓缩机启停', section: '浓缩机', signalName: '启停', tagCode: 'coal.kep.smart200.1ff1a0091f0f65a5', address: 'SMART200.NSJ.管控平台数据接口浓缩机.启停', x: 185, y: 840 },
  { key: 'nsj-rake-up', code: 'NSJ', name: '浓缩机提粑', section: '浓缩机', signalName: '提粑', tagCode: 'coal.kep.smart200.cb640af192198087', address: 'SMART200.NSJ.管控平台数据接口浓缩机.提粑', x: 45, y: 840 },
  { key: 'nsj-rake-down', code: 'NSJ', name: '浓缩机降粑', section: '浓缩机', signalName: '降粑', tagCode: 'coal.kep.smart200.c3295f1797bc0c39', address: 'SMART200.NSJ.管控平台数据接口浓缩机.降粑', x: 45, y: 950 },
  { key: 'nsj-limit-high', code: 'NSJ', name: '浓缩机上限位', section: '浓缩机', signalName: '上限位', tagCode: 'coal.kep.smart200.42b4f48c9539995d', address: 'SMART200.NSJ.管控平台数据接口浓缩机.上限位', x: 185, y: 950 },
  { key: 'nsj-limit-low', code: 'NSJ', name: '浓缩机下限位', section: '浓缩机', signalName: '下限位', tagCode: 'coal.kep.smart200.8c269c94cbf49472', address: 'SMART200.NSJ.管控平台数据接口浓缩机.下限位', x: 325, y: 950 },
  { key: 'circulation-water', code: '404/405', name: '循环/冲洗水泵', section: '水系统', signalName: '404.带电 / 405.带电', tagCode: '404.带电', address: 'DB185,D18.1 / D2268.1', x: 605, y: 840 },
  { key: 'filter-drain-seal', code: '354/356', name: '压滤排污/轴封水泵', section: '煤泥水', signalName: '354.带电 / 356.带电', tagCode: '354.带电', address: 'DB185,D2088.1 / D2214.1', x: 745, y: 700 },
  { key: 'air-blower', code: '361/363', name: '低压/高压风机', section: '空压吹风', signalName: '361.带电 / 363A.带电 / 363B.带电', tagCode: '361.带电', address: 'DB185,D1584.1 / D1566.1 / D1548.1', x: 885, y: 700 },
]

const flowEdges: FlowEdge[] = [
  { key: 'raw-ref-1', kind: 'coal', path: 'M163 39 H185' },
  { key: 'raw-ref-2', kind: 'coal', path: 'M303 39 H325' },
  { key: 'raw-ref-3', kind: 'coal', path: 'M443 39 H465' },
  { key: 'raw-ref-to-main', kind: 'coal', path: 'M524 70 V107 H45' },
  { key: 'raw-1', kind: 'coal', path: 'M163 107 H185' },
  { key: 'raw-2', kind: 'coal', path: 'M303 107 H325' },
  { key: 'raw-3', kind: 'coal', path: 'M443 107 H465' },
  { key: 'raw-4', kind: 'coal', path: 'M583 107 H605' },
  { key: 'raw-5', kind: 'coal', path: 'M723 107 H745' },
  { key: 'raw-6', kind: 'coal', path: 'M863 107 H885' },
  { key: 'block-to-clean', kind: 'coal', path: 'M1003 107 H1030', label: '块精煤', labelX: 1018, labelY: 82 },
  { key: 'block-clean-1', kind: 'coal', path: 'M1148 107 H1170' },
  { key: 'block-clean-2', kind: 'coal', path: 'M1288 107 H1310' },
  { key: 'fine-drop', kind: 'coal', path: 'M664 144 V180', label: '末煤', labelX: 690, labelY: 158 },
  { key: 'fine-main-1', kind: 'coal', path: 'M723 217 H745' },
  { key: 'fine-main-2', kind: 'coal', path: 'M863 217 H885' },
  { key: 'medium-1', kind: 'medium', path: 'M1003 217 H1030' },
  { key: 'medium-2', kind: 'medium', path: 'M1148 217 H1170' },
  { key: 'medium-3', kind: 'medium', path: 'M1288 217 H1310', label: 'H/X/C介质', labelX: 1280, labelY: 205 },
  { key: 'block-waste', kind: 'waste', path: 'M944 144 V275 H1030', label: '中煤/矸石', labelX: 990, labelY: 270 },
  { key: 'fine-waste', kind: 'waste', path: 'M804 254 V325 H1030', label: '矸石仓', labelX: 945, labelY: 326 },
  { key: 'gangue-1', kind: 'waste', path: 'M1148 327 H1170' },
  { key: 'gangue-2', kind: 'waste', path: 'M1288 327 H1310' },
  { key: 'fine-product-1', kind: 'coal', path: 'M804 254 V437 H1030', label: '末精煤', labelX: 940, labelY: 430 },
  { key: 'product-1', kind: 'coal', path: 'M1148 437 H1170' },
  { key: 'product-2', kind: 'coal', path: 'M1288 437 H1310' },
  { key: 'bin-clean', kind: 'coal', path: 'M1229 474 V510' },
  { key: 'bin-mix', kind: 'coal', path: 'M1369 474 V510' },
  { key: 'clean-feeder-to-bin', kind: 'coal', path: 'M1229 584 V620' },
  { key: 'mix-feeder-to-bin', kind: 'coal', path: 'M1369 584 V620' },
  { key: 'bin-to-scale-clean', kind: 'coal', path: 'M1229 682 V745' },
  { key: 'bin-to-scale-mix', kind: 'coal', path: 'M1369 682 V745 H1299' },
  { key: 'screen-underflow', kind: 'water', path: 'M804 144 V400 H605', label: '筛下水', labelX: 690, labelY: 394 },
  { key: 'cyclone-to-classifier', kind: 'water', path: 'M804 254 V295' },
  { key: 'classifier-to-stack', kind: 'water', path: 'M804 357 V400 H723' },
  { key: 'coarse-clean-to-centrifuge', kind: 'coal', path: 'M723 437 H745', label: '粗煤泥精煤', labelX: 720, labelY: 420 },
  { key: 'slime-to-stirrer', kind: 'water', path: 'M664 474 V520 H384 V560', label: 'M煤泥水', labelX: 500, labelY: 512 },
  { key: 'slime-2', kind: 'water', path: 'M443 597 H465' },
  { key: 'slime-3', kind: 'water', path: 'M583 597 H605' },
  { key: 'slime-4', kind: 'water', path: 'M723 597 H745' },
  { key: 'tailing-oversize', kind: 'waste', path: 'M863 597 H885' },
  { key: 'slime-crush', kind: 'coal', path: 'M384 634 V700' },
  { key: 'slime-belt', kind: 'coal', path: 'M443 737 H465' },
  { key: 'reagent-to-thickener', kind: 'medium', path: 'M664 737 V805 H384 V840' },
  { key: 'tailing-underflow-to-thickener', kind: 'water', path: 'M944 597 V800 H384 V840' },
  { key: 'thickener-underflow-to-filter', kind: 'water', path: 'M384 840 V800 H804 V634' },
  { key: 'thickener-overflow', kind: 'water', path: 'M443 877 H605', label: '回水', labelX: 520, labelY: 865 },
  { key: 'filter-filtrate', kind: 'water', path: 'M804 700 V805 H664 V840' },
  { key: 'water-return-screen', kind: 'water', path: 'M664 877 V1010 H804 V144', label: '循环水供水', labelX: 760, labelY: 1000 },
  { key: 'water-return-medium', kind: 'water', path: 'M664 877 H1369 V254' },
  { key: 'water-pump-1', kind: 'water', path: 'M723 877 H745' },
  { key: 'water-pump-2', kind: 'water', path: 'M863 877 H885' },
]

const labeledFlowEdges = computed<LabeledFlowEdge[]>(() =>
  flowEdges.filter((edge): edge is LabeledFlowEdge => Boolean(edge.label && edge.labelX && edge.labelY)),
)

const referenceNodes: ReferenceNode[] = [
  { key: 'raw-pre-crush', code: '101/102', name: '原煤破碎', x: 45, y: 8, iconHref: crusherIcon },
  { key: 'raw-dust', code: '103', name: '破碎除尘', x: 185, y: 8, iconHref: fanIcon },
  { key: 'raw-pipe-belt', code: '105/111', name: '管带机', x: 325, y: 8, iconHref: beltIcon },
  { key: 'raw-buffer-bin', code: '127仓', name: '原煤缓冲仓', x: 465, y: 8, iconHref: tankIcon },
  { key: 'classifying-cyclone', code: '333', name: '分级旋流器', x: 745, y: 295, iconHref: tankIcon },
  { key: 'clean-bin', code: '块/精煤仓', name: '产品储存', x: 1170, y: 620, iconHref: tankIcon },
  { key: 'mix-bin', code: '混煤仓', name: '产品储存', x: 1310, y: 620, iconHref: tankIcon },
  { key: 'truck-scale', code: '751-758', name: '仓下汽车衡', x: 1240, y: 745, iconHref: beltIcon },
]

const flowZones = [
  { name: '01 / RAW COAL PREPARATION', x: 24, y: 22, width: 990, height: 170 },
  { name: '02 / COAL SEPARATION CENTER', x: 585, y: 165, width: 865, height: 390 },
  { name: '03 / WATER AND SLURRY RECOVERY', x: 300, y: 525, width: 1080, height: 435 },
]

const edgeMarker = (kind: FlowEdgeKind) => {
  if (kind === 'medium') return 'url(#arrowHeadMedium)'
  if (kind === 'water') return 'url(#arrowHeadWater)'
  if (kind === 'waste') return 'url(#arrowHeadWaste)'
  return 'url(#arrowHeadCoal)'
}

const readLiveStatus = (tagCode: string): 'running' | 'stopped' | 'unknown' => {
  const live = iotHub.getTagValue(tagCode)
  if (!live || live.value === undefined || live.value === null) return 'unknown'
  if (typeof live.value === 'boolean') return live.value ? 'running' : 'stopped'
  if (typeof live.value === 'number') return live.value > 0 ? 'running' : 'stopped'
  return String(live.valueText || live.value).includes('1') || String(live.valueText || live.value).includes('true')
    ? 'running'
    : 'stopped'
}

const statusText = (state: FlowNode['state']): FlowNode['status'] => {
  if (state === 'running') return '运行'
  if (state === 'stopped') return '停止'
  return '待接入'
}

const iconForNode = (node: PoweredNodeConfig) => {
  const text = `${node.code}${node.name}${node.section}`
  if (text.includes('皮带') || text.includes('输送')) return beltIcon
  if (text.includes('给煤机')) return feederIcon
  if (text.includes('筛')) return screenIcon
  if (text.includes('破碎')) return crusherIcon
  if (text.includes('磁选') || text.includes('除铁')) return magnetIcon
  if (text.includes('离心')) return centrifugeIcon
  if (text.includes('压滤机')) return filterPressIcon
  if (text.includes('泵')) return pumpIcon
  if (text.includes('加药')) return reagentIcon
  if (text.includes('刮板')) return scraperIcon
  if (text.includes('风机') || text.includes('吹风')) return fanIcon
  if (text.includes('浓缩') || text.includes('桶')) return tankIcon
  return screenIcon
}

const processNodes = computed<FlowNode[]>(() =>
  poweredNodeConfigs.map((node) => {
    const state = readLiveStatus(node.tagCode)
    return {
      ...node,
      state,
      status: statusText(state),
      iconHref: iconForNode(node),
    }
  }),
)

const rows = computed<ProcessFlowDto[]>(() => {
  const mapped = processNodes.value
    .filter((node) => !filterStatus.value || node.status === filterStatus.value)
    .map((node) => ({
      nodeName: `${node.code} ${node.name}`,
      section: node.section,
      status: node.status,
      load: node.signalName,
      alarm: node.address,
      suggestion: `来自设备点表的 ${node.signalName} 布尔带电信号`,
      ticketNo: node.tagCode,
      deadline: '',
      closureStatus: node.status,
      reviewConclusion: '只保留带电运行信号，非运行相关测点已剔除',
      updateTime: lastUpdatedText.value,
    }))
  return mapped
})

const stats = computed(() => [
  { label: '带电点位', value: `${processNodes.value.length} 个`, note: '核心流程设备' },
  { label: '运行', value: `${processNodes.value.filter((item) => item.status === '运行').length} 个`, note: '实时值为 1/true' },
  { label: '停止', value: `${processNodes.value.filter((item) => item.status === '停止').length} 个`, note: '实时值为 0/false' },
  { label: '待接入', value: `${processNodes.value.filter((item) => item.status === '待接入').length} 个`, note: '暂无实时快照' },
])

const quickStatus = computed(() => {
  const unknown = processNodes.value.filter((node) => node.status === '待接入').length
  const stopped = processNodes.value.filter((node) => node.status === '停止').length
  if (stopped) return { text: `停止 ${stopped} 个`, type: 'stopped' as const }
  if (unknown) return { text: `待接入 ${unknown} 个`, type: 'idle' as const }
  return { text: '流程运行中', type: 'running' as const }
})

const exportColumns: Array<{ key: keyof ProcessFlowDto; label: string }> = [
  { key: 'nodeName', label: '设备节点' },
  { key: 'section', label: '工艺段' },
  { key: 'status', label: '运行状态' },
  { key: 'load', label: '信号名称' },
  { key: 'alarm', label: '点位地址' },
  { key: 'suggestion', label: '点位说明' },
  { key: 'ticketNo', label: '点位编码' },
  { key: 'reviewConclusion', label: '采集口径' },
  { key: 'updateTime', label: '更新时间' },
]

async function refreshFlow(showToast = false) {
  await iotHub.ensureFresh('process-flow', 0)
  lastUpdatedText.value = new Date().toLocaleString('zh-CN', { hour12: false })
  if (showToast) ElMessage.success('带电运行信号已刷新')
}

const handleExport = () => {
  exportRowsToCsv(rows.value as unknown as Record<string, unknown>[], exportColumns, `带电运行信号流程_${new Date().toISOString().slice(0, 10)}`)
  ElMessage.success('带电运行信号 CSV 已下载')
}

const handleQuery = () => {
  ElMessage.success('筛选已应用')
}

const handleRefresh = () => refreshFlow(true)

const handlePrint = () => {
  const ok = printRowsAsTable('带电运行信号清单', rows.value as unknown as Record<string, unknown>[], exportColumns, {
    subtitle: '金正泰智能化选煤厂工艺流程专项报表',
    meta: [
      { label: '筛选状态', value: filterStatus.value || '全部' },
      { label: '记录条数', value: `${rows.value.length}` },
    ],
    preparedBy: '工艺员',
    reviewedBy: '生产技术科',
    approvedBy: '生产调度',
  })
  if (!ok) {
    ElMessage.warning('浏览器拦截了打印窗口，请允许弹窗后重试')
    return
  }
  ElMessage.success('已打开打印预览')
}

const statusTagType = (status: string) => {
  if (status === '停止') return 'info'
  if (status === '待接入') return 'warning'
  return 'success'
}

const openDetail = (row: ProcessFlowDto) => {
  selectedRow.value = row
  detailVisible.value = true
}

const focusNode = (key: string) => {
  const matched = rows.value.find((row) => row.ticketNo === poweredNodeConfigs.find((item) => item.key === key)?.tagCode)
  if (matched) openDetail(matched)
}

const onFlowWheel = (event: WheelEvent) => {
  zoomFlow(event.deltaY < 0 ? 0.08 : -0.08)
}

const zoomFlow = (delta: number) => {
  flowScale.value = Math.min(2.2, Math.max(0.65, Number((flowScale.value + delta).toFixed(2))))
}

const resetFlowTransform = () => {
  flowScale.value = 1
  flowOffsetX.value = 0
  flowOffsetY.value = 0
}

const onFlowDragStart = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (target.closest('.panel-actions')) return
  flowDragging.value = true
  flowDragStartX.value = event.clientX
  flowDragStartY.value = event.clientY
}

const onFlowDragMove = (event: MouseEvent) => {
  if (!flowDragging.value) return
  flowOffsetX.value += event.clientX - flowDragStartX.value
  flowOffsetY.value += event.clientY - flowDragStartY.value
  flowDragStartX.value = event.clientX
  flowDragStartY.value = event.clientY
}

const onFlowDragEnd = () => {
  flowDragging.value = false
}

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'process-flow', intervalMs: 5000 })
  await refreshFlow()
  refreshTimer = window.setInterval(() => refreshFlow(), 30000)
})

onUnmounted(() => {
  clearInterval(refreshTimer)
})
</script>

<style scoped>
.section-page{height:100%;overflow:hidden;padding:0;background:#091019;color:#eef6ff}
.page-shell{width:min(100%,1680px);margin:0 auto;height:100%;display:flex;flex-direction:column;gap:8px;min-height:0}
.section-hero{display:flex;justify-content:space-between;gap:16px;align-items:flex-start}
.section-eyebrow{margin:0 0 10px;color:#72d8ff;font-size:12px;letter-spacing:.2em;text-transform:uppercase}
.section-hero h1{margin:0;font-size:22px}
.section-text{max-width:820px;margin:8px 0 0;color:#96aabc;line-height:1.5;font-size:12px}
.section-panel{padding:12px 14px;border-radius:14px;border:1px solid rgba(122,190,255,.12);background:rgba(12,20,31,.92);box-shadow:0 12px 28px rgba(0,0,0,.16)}
.filters{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
.refresh-note{color:#8fb0c8;font-size:11px}
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;flex:0 0 auto;margin:0}
.stat-card{padding:8px 12px;border-radius:12px;border:1px solid rgba(122,190,255,.12);background:rgba(12,20,31,.92)}
.stat-card span{display:block;color:#97aabc;font-size:12px}
.stat-card strong{display:block;margin-top:4px;font-size:21px}
.stat-card small{display:block;margin-top:3px;color:#6ec8ff;font-size:11px}
.process-layout{grid-template-columns:minmax(0,1fr);grid-template-rows:minmax(0,1fr);flex:1 1 auto;min-height:0;margin:0}
.flow-panel{grid-row:1;min-height:0}
.list-panel{display:none}
.panel-head{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:8px}
.panel-actions{display:flex;gap:6px;align-items:center}
.panel-head h2{margin:0;font-size:15px}
.panel-head p{margin:4px 0 0;color:#8fa8bc;font-size:11px}
.chart-box{height:100%;min-height:120px}
.flow-map-wrap{position:relative;min-height:0;height:calc(100% - 42px);overflow:hidden;border-radius:12px;cursor:grab;background:radial-gradient(circle at 50% 45%,rgba(0,242,254,.18),transparent 36%),radial-gradient(circle at 72% 18%,rgba(0,255,204,.1),transparent 28%),linear-gradient(135deg,rgba(4,12,27,.96),rgba(7,24,45,.92) 50%,rgba(4,12,27,.96))}
.flow-map-wrap::before{content:"";position:absolute;inset:0;background-image:linear-gradient(rgba(68,181,255,.05) 1px,transparent 1px),linear-gradient(90deg,rgba(68,181,255,.05) 1px,transparent 1px);background-size:28px 28px;mask-image:radial-gradient(circle at 50% 45%,#000 0%,transparent 78%);pointer-events:none}
.flow-map-wrap::after{content:"";position:absolute;inset:1px;border-radius:11px;border:1px solid rgba(0,242,254,.18);box-shadow:inset 0 0 28px rgba(0,242,254,.1);pointer-events:none}
.flow-map-wrap.dragging{cursor:grabbing}
.flow-map{width:100%;height:100%;min-height:0}
.flow-zone rect{fill:rgba(16,24,48,.36);stroke:rgba(0,242,254,.24);stroke-width:1;filter:drop-shadow(0 0 14px rgba(0,242,254,.08));backdrop-filter:blur(6px)}
.flow-zone text{fill:rgba(166,232,255,.5);font-size:15px;font-weight:900;letter-spacing:.12em}
.flow-edge-glow{fill:none;stroke-width:9;stroke-linecap:square;stroke-linejoin:miter;opacity:.16;filter:blur(2px)}
.flow-edge-glow--coal{stroke:#00f2fe}
.flow-edge-glow--medium{stroke:#23d890}
.flow-edge-glow--water{stroke:#00ffcc}
.flow-edge-glow--waste{stroke:#ff9900}
.flow-edge{fill:none;stroke-width:3;stroke-linecap:square;stroke-linejoin:miter;opacity:.9}
.flow-edge--coal{stroke:#00f2fe}
.flow-edge--medium{stroke:#23d890}
.flow-edge--water{stroke:#00ffcc}
.flow-edge--waste{stroke:#ff9900}
.flow-edge-spark{fill:none;stroke-width:3;stroke-linecap:round;stroke-linejoin:miter;stroke-dasharray:3 24;animation:flowPulse 1.15s linear infinite;filter:drop-shadow(0 0 6px currentColor)}
.flow-edge-spark--coal{stroke:#e9fdff;color:#00f2fe}
.flow-edge-spark--medium{stroke:#b8ffe4;color:#23d890}
.flow-edge-spark--water{stroke:#d8fff7;color:#00ffcc}
.flow-edge-spark--waste{stroke:#ffd07a;color:#ff9900}
.flow-edge-label rect{fill:rgba(6,18,30,.72);stroke:rgba(0,242,254,.4);stroke-width:1;filter:drop-shadow(0 0 8px rgba(0,242,254,.18))}
.flow-edge-label text{fill:#f3fbff;font-size:12px;font-weight:900;text-anchor:middle;dominant-baseline:central}
.data-anchor circle{fill:rgba(20,60,92,.75);stroke:#42d9ff;stroke-width:1.5;filter:drop-shadow(0 0 8px rgba(66,217,255,.72))}
.data-anchor text:first-of-type{fill:#fff;font-size:11px;font-weight:900}
.data-anchor text:last-of-type{fill:#9eeeff;font-size:8px;font-weight:800}
.reference-hit{fill:rgba(12,26,40,.38);stroke:rgba(151,190,210,.38);stroke-width:1;stroke-dasharray:5 4;filter:drop-shadow(0 0 6px rgba(80,180,220,.12))}
.reference-image{opacity:.72;filter:grayscale(.22) brightness(.82) drop-shadow(0 0 5px rgba(120,210,240,.26))}
.reference-code{fill:#dbe8ef;font-size:11px;font-weight:900}
.reference-name{fill:#a8bdc9;font-size:10px;font-weight:800}
.pdf-ref-node rect{fill:rgba(14,24,36,.22);stroke:rgba(155,190,210,.42);stroke-width:1;stroke-dasharray:5 4;filter:drop-shadow(0 0 6px rgba(120,180,220,.12))}
.pdf-ref-code{fill:#c9d7df;font-size:11px;font-weight:900}
.pdf-ref-name{fill:#9fb3c0;font-size:10px;font-weight:800}
.lane-title{fill:#8de8ff;font-size:14px;font-weight:800;letter-spacing:.08em}
.lane-line{stroke:rgba(116,214,255,.16);stroke-width:1}
.flow-node{cursor:pointer}
.node-hit{fill:rgba(20,32,55,.54);stroke:rgba(0,162,255,.42);stroke-width:1;stroke-dasharray:none;filter:drop-shadow(0 0 10px rgba(0,242,254,.12))}
.node-shadow{fill:rgba(0,0,0,.5)}
.node-image{filter:drop-shadow(0 0 8px rgba(47,224,165,.62)) drop-shadow(0 8px 10px rgba(0,0,0,.28))}
.node-status{fill:#4ec9ff;filter:drop-shadow(0 0 8px rgba(78,201,255,.75))}
.flow-node:hover .node-hit{stroke:rgba(0,242,254,.95);filter:drop-shadow(0 0 18px rgba(0,242,254,.34))}
.flow-node:hover .node-image{transform:scale(1.04);transform-box:fill-box;transform-origin:center}
.flow-node--running .node-hit{stroke:rgba(0,255,204,.72);fill:rgba(13,78,67,.34)}
.flow-node--running .node-status{fill:#2fe0a5;filter:drop-shadow(0 0 10px rgba(47,224,165,.85))}
.flow-node--running .node-image{filter:drop-shadow(0 0 11px rgba(47,224,165,.88)) drop-shadow(0 8px 10px rgba(0,0,0,.28))}
.flow-node--stopped .node-hit{stroke:rgba(135,149,168,.58);fill:rgba(31,41,53,.38)}
.flow-node--stopped .node-status{fill:#8795a8;filter:none}
.flow-node--stopped .node-image{filter:grayscale(.82) brightness(.65) drop-shadow(0 7px 8px rgba(0,0,0,.24));opacity:.72}
.flow-node--unknown .node-hit{stroke:rgba(0,242,254,.48);fill:rgba(20,54,86,.3)}
.node-code{fill:#f0fbff;font-size:13px;font-weight:900;text-shadow:0 0 6px rgba(58,218,255,.72)}
.node-name{fill:#d9f8ff;font-size:12px;font-weight:800}
.pager-wrap{display:flex;justify-content:flex-end;margin-top:12px}

@keyframes flowPulse{to{stroke-dashoffset:-26}}

:global(body.coal-theme .process-flow-page .page-shell) {
  display: flex !important;
  flex-direction: column !important;
  grid-template-columns: none !important;
  grid-template-rows: none !important;
  gap: 8px !important;
}

:global(body.coal-theme .process-flow-page .page-shell > .stats-grid) {
  display: grid !important;
  flex: 0 0 72px !important;
  max-height: 72px !important;
  grid-template-columns: repeat(4, minmax(0, 1fr)) !important;
  overflow: hidden;
}

:global(body.coal-theme .process-flow-page .stat-card) {
  height: 72px !important;
  overflow: hidden;
  padding: 8px 12px !important;
}

:global(body.coal-theme .process-flow-page .viewport-main-grid) {
  display: grid !important;
  flex: 1 1 auto !important;
  min-height: 0 !important;
  grid-template-columns: minmax(0, 1fr) !important;
  grid-template-rows: minmax(0, 1fr) !important;
  gap: 8px !important;
}

:global(body.coal-theme .process-flow-page .flow-panel) {
  grid-row: 1 / -1 !important;
  grid-column: 1 !important;
}

:global(body.coal-theme .process-flow-page .flow-map) {
  min-height: 0;
}

.detail-popover{position:absolute;right:18px;top:18px;width:360px;max-height:calc(100% - 36px);overflow:auto;padding:14px;border-radius:10px;border:1px solid rgba(0,242,254,.28);background:linear-gradient(180deg,rgba(10,26,42,.96),rgba(7,16,28,.94));box-shadow:0 0 28px rgba(0,242,254,.16),0 18px 44px rgba(0,0,0,.32);z-index:5;color:#eef6ff}
.detail-popover-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;padding-bottom:10px;border-bottom:1px solid rgba(122,190,255,.16)}
.detail-popover-head span{display:block;color:#7ee7ff;font-size:12px;font-weight:800}
.detail-popover-head strong{display:block;margin-top:4px;color:#fff;font-size:16px;line-height:1.35}
.detail-popover-head button{width:26px;height:26px;border:1px solid rgba(122,190,255,.24);border-radius:6px;background:rgba(20,45,68,.72);color:#dff8ff;font-size:18px;line-height:20px;cursor:pointer}
.detail-status-row{display:flex;align-items:center;justify-content:space-between;margin:12px 0;padding:9px 10px;border-radius:8px;background:rgba(16,43,63,.56);color:#9fe8ff;font-size:12px;font-weight:800}
.detail-grid{display:grid;grid-template-columns:76px minmax(0,1fr);gap:8px 10px;margin:0}
.detail-grid dt{color:#72d8ff;font-size:12px;font-weight:800}
.detail-grid dd{margin:0;color:#e9f6ff;font-size:12px;line-height:1.45;word-break:break-all}
.detail-note{margin:12px 0 0;padding:10px;border-radius:8px;background:rgba(4,14,24,.52);color:#b8cad8;font-size:12px;line-height:1.5}

@media (max-width: 1200px){.stats-grid{grid-template-columns:repeat(2,1fr)}.process-layout{grid-template-columns:1fr;grid-template-rows:minmax(0,1fr)}.flow-panel{grid-row:auto}}
@media (max-width: 768px){.stats-grid{grid-template-columns:1fr}}
</style>
