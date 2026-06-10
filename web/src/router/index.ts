import { createRouter, createWebHistory } from 'vue-router'

const extensionRoutes = [
  { path: '/jzt/coal/medium', name: 'CoalMedium', moduleKey: 'medium' },
  { path: '/jzt/coal/reagent', name: 'CoalReagent', moduleKey: 'reagent' },
  { path: '/jzt/coal/water', name: 'CoalWater', moduleKey: 'water' },
  { path: '/jzt/coal/power', name: 'CoalPower', moduleKey: 'power' },
  { path: '/jzt/coal/grease', name: 'CoalGrease', moduleKey: 'grease' },
  { path: '/jzt/coal/air', name: 'CoalAir', moduleKey: 'air' },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/jzt/coal',
    },
    {
      path: '/jzt/coal',
      name: 'CoalHome',
      component: () => import('../views/coal/Home.vue'),
    },
    {
      path: '/jzt',
      redirect: '/jzt/coal',
    },
    {
      path: '/jzt/jzt/:pathMatch(.*)*',
      redirect: (to) => {
        const raw = to.params.pathMatch
        const suffix = Array.isArray(raw) ? raw.join('/') : (raw as string | undefined) || ''
        return suffix ? `/jzt/${suffix}` : '/jzt/coal'
      },
    },
    {
      path: '/coal/:pathMatch(.*)*',
      redirect: (to) => {
        const raw = to.params.pathMatch
        const suffix = Array.isArray(raw) ? raw.join('/') : (raw as string | undefined) || ''
        return suffix ? `/jzt/coal/${suffix}` : '/jzt/coal'
      },
    },
    {
      path: '/login',
      name: 'Login',
      component: () => import('../views/Login.vue'),
    },
    {
      path: '/dashboard',
      name: 'Dashboard',
      component: () => import('../views/Dashboard.vue'),
      children: [
        { path: 'user', name: 'User', component: () => import('../views/User.vue') },
        { path: 'device', name: 'Device', component: () => import('../views/Device.vue') },
        { path: 'monitor', name: 'Monitor', component: () => import('../views/Monitor.vue') },
        { path: 'alarm', name: 'Alarm', component: () => import('../views/Alarm.vue') },
        { path: 'report', name: 'Report', component: () => import('../views/Report.vue') },
        { path: 'workorder', name: 'WorkOrder', component: () => import('../views/WorkOrder.vue') },
      ],
    },
    {
      path: '/jzt/coal/dashboard',
      name: 'CoalDashboard',
      component: () => import('../views/coal/Dashboard.vue'),
    },
    {
      path: '/jzt/coal/dashboard-screen',
      name: 'CoalDashboardScreen',
      component: () => import('../views/coal/DashboardScreen.vue'),
    },
    {
      path: '/jzt/coal/production',
      name: 'CoalProduction',
      component: () => import('../views/coal/Production.vue'),
    },
    {
      path: '/jzt/coal/production-operation',
      name: 'CoalProductionOperation',
      component: () => import('../views/coal/ProductionOperation.vue'),
    },
    {
      path: '/jzt/coal/process-flow',
      name: 'CoalProcessFlow',
      component: () => import('../views/coal/ProcessFlow.vue'),
    },
    {
      path: '/jzt/coal/safety-health',
      name: 'CoalSafetyHealth',
      component: () => import('../views/coal/SafetyHealth.vue'),
    },
    {
      path: '/jzt/coal/planning',
      name: 'CoalPlanning',
      component: () => import('../views/coal/Planning.vue'),
    },
    {
      path: '/jzt/coal/material-tracking',
      name: 'CoalMaterialTracking',
      component: () => import('../views/coal/MaterialTracking.vue'),
    },
    {
      path: '/jzt/coal/process-check',
      name: 'CoalProcessCheck',
      component: () => import('../views/coal/ProcessCheck.vue'),
    },
    {
      path: '/jzt/coal/equipment',
      name: 'CoalEquipment',
      component: () => import('../views/coal/Equipment.vue'),
    },
    {
      path: '/jzt/coal/equipment-screen',
      name: 'CoalEquipmentScreen',
      component: () => import('../views/coal/EquipmentScreen.vue'),
    },
    {
      path: '/jzt/coal/quality',
      name: 'CoalQuality',
      component: () => import('../views/coal/Quality.vue'),
    },
    {
      path: '/jzt/coal/quality-entry',
      name: 'CoalQualityEntry',
      component: () => import('../views/coal/QualityEntry.vue'),
    },
    {
      path: '/jzt/coal/storage',
      name: 'CoalStorage',
      component: () => import('../views/coal/Storage.vue'),
    },
    {
      path: '/jzt/coal/energy',
      name: 'CoalEnergy',
      component: () => import('../views/coal/Energy.vue'),
    },
    {
      path: '/jzt/coal/spare-parts',
      name: 'CoalSpareParts',
      component: () => import('../views/coal/SpareParts.vue'),
    },
    {
      path: '/jzt/coal/collaboration',
      name: 'CoalCollaboration',
      component: () => import('../views/coal/Collaboration.vue'),
    },
    {
      path: '/jzt/coal/energy-screen',
      name: 'CoalEnergyScreen',
      redirect: '/jzt/coal/energy',
    },
    {
      path: '/jzt/coal/report',
      name: 'CoalReport',
      component: () => import('../views/coal/Report.vue'),
    },
    {
      path: '/jzt/coal/settings',
      name: 'CoalSettings',
      component: () => import('../views/coal/Settings.vue'),
    },
    {
      path: '/jzt/coal/dispatch',
      name: 'CoalDispatch',
      component: () => import('../views/coal/Dispatch.vue'),
    },
    {
      path: '/jzt/coal/dispatch-log',
      name: 'CoalDispatchLog',
      component: () => import('../views/coal/DispatchLog.vue'),
    },
    {
      path: '/jzt/coal/decision',
      name: 'CoalDecision',
      component: () => import('../views/coal/Decision.vue'),
    },
    {
      path: '/jzt/coal/model-analysis',
      name: 'CoalModelAnalysis',
      component: () => import('../views/coal/ModelAnalysis.vue'),
    },
    {
      path: '/jzt/coal/monitor',
      name: 'CoalMonitor',
      component: () => import('../views/coal/Monitor.vue'),
    },
    {
      path: '/jzt/coal/data-governance',
      name: 'CoalDataGovernance',
      component: () => import('../views/coal/DataGovernance.vue'),
    },
    {
      path: '/jzt/coal/data-integration',
      name: 'CoalDataIntegration',
      component: () => import('../views/coal/DataIntegration.vue'),
    },
    {
      path: '/jzt/coal/data-access',
      name: 'CoalDataAccess',
      component: () => import('../views/coal/DataAccess.vue'),
    },
    {
      path: '/jzt/coal/sales',
      name: 'CoalSales',
      component: () => import('../views/coal/Sales.vue'),
    },
    {
      path: '/jzt/coal/quality-report',
      name: 'CoalQualityReport',
      component: () => import('../views/coal/QualityReportCenter.vue'),
    },
    {
      path: '/jzt/coal/mechanical',
      name: 'CoalMechanical',
      component: () => import('../views/coal/Mechanical.vue'),
    },
    {
      path: '/jzt/coal/smart-density',
      name: 'CoalSmartDensity',
      component: () => import('../views/coal/SmartDensity.vue'),
    },
    {
      path: '/jzt/coal/smart-reagent',
      name: 'CoalSmartReagent',
      component: () => import('../views/coal/SmartReagent.vue'),
    },
    {
      path: '/jzt/coal/shift-schedule',
      name: 'CoalShiftSchedule',
      component: () => import('../views/coal/ShiftSchedule.vue'),
    },
    ...extensionRoutes.map((item) => ({
      path: item.path,
      name: item.name,
      component: () => import('../views/coal/ExtensionModulePage.vue'),
      meta: { moduleKey: item.moduleKey },
    })),
  ],
})

export default router
