<template>
  <div id="app" class="app-root" :class="{ 'app-root--coal': isCoalRoute }">
    <CoalGlobalNav v-if="showCoalNav" />
    <main class="app-main">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import CoalGlobalNav from './components/coal/CoalGlobalNav.vue'

const route = useRoute()
const isCoalRoute = computed(() => route.path.startsWith('/jzt') || route.path.startsWith('/jzt/coal'))
const isCoalHome = computed(() => route.path === '/jzt/coal')
const showCoalNav = computed(() => isCoalRoute.value && !isCoalHome.value)
</script>
