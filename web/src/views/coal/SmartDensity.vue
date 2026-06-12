<template>
  <div class="coal-page section-page smart-density-page smart-density-container">
    <header class="header-bar">
      <div class="title">重介密控流程</div>
      <div class="actions">
        <el-select v-model="selectedUnit" size="small" class="dark-select" style="width: 138px" @change="handleUnitChange">
          <el-option v-for="unit in densityUnits" :key="unit.value" :label="unit.label" :value="unit.value" />
        </el-select>
        <el-button :loading="loading" type="primary" size="small" class="cyan-btn" @click="runPredict">刷新建议</el-button>
      </div>
    </header>

    <div class="main-content density-workbench">
      <section class="flow-chart-panel">
        <div class="canvas-wrapper flow-map-wrap">
          <img :src="processBg" class="process-bg-img" alt="重介密控流程底图" />
          <svg class="process-svg flow-map" viewBox="0 0 980 760" role="img" aria-label="智能密控工艺流程">
            <defs>
              <linearGradient id="sd-waterGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#00bcd4" stop-opacity="0.2" />
                <stop offset="50%" stop-color="#00bcd4" stop-opacity="1" />
                <stop offset="100%" stop-color="#00bcd4" stop-opacity="0.2" />
              </linearGradient>
              <linearGradient id="sd-mediumGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#4ade80" stop-opacity="0.2" />
                <stop offset="50%" stop-color="#4ade80" stop-opacity="1" />
                <stop offset="100%" stop-color="#4ade80" stop-opacity="0.2" />
              </linearGradient>
              <linearGradient id="pipe-raw" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#f8fafc" />
                <stop offset="45%" stop-color="#cbd5e1" />
                <stop offset="100%" stop-color="#64748b" />
              </linearGradient>
              <linearGradient id="pipe-product" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#f6fbff" />
                <stop offset="45%" stop-color="#aebdca" />
                <stop offset="100%" stop-color="#5f6b75" />
              </linearGradient>
              <linearGradient id="pipe-water" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#8cf7ff" />
                <stop offset="45%" stop-color="#20bcd7" />
                <stop offset="100%" stop-color="#0d6072" />
              </linearGradient>
              <linearGradient id="pipe-medium" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#fed7aa" />
                <stop offset="45%" stop-color="#f97316" />
                <stop offset="100%" stop-color="#9a3412" />
              </linearGradient>
              <linearGradient id="pipe-bypass" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#e9d5ff" />
                <stop offset="45%" stop-color="#a855f7" />
                <stop offset="100%" stop-color="#581c87" />
              </linearGradient>
              <linearGradient id="device-steel" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#586674" />
                <stop offset="46%" stop-color="#2d3944" />
                <stop offset="100%" stop-color="#121a24" />
              </linearGradient>
              <linearGradient id="device-tank" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#1f6f6b" />
                <stop offset="52%" stop-color="#164e4b" />
                <stop offset="100%" stop-color="#0f2f35" />
              </linearGradient>
              <marker id="arrow-flow" markerHeight="10" markerUnits="userSpaceOnUse" markerWidth="10" orient="auto" refX="9" refY="5">
                <path d="M0,0 L10,5 L0,10 Z" fill="#22d3ee" />
              </marker>
              <marker id="arrow-medium" markerHeight="10" markerUnits="userSpaceOnUse" markerWidth="10" orient="auto" refX="9" refY="5">
                <path d="M0,0 L10,5 L0,10 Z" fill="#f97316" />
              </marker>
              <marker id="arrow-water" markerHeight="10" markerUnits="userSpaceOnUse" markerWidth="10" orient="auto" refX="9" refY="5">
                <path d="M0,0 L10,5 L0,10 Z" fill="#22d3ee" />
              </marker>
              <marker id="arrow-dense" markerHeight="10" markerUnits="userSpaceOnUse" markerWidth="10" orient="auto" refX="9" refY="5">
                <path d="M0,0 L10,5 L0,10 Z" fill="#4ade80" />
              </marker>
            </defs>

            <g
              v-for="edge in flowEdges"
              :key="edge.key"
              class="overlay-pipe-layer"
              :class="{ 'is-active-flow': edge.animated && pumpFlowActive }"
            >
              <path class="pipe-shadow" :d="edge.path" />
              <path
                class="pipe-body"
                :class="[edge.kind, edge.lineClass, { 'flow-animate': edge.animated && pumpFlowActive }]"
                :d="edge.path"
                :marker-end="edge.marker"
              />
              <path class="pipe-highlight" :class="edge.kind" :d="edge.path" />
              <path
                class="pipe-flow-light-glow"
                :class="edge.kind"
                :style="{ animationDelay: edge.lightDelay }"
                :d="edge.path"
              />
              <path
                class="pipe-flow-light"
                :class="edge.kind"
                :style="{ animationDelay: edge.lightDelay }"
                :d="edge.path"
              />
              <text v-if="edge.label" :x="edge.labelX" :y="edge.labelY" class="flow-label" :class="edge.kind">{{ edge.label }}</text>
            </g>

            <g
              v-for="node in processNodes"
              :key="node.key"
              class="device-node flow-node equipment"
              :class="[
                deviceClass(node.key),
                `device-${node.kind}`,
                { highlight: node.highlight, active: node.key === 'separator', 'has-asset': Boolean(node.asset) },
              ]"
            >
              <image
                v-if="node.asset"
                :href="node.asset"
                :x="node.assetX ?? node.x"
                :y="node.assetY ?? node.y"
                :width="node.assetW ?? node.w"
                :height="node.assetH ?? node.h"
                preserveAspectRatio="xMidYMid meet"
                class="equipment-asset"
              />
              <template v-if="!node.asset && (node.kind === 'screen' || node.kind === 'separator')">
                <polygon :points="screenShellPoints(node)" class="device-shell screen-shell" />
                <g v-if="node.kind === 'separator'" class="separator-detail">
                  <rect :x="node.x + 28" :y="node.y + 24" :width="node.w - 66" height="18" rx="2" class="coal-bed-plate" />
                  <circle
                    v-for="index in coalPebbles"
                    :key="`coal-${index}`"
                    :cx="node.x + 42 + index * 17"
                    :cy="node.y + 31 + (index % 3) * 4"
                    :r="3.8 + (index % 2)"
                    class="coal-pebble"
                  />
                  <line :x1="node.x + 30" :y1="node.y + 18" :x2="node.x + node.w - 48" :y2="node.y + 14" class="guard-rail" />
                  <line :x1="node.x + 32" :y1="node.y + 22" :x2="node.x + node.w - 46" :y2="node.y + 18" class="guard-rail muted" />
                </g>
                <g v-else class="screen-detail">
                  <line :x1="node.x + 34" :y1="node.y + 34" :x2="node.x + node.w - 42" :y2="node.y + 29" class="spray-main" />
                  <circle
                    v-for="index in sprayNozzles"
                    :key="`spray-${node.key}-${index}`"
                    :cx="node.x + 42 + index * ((node.w - 88) / (sprayNozzles.length - 1))"
                    :cy="node.y + 34 - index * 0.8"
                    r="2.5"
                    class="spray-nozzle"
                  />
                  <line
                    v-for="index in sprayNozzles"
                    :key="`spray-line-${node.key}-${index}`"
                    :x1="node.x + 42 + index * ((node.w - 88) / (sprayNozzles.length - 1))"
                    :y1="node.y + 39"
                    :x2="node.x + 38 + index * ((node.w - 88) / (sprayNozzles.length - 1))"
                    :y2="node.y + 49"
                    class="spray-fall"
                  />
                </g>
                <line :x1="node.x + 24" :y1="node.y + node.h * 0.56" :x2="node.x + node.w - 22" :y2="node.y + node.h * 0.56" class="device-deck" />
                <line :x1="node.x + 30" :y1="node.y + node.h * 0.72" :x2="node.x + node.w - 26" :y2="node.y + node.h * 0.72" class="device-deck muted" />
                <line :x1="node.x + 28" :y1="node.y + node.h - 20" :x2="node.x + 18" :y2="node.y + node.h + 8" class="device-leg" />
                <line :x1="node.x + node.w - 44" :y1="node.y + node.h - 24" :x2="node.x + node.w - 26" :y2="node.y + node.h + 8" class="device-leg" />
              </template>
              <template v-else-if="!node.asset && (node.kind === 'magnet' || node.kind === 'centrifuge')">
                <rect :x="node.x + 14" :y="node.y + node.h - 20" :width="node.w - 28" height="14" rx="3" class="device-base" />
                <rect :x="node.x + 18" :y="node.y + 32" :width="node.w - 36" :height="node.h - 54" rx="10" class="device-shell magnet-body" />
                <ellipse :cx="node.x + 30" :cy="node.y + node.h / 2 + 5" :rx="16" :ry="node.h / 2 - 24" class="device-cylinder-end" />
                <ellipse :cx="node.x + node.w - 30" :cy="node.y + node.h / 2 + 5" :rx="16" :ry="node.h / 2 - 24" class="device-cylinder-end" />
                <line
                  v-for="index in cylinderRibs"
                  :key="`rib-${node.key}-${index}`"
                  :x1="node.x + 48 + index * ((node.w - 96) / Math.max(1, cylinderRibs.length - 1))"
                  :y1="node.y + 36"
                  :x2="node.x + 48 + index * ((node.w - 96) / Math.max(1, cylinderRibs.length - 1))"
                  :y2="node.y + node.h - 26"
                  class="cylinder-rib"
                />
                <rect :x="node.x + node.w * 0.42" :y="node.y + 14" :width="node.w * 0.22" :height="18" rx="3" class="device-motor" />
              </template>
              <template v-else-if="!node.asset && node.kind === 'pump'">
                <rect :x="node.x + 4" :y="node.y + node.h - 13" :width="node.w - 8" height="8" rx="2" class="device-base" />
                <rect :x="node.x + 8" :y="node.y + 30" :width="node.w - 16" :height="node.h - 38" rx="7" class="device-shell pump-body" />
                <rect :x="node.x + node.w * 0.56" :y="node.y + 22" :width="node.w * 0.25" :height="16" rx="3" class="device-motor" />
                <circle :cx="node.x + node.w / 2" :cy="node.y + node.h / 2 + 7" :r="Math.min(node.w, node.h) * 0.22" class="device-impeller" />
                <circle :cx="node.x + 11" :cy="node.y + node.h / 2 + 7" r="4" class="pump-flange" />
                <circle :cx="node.x + node.w - 11" :cy="node.y + node.h / 2 + 7" r="4" class="pump-flange" />
              </template>
              <template v-else-if="!node.asset && node.kind === 'tank'">
                <polygon :points="tankShellPoints(node)" class="device-shell tank-shell" />
                <ellipse :cx="node.x + node.w / 2" :cy="node.y + 23" :rx="node.w / 2 - 18" ry="12" class="tank-rim" />
                <ellipse :cx="node.x + node.w / 2" :cy="node.y + 33" :rx="node.w / 2 - 28" ry="9" class="tank-water" />
                <rect :x="node.x + node.w / 2 - 8" :y="node.y + 10" width="16" height="22" rx="4" class="device-motor" />
                <line :x1="node.x + 24" :y1="node.y + node.h * 0.42" :x2="node.x + node.w - 24" :y2="node.y + node.h * 0.42" class="device-deck" />
              </template>
              <template v-if="node.highlight && !node.asset">
                <polygon
                  :points="trapezoidPoints(node)"
                  class="node-hit node-trapezoid"
                />
              </template>
              <template v-else>
                <rect :x="node.x" :y="node.y" :width="node.w" :height="node.h" rx="6" class="node-hit" />
              </template>
              <ellipse
                v-if="!node.asset"
                :cx="node.x + node.w / 2"
                :cy="node.y + node.h - 6"
                :rx="node.w / 2 - 14"
                ry="8"
                class="node-shadow"
              />
              <image
                v-if="!node.asset"
                :href="node.icon"
                :x="node.x + (node.w - 74) / 2"
                :y="node.y + 4"
                width="74"
                height="40"
                preserveAspectRatio="xMidYMid meet"
                class="node-image"
              />
              <circle :cx="nodeStatusPoint(node).x" :cy="nodeStatusPoint(node).y" r="4" class="node-status" />
              <text :x="nodeLabelAnchor(node).centerX" :y="nodeLabelAnchor(node).codeY" class="node-id device-title">{{ node.code }}</text>
              <text
                :x="nodeLabelAnchor(node).centerX"
                :y="nodeLabelAnchor(node).nameY"
                class="node-name device-name"
                :class="{ big: node.highlight || node.asset }"
              >
                {{ node.name }}
              </text>
              <text v-if="node.subName" :x="nodeLabelAnchor(node).centerX" :y="nodeLabelAnchor(node).subY" class="node-value plc-label">{{ node.subName }}</text>
              <text v-if="node.plcLabel" :x="nodeLabelAnchor(node).centerX" :y="nodeLabelAnchor(node).plcY" class="plc-label">{{ node.plcLabel }}</text>
            </g>

            <g class="equipment control-device valve-node" :class="deviceClass('diverterValve')">
              <circle :cx="controlPoints.diverter.x" :cy="controlPoints.diverter.y" r="18" class="valve-ring" />
              <text :x="controlPoints.diverter.x" :y="controlPoints.diverter.y + 4" class="valve-icon">×</text>
              <text :x="controlPoints.diverter.x" :y="controlPoints.diverter.y + 57" class="device-title">分流阀</text>
              <text :x="controlPoints.diverter.x" :y="controlPoints.diverter.y + 80" class="plc-label">PLC {{ diverterFeedback.toFixed(0) }}%</text>
              <text :x="controlPoints.diverter.x" :y="controlPoints.diverter.y + 103" class="advice-label">建议 {{ guidance.diverter }}%</text>
            </g>

            <g class="equipment control-device valve-node" :class="deviceClass('waterValve')">
              <circle :cx="controlPoints.water.x" :cy="controlPoints.water.y" r="18" class="valve-ring" />
              <text :x="controlPoints.water.x" :y="controlPoints.water.y + 4" class="valve-icon">×</text>
              <text :x="controlPoints.water.x" :y="controlPoints.water.y - 48" class="device-title">补水阀</text>
              <text :x="controlPoints.water.x" :y="controlPoints.water.y + 38" class="plc-label">PLC {{ waterFeedback.toFixed(0) }}%</text>
            </g>

            <g class="equipment control-device" :class="[deviceClass('mediumPump'), { 'pump-active': pumpFlowActive }]">
              <circle :cx="controlPoints.pump.x" :cy="controlPoints.pump.y" r="30" class="pump-ring" />
              <path :d="pumpIconPath" />
              <text :x="controlPoints.pump.x" :y="controlPoints.pump.y - 47" class="device-title">加介泵</text>
              <text :x="controlPoints.pump.x" :y="controlPoints.pump.y + 48" class="plc-label" :class="{ 'animated-flash': pumpFlowActive }">{{ pumpStatusText }}</text>
              <text :x="controlPoints.pump.x" :y="controlPoints.pump.y + 71" class="advice-label">{{ guidance.pump }}</text>
            </g>

            <g class="flow-meter">
              <rect x="174" y="470" width="100" height="44" rx="5" />
              <text x="184" y="490">RPM</text>
              <text x="184" y="508">Speed 0%</text>
            </g>

            <g class="flow-meter density-meter">
              <rect x="650" y="545" width="104" height="44" rx="5" />
              <text x="660" y="565">D {{ actualDensity.toFixed(3) }}</text>
              <text x="660" y="583">Δ {{ densityDiffText }}</text>
            </g>
          </svg>

          <div class="theory-board">
            <p>理论分选密度: <span>{{ targetDensity.toFixed(3) }} g/cm³</span></p>
            <p>稳定区间: {{ stableRangeText }} g/cm³</p>
          </div>

          <div class="pipe-legend-panel">
            <div><i class="line product"></i><span>主物料流</span></div>
            <div><i class="line dense"></i><span>合格介质 / 磁选精矿</span></div>
            <div><i class="line medium"></i><span>稀介 / 尾水</span></div>
            <div><i class="line water"></i><span>补水 / 喷水</span></div>
            <div><i class="line bypass"></i><span>加介系统</span></div>
          </div>
        </div>

        <div class="bottom-legend">
          <span class="legend-item"><i class="dot run"></i>运行</span>
          <span class="legend-item"><i class="dot idle"></i>停车</span>
          <span class="legend-item"><i class="dot standby"></i>带电待机</span>
          <span class="legend-item"><i class="dot fault"></i>故障</span>
          <span class="legend-item"><i class="dot manual"></i>就地位</span>
        </div>
      </section>

      <aside class="data-sidebar guidance-panel">
        <div class="card-panel guidance-card">
          <div class="card-title">指导意见</div>

          <div class="kpi-grid">
            <div class="kpi-item">
              <div class="label">目标密度</div>
              <div class="value">{{ targetDensity.toFixed(3) }}</div>
              <div class="sub">煤质计算表</div>
            </div>
            <div class="kpi-item">
              <div class="label">实际密度</div>
              <div class="value text-cyan">{{ actualDensity.toFixed(3) }}</div>
              <div class="sub">PLC 采集</div>
            </div>
            <div class="kpi-item">
              <div class="label">密度偏差</div>
              <div class="value" :class="densityState.tone === 'is-low' ? 'text-amber' : densityState.tone === 'is-high' ? 'text-red' : 'text-green'">
                {{ densityDiffText }}
              </div>
              <div class="sub">{{ densityState.label }}</div>
            </div>
          </div>

          <div class="barrel-status level-select">
            <div class="label">桶位段位</div>
            <div class="level-band-bar" role="tablist" aria-label="桶位段位">
              <button
                v-for="band in levelBandOptions"
                :key="band"
                type="button"
                role="tab"
                class="level-band-item"
                :class="{ 'is-active': selectedLevelBand === band }"
                :aria-selected="selectedLevelBand === band"
                @click="selectedLevelBand = band"
              >
                {{ band }}
              </button>
            </div>
            <small>现场人工确认，当前没有液位计。</small>
          </div>

          <ul class="meta-list">
            <li><span>稳定区间：</span><span>{{ stableRangeText }} g/cm³</span></li>
            <li><span>命中规则：</span><span class="text-amber">{{ densityState.label }} / {{ selectedLevelBand }}</span></li>
            <li><span>补水阀建议：</span><span>{{ guidance.water }}%</span></li>
            <li><span>分流阀建议：</span><span>{{ guidance.diverter }}%</span></li>
            <li><span>加介泵建议：</span><span class="text-green">{{ guidance.pump }}</span></li>
            <li><span>控制意图：</span><span>{{ guidance.remark }}</span></li>
          </ul>
        </div>

        <div class="card-panel table-panel matrix-card">
          <div class="card-title">现场规则矩阵</div>
          <el-table :data="visibleRules" size="small" class="dark-table rule-table" :row-class-name="ruleRowClassName">
            <el-table-column prop="density" label="密度状态" min-width="80" />
            <el-table-column prop="level" label="桶位" width="84" />
            <el-table-column prop="water" label="补水" width="56" />
            <el-table-column prop="diverter" label="分流" width="56" />
            <el-table-column prop="pump" label="加介泵" min-width="72" />
          </el-table>
        </div>

        <div class="card-panel control-panel actuator-card">
          <div class="card-title">控制对象</div>
          <div class="control-grid">
            <div class="ctrl-box">
              <div class="name">分流阀</div>
              <div class="num">{{ diverterFeedback.toFixed(0) }}%</div>
              <div class="tip">建议 {{ guidance.diverter }}%，微调上限 20%</div>
            </div>
            <div class="ctrl-box">
              <div class="name">补水阀</div>
              <div class="num text-cyan">{{ waterFeedback.toFixed(0) }}%</div>
              <div class="tip">建议 {{ guidance.water }}%</div>
            </div>
            <div class="ctrl-box" :class="{ alert: guidance.pump === '启动' }">
              <div class="name">加介泵</div>
              <div class="status-text" :class="{ 'animated-flash': guidance.pump === '启动' }">{{ pumpStatusText }}</div>
              <div class="tip">{{ guidance.pump }}</div>
            </div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useIotHub } from '../../composables/useIotHub'
