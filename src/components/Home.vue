<template>
  <div class="hello">
    <h1>{{ msg }}</h1>


    <p>Network: {{ network }}</p>
    <p>Account: {{ coinbase }}</p>
    <p>Balance: {{ balance }} Wei // {{ ethBalance }} Eth</p>

  </div>
</template>

<script>
  import {NETWORKS} from '../util/constants/networks'
  import {mapState} from 'vuex'

  export default {
    name: 'Home',
    props: {
      msg: String
    },
    components: {
      //VueMetamask,
    },
    data(){
      return {
        web3:"",
        msg2: "This is demo network",
        address:""
      }
    },
    computed: mapState({
      isInjected: state => state.web3.isInjected,
      network: state => NETWORKS[state.web3.networkId],
      coinbase: state => state.web3.coinbase,
      balance: state => state.web3.balance,
      ethBalance: state => {
        if (state.web3.web3Instance !== null) return state.web3.web3Instance().fromWei(state.web3.balance, 'ether')
      }
    }),
    beforeCreate () {
      console.log('registerWeb3 Action dispatched from Home')
      this.$store.dispatch('registerWeb3')
    },
    async mounted(){
      try{
          //

        }catch(e){
          this.$log.error("error: ",e)
      }
    },
    methods:{
      onComplete(data){
        console.log('data:', data);
        this.address = data.metaMaskAddress
        //this.web3 = data.web3

      },
      checkWeb3() {
        let web3 = window.web3;
        if (typeof web3 === 'undefined') {
          this.web3 = null;
          this.Log(this.MetamaskMsg.METAMASK_NOT_INSTALL, "NO_INSTALL_METAMASK");
        }
      },
      checkAccounts() {
        if (this.web3 === null) return;
        this.web3.eth.getAccounts((err, accounts) => {
          console.log();

          if (err != null) return this.Log(this.MetamaskMsg.NETWORK_ERROR, "NETWORK_ERROR");
          if (accounts.length === 0){
            this.MetaMaskAddress = "";
            this.Log(this.MetamaskMsg.EMPTY_METAMASK_ACCOUNT, 'NO_LOGIN');
            return;
          }
          this.MetaMaskAddress = accounts[0]; // user Address
        });
      },
    }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>
