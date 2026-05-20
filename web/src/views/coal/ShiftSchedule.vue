<template>
  <div class="shift-page">
    <section class="page-hero">
      <div>
        <p class="eyebrow">排班管理</p>
        <h1>二班倒与检修班配置</h1>
        <p>默认二班倒：一班生产、二班生产、检修班不计生产计划；切换三班倒时允许其中一班生产计划为 0。</p>
      </div>
      <el-radio-group v-model="mode">
        <el-radio-button label="二班倒" />
        <el-radio-button label="三班倒" />
      </el-radio-group>
    </section>

    <section class="panel">
      <el-table :data="rows">
        <el-table-column prop="team" label="班组" width="120" />
        <el-table-column prop="role" label="类型" width="120" />
        <el-table-column prop="time" label="时间" width="180" />
        <el-table-column prop="production" label="是否生产班" width="130" />
        <el-table-column prop="plan" label="生产计划(吨)" width="150" />
        <el-table-column prop="remark" label="说明" />
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
const mode = ref('二班倒')
const rows = computed(() => mode.value === '二班倒'
  ? [
      { team: '一班', role: '生产班', time: '08:00-20:00', production: '是', plan: 12600, remark: '白班生产' },
      { team: '二班', role: '生产班', time: '20:00-08:00', production: '是', plan: 12600, remark: '夜班生产' },
      { team: '检修班', role: '检修班', time: '08:00-17:30', production: '否', plan: 0, remark: '设备检修和保养' },
    ]
  : [
      { team: '一班', role: '生产班', time: '08:00-16:00', production: '是', plan: 8400, remark: '早班生产' },
      { team: '二班', role: '生产班', time: '16:00-00:00', production: '是', plan: 8400, remark: '中班生产' },
      { team: '三班', role: '备用/检修', time: '00:00-08:00', production: '否', plan: 0, remark: '计划为 0，可用于检修' },
    ])
</script>

<style scoped>
.shift-page{min-height:100vh;padding:92px 20px 28px;background:#16202a;color:#eef6ff}.page-hero,.panel{width:min(100%,1680px);margin:0 auto 16px;border:1px solid rgba(169,202,232,.18);border-radius:10px;background:#202c38;box-shadow:0 16px 36px rgba(0,0,0,.18)}.page-hero{display:flex;justify-content:space-between;gap:20px;padding:26px 30px}.eyebrow{margin:0 0 8px;color:#8bdfff}.page-hero h1{margin:0}.page-hero p{color:#c8d6e3}.panel{padding:22px}@media(max-width:900px){.shift-page{padding-top:24px}.page-hero{flex-direction:column}}
</style>
