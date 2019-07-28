<template>
  <div class="home">
    <img alt="Vue logo" src="../assets/logo.png" height="300pc" width="300">
    <Home msg="DeFi is coming"/>
  </div>
</template>

<script>
// @ is an alias to /src
import Home from '@/components/Home.vue'

export default {
  name: 'home',
  components: {
    Home
  }
}
</script>