import feederIcon from '../../assets/process/feeder.svg'
import screenIcon from '../../assets/process/screen.svg'
import tankIcon from '../../assets/process/tank.svg'
import magnetIcon from '../../assets/process/magnet.svg'
import processBg from '../../assets/images/smart-density-process-bg-piped.png'
import separator3d from '../../assets/process3d/jzt-separator.png'
import screen3d from '../../assets/process3d/jzt-screen.png'
import centrifuge3d from '../../assets/process3d/jzt-centrifuge.png'
import tank3d from '../../assets/process3d/jzt-tank.png'
import pump3d from '../../assets/process3d/jzt-pump.png'
import magnet3d from '../../assets/process3d/jzt-magnet.png'
import {
  getSmartDensityOverview,
  predictSmartDensity,
  predictSmartDensitySetpoint,
  type SmartDensityPredictResult,
} from '../../api/coal-business'

type DeviceState = 'running' | 'stopped' | 'standby' | 'fault'
type DevicePosition = 'central' | 'maintenance' | 'local'
type DensityBand = 'veryLow' | 'low' | 'stable' | 'high' | 'veryHigh'

const densityUnits = [
  { label: '主洗重介', value: '3207', processName: '主洗重介' },
  { label: '中煤重介', value: '3208', processName: '中煤重介' },
  { label: '末煤重介', value: '316', processName: '末煤重介' },
]

