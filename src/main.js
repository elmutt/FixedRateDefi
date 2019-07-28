import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import VueLogger from 'vuejs-logger';
import BlackDashboard from "./plugins/blackDashboard";

Vue.config.productionTip = false

//logging options
const isProduction = process.env.NODE_ENV === 'production';
const options = {
  isEnabled: true,
  logLevel : isProduction ? 'error' : 'debug',
  stringifyArguments : false,
  showLogLevel : true,
  showMethodName : true,
  separator: '|',
  showConsoleColors: true
};
Vue.config.productionTip = false

Vue.use(VueLogger, options);
Vue.use(BlackDashboard);

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
