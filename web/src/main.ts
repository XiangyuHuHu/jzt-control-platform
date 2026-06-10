import { createApp } from 'vue'
import App from './App.vue'
import './style.css'
import './styles/viewport-layout.css'
import './styles/coal-page-fixes.css'
import router from './router'
import { createPinia } from 'pinia'

const applyRouteTheme = (path: string) => {
  document.body.classList.toggle('coal-theme', path.startsWith('/jzt') || path.startsWith('/jzt/coal'))
}

applyRouteTheme(window.location.pathname)
router.afterEach((to) => {
  applyRouteTheme(to.path)
})

const app = createApp(App)
const pinia = createPinia()

app.use(router)
app.use(pinia)

app.mount('#app')