const templates: Record<string, { dataLong: number[]; dataShort: number[]; params: Record<string, any>; target: number }> = {
  '3207': {
    dataLong: [1.552, 1.558, 1.562, 1.566, 42, 11.8, 2850, 2180],
    dataShort: [20, 1, 0, 0],
    params: { water_switch: 0, update_ctrl: 1, density_setpoint: 1.6, run_state: 0 },
    target: 1.6,
  },
  '3208': {
    dataLong: [1.607, 1.604, 1.603, 1.602, 46, 12.6, 2960, 2220],
    dataShort: [12, 1, 0, 0],
    params: { water_switch: 0, update_ctrl: 1, density_setpoint: 1.6, run_state: 0 },
    target: 1.6,
  },
  '316': {
    dataLong: [1.646, 1.650, 1.655, 1.658, 38, 9.8, 2320, 1690],
    dataShort: [35, 1, 0, 0],
    params: { water_switch: 1, update_ctrl: 1, density_setpoint: 1.6, run_state: 0 },
    target: 1.6,
  },
}

const selectedUnit = ref('3207')
const selectedLevelBand = ref('25~50%')
const result = ref<SmartDensityPredictResult | null>(null)
const setpoint = ref<{ predMiddlingDensity: number; predCleanDensity: number; mode: string } | null>(null)
const loading = ref(false)
const iotHub = useIotHub()

const analogTags = {
  density: 'coal.kep.analog.b9e82933eec320e9',
  diverter: 'coal.kep.analog.7014082b6f33a101',
  water: 'coal.kep.analog.7c6a1bd7d61f805c',
}

const deviceStates = ref<Record<string, { state: DeviceState; position: DevicePosition }>>({
  separator: { state: 'running', position: 'central' },
  gangueScreen: { state: 'running', position: 'central' },
  cleanScreen: { state: 'running', position: 'central' },
  addMediumMagnet: { state: 'running', position: 'central' },
  cleanCentrifuge: { state: 'running', position: 'central' },
  addMediumPump: { state: 'running', position: 'central' },
  shallowMediumTank: { state: 'running', position: 'central' },
  blockMediumPump: { state: 'running', position: 'central' },
  blockThinMediumTank: { state: 'running', position: 'central' },
  blockThinMediumPump: { state: 'running', position: 'central' },
  thinMediumMagnet326: { state: 'running', position: 'central' },
  thinMediumMagnet327: { state: 'running', position: 'central' },
  diverterValve: { state: 'running', position: 'central' },
  waterValve: { state: 'running', position: 'central' },
  mediumPump: { state: 'standby', position: 'central' },
})

const levelBandOptions = ['0~25%', '25~50%', '50~75%', '75~100%']

const ruleMatrix: Record<Exclude<DensityBand, 'stable'>, Record<string, { water: number; diverter: number; pump: string; remark: string }>> = {
  veryLow: {
    '0~25%': { water: 40, diverter: 0, pump: '启动', remark: '提桶位、提密度' },
    '25~50%': { water: 20, diverter: 0, pump: '启动', remark: '提桶位、提密度' },
    '50~75%': { water: 0, diverter: 0, pump: '启动', remark: '提密度' },
    '75~100%': { water: 0, diverter: 20, pump: '启动', remark: '提密度' },
  },
  low: {
    '0~25%': { water: 50, diverter: 0, pump: '启动', remark: '提桶位、提密度' },
    '25~50%': { water: 25, diverter: 0, pump: '启动', remark: '提桶位、提密度' },
    '50~75%': { water: 0, diverter: 15, pump: '启动', remark: '提密度' },
    '75~100%': { water: 0, diverter: 20, pump: '启动', remark: '提密度' },
  },
  high: {
    '0~25%': { water: 75, diverter: 0, pump: '停止', remark: '提桶位、降密度' },
    '25~50%': { water: 50, diverter: 0, pump: '停止', remark: '提桶位、降密度' },
    '50~75%': { water: 0, diverter: 15, pump: '停止', remark: '降密度' },
    '75~100%': { water: 0, diverter: 20, pump: '停止', remark: '降密度' },
  },
  veryHigh: {
    '0~25%': { water: 100, diverter: 0, pump: '停止', remark: '提桶位、强降密度' },
    '25~50%': { water: 75, diverter: 0, pump: '停止', remark: '提桶位、降密度' },
    '50~75%': { water: 50, diverter: 15, pump: '停止', remark: '降密度' },
    '75~100%': { water: 0, diverter: 20, pump: '停止', remark: '降密度' },
  },
}

const currentTemplate = computed(() => templates[selectedUnit.value])
const targetDensity = computed(() => currentTemplate.value.target)
const actualDensity = computed(() => Number(getLiveValue(analogTags.density, currentTemplate.value.dataLong[0]).toFixed(3)))
const diverterFeedback = computed(() => Number(getLiveValue(analogTags.diverter, currentTemplate.value.dataLong[4]).toFixed(1)))
const waterFeedback = computed(() => Number(getLiveValue(analogTags.water, currentTemplate.value.dataShort[0]).toFixed(1)))
const densityDiff = computed(() => Number((actualDensity.value - targetDensity.value).toFixed(3)))
const stableRangeText = computed(() => `${(targetDensity.value - 0.005).toFixed(3)} ~ ${(targetDensity.value + 0.005).toFixed(3)}`)
const densityDiffText = computed(() => `${densityDiff.value >= 0 ? '+' : ''}${densityDiff.value.toFixed(3)}`)
const densityState = computed<{ band: DensityBand; label: string; tone: string }>(() => {
  const diff = densityDiff.value
  if (diff <= -0.05) return { band: 'veryLow', label: '严重偏低', tone: 'is-low' }
  if (diff < -0.005) return { band: 'low', label: '偏低', tone: 'is-low' }
  if (diff <= 0.005) return { band: 'stable', label: '稳定区间', tone: 'is-stable' }
  if (diff < 0.05) return { band: 'high', label: '偏高', tone: 'is-high' }
  return { band: 'veryHigh', label: '严重偏高', tone: 'is-high' }
})

const guidance = computed(() => {
  if (densityState.value.band === 'stable') {
    return { water: 0, diverter: 0, pump: '停止', remark: '密度在千分位稳定区间内，保持观察' }
  }
  return ruleMatrix[densityState.value.band][selectedLevelBand.value]
})

const visibleRules = computed(() => {
  const labels: Record<Exclude<DensityBand, 'stable'>, string> = {
    veryLow: '严重偏低',
    low: '偏低',
    high: '偏高',
    veryHigh: '严重偏高',
  }
  if (densityState.value.band === 'stable') {
    return levelBandOptions.map((level) => ({
      density: '稳定',
      level,
      water: '0%',
      diverter: '0%',
      pump: '停止',
    }))
  }
  const band = densityState.value.band as Exclude<DensityBand, 'stable'>
  return levelBandOptions.map((level) => ({
    density: labels[band],
    level,
    water: `${ruleMatrix[band][level].water}%`,
    diverter: `${ruleMatrix[band][level].diverter}%`,
    pump: ruleMatrix[band][level].pump,
  }))
})

const pumpStatusText = computed(() => (guidance.value.pump === '启动' ? '待启动' : '停止'))
const pumpFlowActive = computed(() => guidance.value.pump === '启动')

type NodeRect = {
  key: string
  x: number
  y: number
  w: number
  h: number
  asset?: string
  assetX?: number
  assetY?: number
  assetW?: number
  assetH?: number
  highlight?: boolean
}

type Point = { x: number; y: number }

type FlowEdgeKind = 'raw' | 'product' | 'dense-medium' | 'medium' | 'water' | 'bypass'

interface FlowEdgeItem {
  key: string
  kind: FlowEdgeKind
  path: string
  marker?: string
  lineClass?: string
  animated?: boolean
  lightDelay?: string
  label?: string
  labelX?: number
  labelY?: number
}

const controlPoints = {
  diverter: { x: 360, y: 500 },
  water: { x: 930, y: 520 },
  pump: { x: 92, y: 666 },
}

const coalPebbles = [0, 1, 2, 3, 4, 5, 6, 7]
const sprayNozzles = [0, 1, 2, 3, 4, 5]
const cylinderRibs = [0, 1, 2, 3]

const pumpIconPath = computed(() => {
  const { x, y } = controlPoints.pump
  return `M${x - 13} ${y - 15} L${x + 22} ${y} L${x - 13} ${y + 15} Z`
})

function trapezoidPoints(node: NodeRect) {
  return `${node.x + 10},${node.y} ${node.x + node.w - 10},${node.y} ${node.x + node.w - 30},${node.y + node.h} ${node.x + 30},${node.y + node.h}`
}

function screenShellPoints(node: NodeRect) {
  return `${node.x + 18},${node.y + 28} ${node.x + node.w - 12},${node.y + 18} ${node.x + node.w - 34},${node.y + node.h - 22} ${node.x + 10},${node.y + node.h - 18}`
}

function tankShellPoints(node: NodeRect) {
  return `${node.x + 12},${node.y + 18} ${node.x + node.w - 12},${node.y + 18} ${node.x + node.w - 38},${node.y + node.h - 12} ${node.x + 38},${node.y + node.h - 12}`
}

type LabelNode = NodeRect & {
  subName?: string
  plcLabel?: string
  highlight?: boolean
}

function nodeLabelAnchor(node: LabelNode) {
  if (node.asset) {
    const ax = node.assetX ?? node.x
    const ay = node.assetY ?? node.y
    const aw = node.assetW ?? node.w
    const ah = node.assetH ?? node.h
    const centerX = ax + aw / 2
    const codeY = ay + ah + 4
    return {
      centerX,
      codeY,
      nameY: codeY + 18,
      subY: codeY + 36,
      plcY: codeY + (node.subName ? 54 : 36),
    }
  }
  return {
    centerX: node.x + node.w / 2,
    codeY: node.y + (node.highlight ? 28 : node.h - 24),
    nameY: node.y + (node.highlight ? 48 : node.h - 10),
    subY: node.y + (node.highlight ? 68 : node.h + 8),
    plcY: node.y + node.h + (node.subName ? 26 : 14),
  }
}

function nodeStatusPoint(node: LabelNode) {
  if (node.asset) {
    const ax = node.assetX ?? node.x
    const ay = node.assetY ?? node.y
    return { x: ax + 12, y: ay + 12 }
  }
  return { x: node.x + 14, y: node.y + 12 }
}

function nodeByKey(nodes: NodeRect[], key: string) {
  const node = nodes.find((item) => item.key === key)
  if (!node) throw new Error(`Missing node ${key}`)
  return node
}

function nodePort(
  node: NodeRect,
  side: 'top' | 'bottom' | 'left' | 'right' | 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight',
): Point {
  const cx = node.x + node.w / 2
  const cy = node.y + node.h / 2
  if (node.highlight) {
    const ports: Record<string, Point> = {
      topLeft: { x: node.x + 10, y: node.y },
      topRight: { x: node.x + node.w - 10, y: node.y },
      bottomLeft: { x: node.x + 30, y: node.y + node.h },
      bottomRight: { x: node.x + node.w - 30, y: node.y + node.h },
      top: { x: cx, y: node.y },
      bottom: { x: cx, y: node.y + node.h },
      left: { x: node.x + 20, y: cy },
      right: { x: node.x + node.w - 20, y: cy },
    }
    return ports[side]
  }
  const ports: Record<string, Point> = {
    top: { x: cx, y: node.y },
    bottom: { x: cx, y: node.y + node.h },
    left: { x: node.x, y: cy },
    right: { x: node.x + node.w, y: cy },
  }
  return ports[side]
}

function connectPath(...points: Point[]) {
  if (points.length <= 2) {
    return points.map((point, index) => `${index === 0 ? 'M' : 'L'} ${Math.round(point.x)} ${Math.round(point.y)}`).join(' ')
  }

  const radius = 14
  const segments = [`M ${Math.round(points[0].x)} ${Math.round(points[0].y)}`]

  for (let index = 1; index < points.length - 1; index += 1) {
    const previous = points[index - 1]
    const current = points[index]
    const next = points[index + 1]
    const previousLength = Math.hypot(current.x - previous.x, current.y - previous.y)
    const nextLength = Math.hypot(next.x - current.x, next.y - current.y)
    const cornerRadius = Math.min(radius, previousLength / 2, nextLength / 2)

    if (cornerRadius <= 1) {
      segments.push(`L ${Math.round(current.x)} ${Math.round(current.y)}`)
      continue
    }

    const beforeCorner = {
      x: current.x - ((current.x - previous.x) / previousLength) * cornerRadius,
      y: current.y - ((current.y - previous.y) / previousLength) * cornerRadius,
    }
    const afterCorner = {
      x: current.x + ((next.x - current.x) / nextLength) * cornerRadius,
      y: current.y + ((next.y - current.y) / nextLength) * cornerRadius,
    }

    segments.push(`L ${Math.round(beforeCorner.x)} ${Math.round(beforeCorner.y)}`)
    segments.push(`Q ${Math.round(current.x)} ${Math.round(current.y)} ${Math.round(afterCorner.x)} ${Math.round(afterCorner.y)}`)
  }

  const last = points[points.length - 1]
  segments.push(`L ${Math.round(last.x)} ${Math.round(last.y)}`)
  return segments.join(' ')
}

const processNodes = computed(() => [
  { key: 'separator', code: '317', name: '浅槽分选机', subName: `密度 ${actualDensity.value.toFixed(3)}`, kind: 'separator', x: 292, y: 70, w: 300, h: 120, icon: feederIcon, asset: separator3d, assetX: 238, assetY: 38, assetW: 395, assetH: 252, highlight: false },
  { key: 'gangueScreen', code: '321', name: '块矸石脱介筛', kind: 'screen', x: 120, y: 245, w: 220, h: 100, icon: screenIcon, asset: screen3d, assetX: 82, assetY: 210, assetW: 300, assetH: 210, highlight: false },
  { key: 'cleanScreen', code: '318', name: '块精煤脱介筛', kind: 'screen', x: 570, y: 245, w: 220, h: 100, icon: screenIcon, asset: screen3d, assetX: 532, assetY: 210, assetW: 300, assetH: 210, highlight: false },
  { key: 'addMediumMagnet', code: '333', name: '加介磁选机', kind: 'magnet', x: 122, y: 620, w: 170, h: 78, icon: magnetIcon, asset: magnet3d, assetX: 92, assetY: 585, assetW: 245, assetH: 140, highlight: false },
  { key: 'cleanCentrifuge', code: '319', name: '精煤离心机', kind: 'centrifuge', x: 805, y: 260, w: 145, h: 80, icon: magnetIcon, asset: centrifuge3d, assetX: 778, assetY: 232, assetW: 205, assetH: 148, highlight: false },
  { key: 'addMediumPump', code: '332', name: '加介泵', kind: 'pump', x: 34, y: 620, w: 82, h: 56, icon: tankIcon, asset: pump3d, assetX: 6, assetY: 594, assetW: 135, assetH: 108, highlight: false },
  {
    key: 'shallowMediumTank',
    code: '322',
    name: '浅槽合介桶',
    plcLabel: `桶位 ${selectedLevelBand.value}`,
    kind: 'tank',
    x: 330,
    y: 405,
    w: 125,
    h: 115,
    icon: tankIcon,
    asset: tank3d,
    assetX: 298,
    assetY: 355,
    assetW: 180,
    assetH: 286,
    highlight: true,
  },
  { key: 'blockMediumPump', code: '323', name: '块煤合介泵', kind: 'pump', x: 405, y: 590, w: 92, h: 62, icon: tankIcon, asset: pump3d, assetX: 374, assetY: 560, assetW: 148, assetH: 118, highlight: false },
  {
    key: 'blockThinMediumTank',
    code: '324',
    name: '块煤稀介桶',
    kind: 'tank',
    x: 520,
    y: 405,
    w: 125,
    h: 115,
    icon: tankIcon,
    asset: tank3d,
    assetX: 488,
    assetY: 355,
    assetW: 180,
    assetH: 286,
    highlight: true,
  },
  { key: 'blockThinMediumPump', code: '325', name: '块煤稀介泵', kind: 'pump', x: 560, y: 590, w: 92, h: 62, icon: tankIcon, asset: pump3d, assetX: 530, assetY: 560, assetW: 148, assetH: 118, highlight: false },
  { key: 'thinMediumMagnet326', code: '326', name: '块煤稀介磁选机', kind: 'magnet', x: 700, y: 455, w: 170, h: 78, icon: magnetIcon, asset: magnet3d, assetX: 672, assetY: 420, assetW: 245, assetH: 140, highlight: false },
  { key: 'thinMediumMagnet327', code: '327', name: '块煤稀介磁选机', kind: 'magnet', x: 700, y: 575, w: 170, h: 78, icon: magnetIcon, asset: magnet3d, assetX: 672, assetY: 540, assetW: 245, assetH: 140, highlight: false },
])

const flowEdges = computed<FlowEdgeItem[]>(() => {
  const nodes = processNodes.value
  const separator = nodeByKey(nodes, 'separator')
  const gangueScreen = nodeByKey(nodes, 'gangueScreen')
  const cleanScreen = nodeByKey(nodes, 'cleanScreen')
  const cleanCentrifuge = nodeByKey(nodes, 'cleanCentrifuge')
  const addMediumMagnet = nodeByKey(nodes, 'addMediumMagnet')
  const addMediumPump = nodeByKey(nodes, 'addMediumPump')
  const shallowMediumTank = nodeByKey(nodes, 'shallowMediumTank')
  const blockMediumPump = nodeByKey(nodes, 'blockMediumPump')
  const blockThinMediumTank = nodeByKey(nodes, 'blockThinMediumTank')
  const blockThinMediumPump = nodeByKey(nodes, 'blockThinMediumPump')
  const thinMediumMagnet326 = nodeByKey(nodes, 'thinMediumMagnet326')
  const thinMediumMagnet327 = nodeByKey(nodes, 'thinMediumMagnet327')
  const { diverter } = controlPoints

  return [
    {
      key: 'separator-to-gangue-screen',
      kind: 'product',
      lineClass: 'material-line',
      marker: 'url(#arrow-flow)',
      label: '块矸石+介质',
      labelX: 286,
      labelY: 225,
      path: connectPath({ x: 330, y: 190 }, { x: 330, y: 226 }, nodePort(gangueScreen, 'top')),
    },
    {
      key: 'separator-to-clean-screen',
      kind: 'product',
      lineClass: 'material-line',
      marker: 'url(#arrow-flow)',
      label: '块精煤+介质',
      labelX: 655,
      labelY: 224,
      path: connectPath({ x: 555, y: 190 }, { x: 555, y: 226 }, nodePort(cleanScreen, 'top')),
    },
    {
      key: 'gangue-product',
      kind: 'product',
      marker: 'url(#arrow-flow)',
      label: '矸石',
      labelX: 118,
      labelY: 395,
      path: connectPath(nodePort(gangueScreen, 'bottom'), { x: 155, y: 405 }),
    },
    {
      key: 'gangue-screen-good-medium-to-322',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      label: '321合介回322',
      labelX: 280,
      labelY: 376,
      path: connectPath({ x: 250, y: 340 }, { x: 250, y: 385 }, nodePort(shallowMediumTank, 'left')),
    },
    {
      key: 'gangue-screen-thin-medium-to-324',
      kind: 'medium',
      marker: 'url(#arrow-flow)',
      label: '321稀介回324',
      labelX: 478,
      labelY: 348,
      path: connectPath({ x: 320, y: 315 }, { x: 500, y: 315 }, nodePort(blockThinMediumTank, 'top')),
    },
    {
      key: 'clean-screen-to-centrifuge',
      kind: 'product',
      marker: 'url(#arrow-flow)',
      label: '块精煤',
      labelX: 805,
      labelY: 352,
      path: connectPath(nodePort(cleanScreen, 'right'), nodePort(cleanCentrifuge, 'left')),
    },
    {
      key: 'clean-screen-good-medium-to-322',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      label: '318合介回322',
      labelX: 486,
      labelY: 386,
      path: connectPath({ x: 620, y: 345 }, { x: 620, y: 382 }, { x: 445, y: 382 }, nodePort(shallowMediumTank, 'right')),
    },
    {
      key: 'clean-screen-thin-medium-to-324',
      kind: 'medium',
      marker: 'url(#arrow-flow)',
      label: '318稀介回324',
      labelX: 650,
      labelY: 374,
      path: connectPath({ x: 675, y: 345 }, { x: 675, y: 385 }, nodePort(blockThinMediumTank, 'right')),
    },
    {
      key: 'centrifuge-product',
      kind: 'product',
      marker: 'url(#arrow-flow)',
      label: '块精煤产品',
      labelX: 886,
      labelY: 410,
      path: connectPath(nodePort(cleanCentrifuge, 'bottom'), { x: 875, y: 420 }),
    },
    {
      key: 'add-pump-to-add-magnet',
      kind: 'bypass',
      marker: 'url(#arrow-medium)',
      label: '加介介质',
      labelX: 92,
      labelY: 706,
      path: connectPath(nodePort(addMediumPump, 'right'), nodePort(addMediumMagnet, 'left')),
    },
    {
      key: 'add-magnet-to-322',
      kind: 'bypass',
      marker: 'url(#arrow-medium)',
      label: '333补介回322',
      labelX: 280,
      labelY: 610,
      path: connectPath(nodePort(addMediumMagnet, 'right'), { x: 330, y: 625 }, nodePort(shallowMediumTank, 'bottom')),
    },
    {
      key: 'shallow-tank-to-block-pump',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      animated: true,
      label: '合介到泵',
      labelX: 430,
      labelY: 565,
      path: connectPath(nodePort(shallowMediumTank, 'bottom'), nodePort(blockMediumPump, 'top')),
    },
    {
      key: 'block-pump-to-separator',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      animated: true,
      label: '合介上料',
      labelX: 150,
      labelY: 100,
      path: connectPath(nodePort(blockMediumPump, 'left'), { x: 100, y: 590 }, { x: 100, y: 110 }, nodePort(separator, 'left')),
    },
    {
      key: 'block-thin-tank-to-thin-pump',
      kind: 'medium',
      marker: 'url(#arrow-medium)',
      label: '稀介到泵',
      labelX: 590,
      labelY: 565,
      path: connectPath(nodePort(blockThinMediumTank, 'bottom'), nodePort(blockThinMediumPump, 'top')),
    },
    {
      key: 'thin-pump-to-magnet-326',
      kind: 'medium',
      marker: 'url(#arrow-medium)',
      label: '送326磁选',
      labelX: 690,
      labelY: 520,
      path: connectPath(nodePort(blockThinMediumPump, 'right'), { x: 680, y: 620 }, { x: 680, y: 500 }, nodePort(thinMediumMagnet326, 'left')),
    },
    {
      key: 'thin-pump-to-magnet-327',
      kind: 'medium',
      marker: 'url(#arrow-medium)',
      label: '送327磁选',
      labelX: 690,
      labelY: 640,
      path: connectPath(nodePort(blockThinMediumPump, 'right'), nodePort(thinMediumMagnet327, 'left')),
    },
    {
      key: 'thin-magnet-concentrate-to-322',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      label: '磁选精矿回322',
      labelX: 640,
      labelY: 440,
      path: connectPath(nodePort(thinMediumMagnet326, 'top'), { x: 645, y: 415 }, { x: 455, y: 415 }, nodePort(shallowMediumTank, 'right')),
    },
    {
      key: 'thin-magnet-concentrate-to-322-lower',
      kind: 'dense-medium',
      marker: 'url(#arrow-dense)',
      label: '',
      path: connectPath(nodePort(thinMediumMagnet327, 'top'), { x: 650, y: 535 }, { x: 455, y: 535 }, nodePort(shallowMediumTank, 'right')),
    },
    {
      key: 'thin-magnet-tailwater-326',
      kind: 'water',
      marker: 'url(#arrow-water)',
      label: '尾水去煤泥水',
      labelX: 900,
      labelY: 575,
      path: connectPath(nodePort(thinMediumMagnet326, 'right'), { x: 910, y: 494 }, { x: 910, y: 676 }, { x: 950, y: 676 }),
    },
    {
      key: 'thin-magnet-tailwater-327',
      kind: 'water',
      marker: 'url(#arrow-water)',
      label: '',
      path: connectPath(nodePort(thinMediumMagnet327, 'right'), { x: 910, y: 614 }, { x: 910, y: 676 }),
    },
    {
      key: 'water-614-main',
      kind: 'water',
      marker: 'url(#arrow-water)',
      animated: true,
      label: '614块煤水泵补水',
      labelX: 520,
      labelY: 720,
      path: connectPath({ x: 430, y: 720 }, { x: 910, y: 720 }, { x: 910, y: 494 }),
    },
    {
      key: 'water-to-318',
      kind: 'water',
      marker: 'url(#arrow-water)',
      animated: true,
      label: '补水到318',
      labelX: 610,
      labelY: 214,
      path: connectPath({ x: 610, y: 720 }, { x: 610, y: 345 }),
    },
    {
      key: 'water-to-321',
      kind: 'water',
      marker: 'url(#arrow-water)',
      animated: true,
      label: '补水到321',
      labelX: 270,
      labelY: 214,
      path: connectPath({ x: 270, y: 720 }, { x: 270, y: 345 }),
    },
    {
      key: 'water-to-322',
      kind: 'water',
      marker: 'url(#arrow-water)',
      animated: true,
      label: '补水到322',
      labelX: 390,
      labelY: 362,
      path: connectPath({ x: 390, y: 720 }, nodePort(shallowMediumTank, 'top')),
    },
    {
      key: 'water-to-324',
      kind: 'water',
      marker: 'url(#arrow-water)',
      animated: true,
      label: '补水到324',
      labelX: 582,
      labelY: 362,
      path: connectPath({ x: 582, y: 720 }, nodePort(blockThinMediumTank, 'top')),
    },
    {
      key: 'diverter-to-pump',
      kind: 'bypass',
      marker: 'url(#arrow-flow)',
      label: '分流调节',
      labelX: 356,
      labelY: 508,
      path: connectPath({ x: 270, y: 345 }, { x: 270, y: 500 }, diverter, nodePort(blockMediumPump, 'left')),
    },
  ].map((edge, index) => ({
    ...edge,
    lightDelay: `${-(index * 0.32).toFixed(2)}s`,
  }))
})
const getLiveValue = (tagCode: string, fallback: number) => {
  const live = iotHub.getTagValue(tagCode)?.value
  return typeof live === 'number' && Number.isFinite(live) ? live : fallback
}

function deviceClass(key: string) {
  const device = deviceStates.value[key]
  const pumpShouldRun = (key === 'mediumPump' || key === 'addMediumPump') && guidance.value.pump === '启动'
  const state = pumpShouldRun ? 'running' : device?.state || 'standby'
  const position = device?.position || 'central'
  return [`is-${state}`, `pos-${position}`]
}

function ruleRowClassName({ row }: { row: { level: string } }) {
  return row.level === selectedLevelBand.value ? 'is-active-row' : ''
}

function handleUnitChange() {
  result.value = null
}

async function loadOverview() {
  try {
    const data = await getSmartDensityOverview()
    setpoint.value = data.setpoint
  } catch {
    setpoint.value = { predMiddlingDensity: currentTemplate.value.target, predCleanDensity: 1.38, mode: '实时点位回退' }
  }
}

async function runPredict() {
  try {
    loading.value = true
    const template = currentTemplate.value
    const payload = {
      unit: selectedUnit.value,
      dataLong: template.dataLong,
      dataShort: template.dataShort,
      params: template.params,
    }
    result.value = await predictSmartDensity(payload)
    setpoint.value = await predictSmartDensitySetpoint({ data: [targetDensity.value, actualDensity.value, waterFeedback.value] })
    ElMessage.success(`智能密控 ${selectedUnit.value} 建议已刷新`)
  } catch (error: any) {
    result.value = {
      unit: selectedUnit.value,
      predDiverter: guidance.value.diverter,
      predWater: guidance.value.water,
      predDensity: actualDensity.value,
      state: 0,
      stateName: densityState.value.label,
      mode: '实时点位回退',
    }
    ElMessage.warning(error?.message || '模型未响应，已使用现场规则建议')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  iotHub.subscribe({ pageKey: 'smart-density', intervalMs: 5000 })
  await iotHub.ensureFresh('smart-density', 2000)
  await loadOverview()
  await runPredict()
})

onUnmounted(() => {
  iotHub.unsubscribe?.('smart-density')
})
</script>

<style scoped>
.smart-density-container {
  --sd-bg: #0b0f19;
  --sd-panel: #111827;
  --sd-panel-border: #1e293b;
  --sd-card: #1e293b;
  --sd-card-border: #334155;
  --sd-text: #e2e8f0;
  --sd-muted: #94a3b8;
  --sd-cyan: #22d3ee;
  --sd-green: #4ade80;
  --sd-amber: #fbbf24;
  --sd-red: #f87171;

  height: 100%;
  min-height: 0;
  overflow: hidden;
  padding: 12px 14px;
  background: var(--sd-bg);
  color: var(--sd-text);
  display: flex;
  flex-direction: column;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'PingFang SC', sans-serif;
}

:global(body.coal-theme .app-main > .smart-density-page),
:global(body.coal-theme .smart-density-page) {
  height: 100% !important;
  min-height: 0 !important;
  overflow: hidden !important;
  padding: 12px 14px !important;
  background: #0b0f19 !important;
}

.header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--sd-panel-border);
  padding-bottom: 12px;
  margin-bottom: 12px;
  flex-shrink: 0;
}

.header-bar .title {
  font-size: 18px;
  font-weight: 600;
  color: #f8fafc;
  letter-spacing: 0.5px;
}

.header-bar .actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.main-content,
.density-workbench {
  flex: 1;
  min-height: 0;
  display: flex;
  gap: 14px;
  overflow: hidden;
}

.flow-chart-panel {
  flex: 1;
  min-width: 0;
  background: var(--sd-panel);
  border: 1px solid var(--sd-panel-border);
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  box-shadow: inset 0 4px 20px rgba(0, 0, 0, 0.5);
  overflow: hidden;
}

.canvas-wrapper,
.flow-map-wrap {
  flex: 1;
  min-height: 0;
  position: relative;
  overflow: hidden;
  background:
    radial-gradient(circle at 50% 45%, rgba(6, 182, 212, 0.12), transparent 38%),
    linear-gradient(135deg, rgba(4, 12, 27, 0.96), rgba(7, 24, 45, 0.92) 50%, rgba(4, 12, 27, 0.96));
}

.canvas-wrapper::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(68, 181, 255, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(68, 181, 255, 0.05) 1px, transparent 1px);
  background-size: 28px 28px;
  mask-image: radial-gradient(circle at 50% 45%, #000 0%, transparent 78%);
  pointer-events: none;
}

.process-svg,
.flow-map {
  width: 100%;
  height: 100%;
  display: block;
  position: absolute;
  inset: 0;
  z-index: 2;
}

.process-bg-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: fill;
  opacity: 0;
  pointer-events: none;
  z-index: 1;
}

.overlay-pipe-layer {
  display: block;
}

.theory-board {
  position: absolute;
  top: 16px;
  left: 16px;
  background: rgba(30, 41, 59, 0.88);
  border: 1px solid var(--sd-card-border);
  padding: 10px 14px;
  border-radius: 6px;
  backdrop-filter: blur(4px);
  z-index: 3;
}

.theory-board p {
  margin: 4px 0;
  font-size: 13px;
  color: var(--sd-muted);
}

.theory-board span {
  color: var(--sd-cyan);
  font-weight: 700;
}

.pipe-legend-panel {
  position: absolute;
  top: 16px;
  right: 16px;
  z-index: 3;
  display: grid;
  gap: 7px;
  min-width: 190px;
  padding: 11px 14px;
  color: #dbeafe;
  font-size: 12px;
  font-weight: 600;
  background: rgba(3, 10, 18, 0.48);
  border: 1px dashed rgba(203, 213, 225, 0.58);
  border-radius: 8px;
  backdrop-filter: blur(4px);
}

.pipe-legend-panel div {
  display: flex;
  align-items: center;
  gap: 10px;
  white-space: nowrap;
}

.pipe-legend-panel .line {
  width: 34px;
  height: 3px;
  border-radius: 999px;
  box-shadow: 0 0 8px currentColor;
}

.pipe-legend-panel .product {
  background: #e5e7eb;
  color: #e5e7eb;
}

.pipe-legend-panel .dense {
  background: #4ade80;
  color: #4ade80;
}

.pipe-legend-panel .medium {
  background: #f97316;
  color: #f97316;
}

.pipe-legend-panel .water {
  background: #38bdf8;
  color: #38bdf8;
}

.pipe-legend-panel .bypass {
  background: #a855f7;
  color: #a855f7;
}

.bottom-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  padding: 10px 14px;
  border-top: 1px solid var(--sd-panel-border);
  font-size: 12px;
  color: var(--sd-muted);
  flex-shrink: 0;
}

.legend-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot.run {
  background: var(--sd-green);
}

.dot.idle {
  background: #64748b;
}

.dot.standby {
  background: var(--sd-cyan);
}

.dot.fault {
  background: var(--sd-red);
}

.dot.manual {
  background: var(--sd-amber);
}

.pipe-shadow,
.pipe-body,
.pipe-highlight,
.pipe-flow-light,
.pipe-flow-light-glow {
  fill: none;
  stroke-linecap: round;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
  pointer-events: none;
}

.pipe-shadow {
  stroke: rgba(0, 0, 0, 0.72);
  stroke-width: 14;
  filter: blur(1.4px);
  transform: translate(2px, 3px);
  opacity: 0.82;
}

.pipe-body {
  stroke-width: 9;
  filter:
    drop-shadow(0 3px 4px rgba(0, 0, 0, 0.45))
    drop-shadow(0 0 4px rgba(80, 210, 255, 0.1));
}

.pipe-body.raw {
  stroke: url(#pipe-raw);
}

.pipe-body.dense-medium {
  stroke: url(#sd-mediumGrad);
}

.pipe-body.water {
  stroke: url(#pipe-water);
}

.pipe-body.medium {
  stroke: url(#pipe-medium);
}

.pipe-body.product {
  stroke: url(#pipe-product);
}

.pipe-body.bypass {
  stroke: url(#pipe-bypass);
}

.pipe-highlight {
  stroke: rgba(255, 255, 255, 0.5);
  stroke-width: 2;
  opacity: 0.62;
}

.pipe-highlight.raw,
.pipe-highlight.dense-medium {
  stroke: rgba(175, 255, 214, 0.76);
}

.pipe-highlight.water {
  stroke: rgba(184, 250, 255, 0.72);
}

.pipe-highlight.medium {
  stroke: rgba(255, 239, 170, 0.76);
}

.pipe-highlight.bypass {
  stroke: rgba(255, 188, 180, 0.78);
}

.pipe-body.flow-animate {
  animation: none;
}

.pipe-flow-light-glow {
  stroke: rgba(255, 255, 255, 0.55);
  stroke-width: 12;
  stroke-dasharray: 4 52;
  stroke-dashoffset: 0;
  opacity: 0.34;
  animation: pipeLightGlow 3s linear infinite;
  filter: blur(2px);
}

.pipe-flow-light-glow.raw,
.pipe-flow-light-glow.product {
  stroke: rgba(248, 250, 252, 0.72);
}

.pipe-flow-light-glow.dense-medium {
  stroke: rgba(74, 222, 128, 0.78);
}

.pipe-flow-light-glow.medium {
  stroke: rgba(251, 146, 60, 0.78);
}

.pipe-flow-light-glow.water {
  stroke: rgba(34, 211, 238, 0.82);
}

.pipe-flow-light-glow.bypass {
  stroke: rgba(192, 132, 252, 0.82);
}

.pipe-flow-light {
  stroke: rgba(255, 255, 255, 0.92);
  stroke-width: 4;
  stroke-dasharray: 8 28 2 32;
  stroke-dashoffset: 0;
  opacity: 0.88;
  animation: pipeLight 2.4s linear infinite;
  filter:
    drop-shadow(0 0 4px currentColor)
    drop-shadow(0 0 10px currentColor);
}

.pipe-flow-light.raw,
.pipe-flow-light.product {
  stroke: rgba(248, 250, 252, 0.86);
}

.pipe-flow-light.dense-medium {
  stroke: rgba(134, 239, 172, 0.92);
}

.pipe-flow-light.medium {
  stroke: rgba(253, 186, 116, 0.92);
}

.pipe-flow-light.water {
  stroke: rgba(103, 232, 249, 0.92);
}

.pipe-flow-light.bypass {
  stroke: rgba(216, 180, 254, 0.96);
}

.overlay-pipe-layer.is-active-flow .pipe-flow-light,
.overlay-pipe-layer.is-active-flow .pipe-flow-light-glow {
  animation-duration: 1s;
  opacity: 1;
}

@keyframes pipeLight {
  to {
    stroke-dashoffset: -120;
  }
}

@keyframes pipeLightGlow {
  to {
    stroke-dashoffset: -140;
  }
}

.flow-label {
  paint-order: stroke;
  stroke: rgba(3, 7, 12, 0.95);
  stroke-width: 5px;
  stroke-linejoin: round;
  fill: #dbeafe;
  font-size: 12px;
  font-weight: 700;
  text-anchor: middle;
  dominant-baseline: middle;
  pointer-events: none;
}

.flow-label.raw {
  fill: #86efac;
}

.flow-label.water {
  fill: #67e8f9;
}

.flow-label.dense-medium {
  fill: #4ade80;
}

.flow-label.medium {
  fill: #fde68a;
}

.flow-label.bypass {
  fill: #fca5a5;
}

.device-node .node-hit {
  fill: transparent;
  stroke: transparent;
  stroke-width: 0;
  transition: all 0.3s;
}

.device-node.highlight .node-trapezoid,
.device-node.highlight .node-hit {
  fill: transparent;
  stroke: transparent;
  stroke-width: 0;
}

.device-shell {
  fill: url(#device-steel);
  stroke: rgba(148, 163, 184, 0.72);
  stroke-width: 1.2;
  filter:
    drop-shadow(0 6px 8px rgba(0, 0, 0, 0.36))
    drop-shadow(0 0 7px rgba(34, 211, 238, 0.08));
}

.device-shell,
.device-deck,
.device-leg,
.separator-detail,
.screen-detail,
.device-base,
.device-cylinder-end,
.device-motor,
.device-impeller,
.pump-flange,
.tank-rim,
.tank-water {
  display: none;
}

.screen-shell {
  fill: url(#device-steel);
}

.separator-detail,
.screen-detail {
  pointer-events: none;
}

.coal-bed-plate {
  fill: rgba(10, 17, 24, 0.9);
  stroke: rgba(148, 163, 184, 0.28);
  stroke-width: 0.8;
}

.coal-pebble {
  fill: #111827;
  stroke: rgba(203, 213, 225, 0.28);
  stroke-width: 0.7;
  filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.6));
}

.guard-rail {
  stroke: rgba(245, 158, 11, 0.78);
  stroke-width: 1.2;
  vector-effect: non-scaling-stroke;
}

.guard-rail.muted {
  stroke: rgba(245, 158, 11, 0.38);
}

.spray-main {
  stroke: rgba(148, 163, 184, 0.68);
  stroke-width: 1.2;
  vector-effect: non-scaling-stroke;
}

.spray-nozzle {
  fill: #38bdf8;
  stroke: rgba(15, 23, 42, 0.8);
  stroke-width: 0.7;
}

.spray-fall {
  stroke: rgba(56, 189, 248, 0.62);
  stroke-width: 1.4;
  stroke-linecap: round;
  vector-effect: non-scaling-stroke;
}

.device-deck {
  stroke: rgba(125, 211, 252, 0.58);
  stroke-width: 2;
  vector-effect: non-scaling-stroke;
}

.device-deck.muted {
  stroke: rgba(148, 163, 184, 0.38);
  stroke-width: 1.4;
}

.magnet-body {
  fill: rgba(52, 63, 72, 0.95);
}

.device-base {
  fill: rgba(9, 14, 20, 0.82);
  stroke: rgba(148, 163, 184, 0.42);
  stroke-width: 0.9;
  filter: drop-shadow(0 4px 5px rgba(0, 0, 0, 0.42));
}

.device-leg {
  stroke: rgba(148, 163, 184, 0.66);
  stroke-width: 2;
  stroke-linecap: round;
  vector-effect: non-scaling-stroke;
}

.device-cylinder-end {
  fill: rgba(18, 27, 35, 0.95);
  stroke: rgba(148, 163, 184, 0.64);
  stroke-width: 1.1;
}

.cylinder-rib {
  stroke: rgba(203, 213, 225, 0.36);
  stroke-width: 1.1;
  vector-effect: non-scaling-stroke;
}

.device-motor {
  fill: rgba(77, 92, 104, 0.95);
  stroke: rgba(148, 163, 184, 0.55);
  stroke-width: 1;
}

.pump-body {
  fill: rgba(38, 54, 64, 0.96);
}

.device-impeller {
  fill: rgba(15, 23, 42, 0.88);
  stroke: rgba(125, 211, 252, 0.58);
  stroke-width: 1.2;
}

.pump-flange {
  fill: rgba(15, 23, 42, 0.86);
  stroke: rgba(125, 211, 252, 0.62);
  stroke-width: 1;
}

.tank-shell {
  fill: url(#device-tank);
  stroke: rgba(103, 232, 249, 0.78);
}

.tank-rim {
  fill: rgba(7, 20, 28, 0.86);
  stroke: rgba(148, 163, 184, 0.54);
  stroke-width: 1.1;
}

.tank-water {
  fill: rgba(34, 211, 238, 0.28);
  stroke: rgba(103, 232, 249, 0.55);
  stroke-width: 0.8;
  filter: drop-shadow(0 0 5px rgba(34, 211, 238, 0.32));
}

.device-node .node-shadow {
  fill: transparent;
}

.device-node .node-image {
  opacity: 0;
  filter: drop-shadow(0 0 8px rgba(47, 224, 165, 0.35));
}

.equipment-asset {
  pointer-events: none;
  filter:
    drop-shadow(0 12px 14px rgba(0, 0, 0, 0.48))
    drop-shadow(0 0 10px rgba(34, 211, 238, 0.08));
}

.device-node.has-asset .node-id {
  fill: #f8fafc;
  font-size: 13px;
  font-weight: 800;
}

.device-node.has-asset .node-name {
  fill: #dbeafe;
  font-size: 12px;
  font-weight: 600;
}

.device-node.has-asset .node-status {
  filter: drop-shadow(0 0 4px rgba(34, 211, 238, 0.8));
}

.device-node .node-status {
  fill: var(--sd-cyan);
}

.device-node.is-running .node-hit {
  stroke: transparent;
}

.device-node.is-standby .node-hit {
  stroke: transparent;
}

.device-node.is-stopped .node-hit {
  stroke: #64748b;
}

.device-node.is-fault .node-hit {
  animation: faultBlink 1s infinite;
}

.node-id,
.device-title {
  fill: #94a3b8;
  font-size: 12px;
  font-weight: 700;
  text-anchor: middle;
  dominant-baseline: middle;
}

.node-name,
.device-name {
  fill: #cbd5e1;
  font-size: 12px;
  text-anchor: middle;
  dominant-baseline: middle;
}

.node-name.big {
  fill: #f8fafc;
  font-size: 14px;
  font-weight: 700;
}

.node-value,
.plc-label {
  fill: var(--sd-cyan);
  font-size: 12px;
  font-weight: 500;
  text-anchor: middle;
  dominant-baseline: middle;
}

.advice-label {
  fill: var(--sd-amber);
  font-size: 12px;
  text-anchor: middle;
  dominant-baseline: middle;
}

.equipment.pos-central .node-id,
.equipment.pos-central .device-title {
  fill: #050505;
  stroke: #eef6ff;
  stroke-width: 2px;
}

.valve-ring,
.pump-ring {
  fill: #1e293b;
  stroke: #f59e0b;
  stroke-width: 2;
}

.valve-icon {
  fill: #ef4444;
  font-size: 14px;
  font-weight: 700;
  text-anchor: middle;
  dominant-baseline: middle;
}

.control-device.pump-active .pump-ring {
  stroke: var(--sd-green);
  filter: drop-shadow(0 0 8px rgba(74, 222, 128, 0.6));
}

.control-device path {
  fill: #eef6ff;
}

.flow-meter rect {
  fill: rgba(30, 41, 59, 0.88);
  stroke: rgba(51, 65, 85, 0.8);
}

.flow-meter {
  display: none;
}

.flow-meter text {
  fill: #94a3b8;
  font-size: 10px;
  text-anchor: start;
  dominant-baseline: middle;
}

.density-meter text:last-child {
  fill: var(--sd-amber);
}

.data-sidebar,
.guidance-panel {
  width: 380px;
  min-width: 380px;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
  overflow-y: auto;
}

.card-panel {
  background: var(--sd-panel);
  border: 1px solid var(--sd-panel-border);
  border-radius: 8px;
  padding: 14px;
}

.card-title {
  font-size: 14px;
  color: var(--sd-muted);
  font-weight: 600;
  margin-bottom: 12px;
  border-left: 3px solid #06b6d4;
  padding-left: 8px;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-bottom: 14px;
}

.kpi-item {
  background: var(--sd-card);
  padding: 10px 8px;
  border-radius: 6px;
  text-align: center;
  border: 1px solid var(--sd-card-border);
}

.kpi-item .label {
  font-size: 11px;
  color: var(--sd-muted);
}

.kpi-item .value {
  font-size: 18px;
  font-weight: 700;
  margin: 4px 0;
  color: #f1f5f9;
}

.kpi-item .sub {
  font-size: 10px;
  color: #64748b;
}

.barrel-status .label,
.level-select label {
  font-size: 12px;
  color: var(--sd-muted);
  margin-bottom: 8px;
}

.level-select small {
  display: block;
  margin-top: 8px;
  font-size: 11px;
  color: var(--sd-amber);
}

.level-band-bar {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  border: 1px solid var(--sd-card-border);
  border-radius: 6px;
  overflow: hidden;
  background: #0f172a;
}

.level-band-item {
  border: none;
  border-right: 1px solid var(--sd-card-border);
  background: transparent;
  color: #64748b;
  font-size: 11px;
  font-weight: 600;
  padding: 8px 2px;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.level-band-item:last-child {
  border-right: none;
}

.level-band-item.is-active {
  background: linear-gradient(180deg, #06b6d4, #0891b2);
  color: #041018;
}

.meta-list {
  list-style: none;
  margin: 12px 0 0;
  padding: 0;
  font-size: 12px;
}

.meta-list li {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  padding: 7px 0;
  border-bottom: 1px solid rgba(51, 65, 85, 0.6);
  color: #cbd5e1;
}

.meta-list li span:first-child {
  color: var(--sd-muted);
  flex-shrink: 0;
}

.table-panel {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.control-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.ctrl-box {
  background: var(--sd-card);
  border: 1px solid var(--sd-card-border);
  padding: 10px 8px;
  border-radius: 6px;
  text-align: center;
}

.ctrl-box .name {
  font-size: 12px;
  color: var(--sd-muted);
}

.ctrl-box .num,
.ctrl-box .status-text {
  font-size: 16px;
  font-weight: 700;
  margin-top: 4px;
  color: #f1f5f9;
}

.ctrl-box .tip {
  font-size: 9px;
  color: #64748b;
  margin-top: 4px;
  line-height: 1.3;
}

.ctrl-box.alert {
  border-color: #ca8a04;
  background: rgba(202, 138, 4, 0.1);
}

.ctrl-box.alert .status-text {
  color: #facc15;
}

.text-cyan {
  color: var(--sd-cyan) !important;
}

.text-amber {
  color: var(--sd-amber) !important;
}

.text-green {
  color: var(--sd-green) !important;
}

.text-red {
  color: var(--sd-red) !important;
}

.rule-table {
  flex: 1;
  min-height: 0;
}

.rule-table :deep(.el-table__cell) {
  padding: 4px 0;
}

.rule-table :deep(.is-active-row td.el-table__cell) {
  background: rgba(6, 182, 212, 0.18) !important;
  color: #fff;
}

.dark-select :deep(.el-select__wrapper) {
  background-color: var(--sd-card);
  border-color: var(--sd-card-border);
  box-shadow: none;
}

.dark-select :deep(.el-select__placeholder),
.dark-select :deep(.el-select__selected-item) {
  color: #f1f5f9;
}

.cyan-btn {
  background: linear-gradient(135deg, #06b6d4, #0891b2) !important;
  border-color: #06b6d4 !important;
  color: #041018 !important;
}

.dark-table {
  --el-table-bg-color: transparent;
  --el-table-tr-bg-color: #111827;
  --el-table-header-bg-color: #1e293b;
  --el-table-border-color: #334155;
  --el-table-text-color: #cbd5e1;
  --el-table-header-text-color: #94a3b8;
  background: transparent !important;
  color: #cbd5e1;
}

.dark-table :deep(.el-table__inner-wrapper::before) {
  background-color: #334155;
}

@keyframes dash {
  to {
    stroke-dashoffset: -1000;
  }
}

@keyframes faultBlink {
  0%,
  100% {
    stroke: var(--sd-green);
  }
  50% {
    stroke: var(--sd-red);
  }
}

@keyframes flash {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.45;
  }
}

.animated-flash {
  animation: flash 1.5s infinite;
}

@media (max-width: 900px) {
  .main-content,
  .density-workbench {
    flex-direction: column;
    overflow-y: auto;
  }

  .data-sidebar,
  .guidance-panel {
    width: 100%;
    min-width: 0;
    max-width: none;
  }

  .control-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 760px) {
  .kpi-grid {
    grid-template-columns: 1fr;
  }

  .canvas-wrapper {
    min-height: 520px;
  }

  .process-svg {
    min-width: 980px;
  }
}
</style>



