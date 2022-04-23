<template>
  <div id="app">
    <el-container
        v-loading="loading"
        element-loading-text="正在链接区块，请稍后"
        element-loading-spinner="el-icon-loading"
        element-loading-background="rgba(0, 0, 0, 0.8)">
      <el-header style="background-color:#00FFFF;">
        <el-button type="warning" round @click="linkAccount()">{{ linkMessage() }}</el-button>
      </el-header>
      <el-main v-if="!loading">
        <el-row>
          <el-col :span="24">
            <div>
              <h1>哈希选奖（币安测试网）</h1>
              <p>每个回合分为四个阶段，未开启阶段，开启阶段，停止投注等待开奖阶段，结束阶段</p>
              <p>在每个回合的开启阶段玩家可以下注，每次的下注额度为{{ betFee }}BNB</p>
              <p>在每个回合最多下注{{ maxPlayersOneTurn }}人次，可重复下注</p>
              <p>在每个回合下注人次满后立刻跨过等待开奖阶段立即开奖，<br>利用标准hash算法得出hash值然后按下注数取余算出中奖人是谁</p>
              <p>或者在每个回合下注人次未满时，由管理员控制进入停止头猪等待开奖阶段</p>
              <p>如果再停止下注等待开奖阶段，则任何人可以控制开奖</p>
              <p>在每个回合中奖人出现后将奖池中的所有金额给予中奖人（扣除管理费用{{ loudFee }}%）</p>
              <p>在每个回合开奖之后立刻进入结束阶段，并且新的回合由未开启阶段进入开启阶段</p>
            </div>
          </el-col>

        </el-row>
        <el-row v-for="(oneTurn,index) in allTurnsData " :key="index">
          <el-col style="background-color:#66CCFF;">
            <h3>第{{ allTurnsData.length - index }}回合（当前阶段：{{ actionsToMessage(oneTurn.action) }}）</h3>
            <el-col :span="12" style="background-color:#9999FF;">
              <div>
                <h5>玩家下注工具</h5>
                <el-button @click="bet(allTurnsData.length- index-1)" v-if="oneTurn.action===1">下注</el-button>
                <el-button @click="openAward()" v-if="oneTurn.action===2">开奖</el-button>
              </div>
            </el-col>
            <el-col :span="12" style="background-color:#CC99FF;">
              <div>
                <h5>管理员工具</h5>
                <el-button @click="overBet(allTurnsData.length- index-1)" v-if="oneTurn.action===1">结束下注阶段</el-button>
              </div>
            </el-col>
            <el-col>
              <p>开奖hash：{{ oneTurn.hash }}</p>
              <p>参与玩家地址：</p>
              <p v-for="(player,indexz) in oneTurn.players" :key="indexz">id:{{ indexz }} ,address:{{ player }}</p>
              <p>总奖金池：{{ oneTurn.totalPool }}</p>
              <p v-if="oneTurn.winner!=='0x0000000000000000000000000000000000000000'">中奖玩家：id:{{
                  oneTurn.winerId
                }}，address:{{ oneTurn.winner }}</p>
            </el-col>
          </el-col>
        </el-row>
      </el-main>
      <el-footer>

      </el-footer>
    </el-container>
  </div>
</template>

<script>
import {ethers} from "ethers";
import {abi} from './abis'

export default {
  name: 'app',
  data() {
    return {
      account: '',
      testChainId: '0x61',
      betFee: 0,
      maxPlayersOneTurn: 0,
      loudFee: 0,
      nowTurn: 0,
      manager: '',
      allTurnsData: [],
      allTurnsDataDeas: [],
      turn: 0,
      contractAddress: '0x6a427637528da0ca9a894ecc29ebd820a8d694f4',
      rpc: 'https://data-seed-prebsc-2-s3.binance.org:8545/',
      loading: 1
    }
  },
  components: {},
  async mounted() {
    this.loading = 0;
    this.getHashAwardAllDataNew();
    const that = this;
    setInterval(function () {
      that.getHashAwardAllDataNew()
    }, 3000);
  },
  methods: {
    deasData() {
      let deasdata = [];
      for (let i = this.allTurnsData.length; i >= 0; i--) {
        deasdata.push(this.allTurnsData[i])
      }
      return deasdata;
    },
    async bet(turn) {
      if (!this.checkAccount()) {
        return;
      }
      if (!this.checkChainId()) {
        return;
      }

      try {
        const Provider = await new ethers.providers.Web3Provider(window.ethereum)
        const signer = Provider.getSigner()
        const Contract = await new ethers.Contract(this.contractAddress, abi, signer);
        const tx = await Contract.bet(turn, {
          value: Contract.oneBetFee(),
          gasLimit: 200000,
          gasPrice: await Provider.getGasPrice()
        })
        const waitData = await tx.wait();
        console.log(waitData)
        if (waitData.status === 1) {
          this.$message({
            message: '下注成功！',
            type: 'success'
          });
        } else {
          this.$message({
            message: '下注失败请检查数据是否正确',
            type: 'warning'
          });
        }
      } catch (e) {
        this.$message({
          message: '下注失败请检查数据是否正确',
          type: 'warning'
        });
      }

    },
    async openAward() {
      if (!this.checkAccount()) {
        return;
      }
      if (!this.checkChainId()) {
        return;
      }
      try {
        const Provider = await new ethers.providers.Web3Provider(window.ethereum)
        const signer = Provider.getSigner()
        const Contract = await new ethers.Contract(this.contractAddress, abi, signer);
        const tx = await Contract.openAward({
          gasLimit: 200000,
          gasPrice: await Provider.getGasPrice()
        })
        const waitData = await tx.wait();
        if (waitData.status === 1) {
          this.$message({
            message: '开奖成功！',
            type: 'success'
          });
        } else {
          this.$message({
            message: '开奖失败请检查数据是否正确',
            type: 'warning'
          });
        }
      } catch (e) {
        this.$message({
          message: '开奖失败请检查数据是否正确',
          type: 'warning'
        });
      }
    },
    async overBet(turn) {
      if (!this.checkAccount()) {
        return;
      }
      if (!this.checkManager()) {
        return;
      }
      if (!this.checkChainId()) {
        return;
      }
      try {
        const Provider = await new ethers.providers.Web3Provider(window.ethereum)
        const signer = Provider.getSigner()
        const Contract = await new ethers.Contract(this.contractAddress, abi, signer);
        const tx = await Contract.overBet(turn, {
          gasLimit: 200000,
          gasPrice: await Provider.getGasPrice()
        })
        const waitData = await tx.wait();
        if (waitData.status === 1) {
          this.$message({
            message: '结束下注阶段成功！',
            type: 'success'
          });
        } else {
          this.$message({
            message: '结束下注阶段失败请检查数据是否正确',
            type: 'warning'
          });
        }
      } catch (e) {
        this.$message({
          message: '结束下注阶段失败请检查数据是否正确',
          type: 'warning'
        });
        console.log(e);
      }
    },


    //todo 实际上可以不需要一次加载那么多数据甚至应该在服务器缓存直接读取服务器数据或者改用异步
    async getHashAwardAllData() {
      try {
        const Provider = await new ethers.providers.JsonRpcProvider(this.rpc);
        const Contract = await new ethers.Contract(this.contractAddress, abi, Provider);
        this.betFee = ethers.utils.formatEther(await Contract.oneBetFee());
        this.maxPlayersOneTurn = await Contract.maxPlayersOneTurn();
        this.loudFee = await Contract.loudFee100();
        this.nowTurn = await Contract.nowTurn();
        this.manager = await Contract.manager();
        this.maxPlayersOneTurn = await Contract.maxPlayersOneTurn();
        this.pauseData = await Contract.pauseData();
        for (let i = this.nowTurn; i >= 0; i--) {
          let oneTurnsData = {};
          oneTurnsData.action = await Contract.turnsActions(i);
          oneTurnsData.players = await Contract.getOneturnsPlayers(i);
          oneTurnsData.winner = await Contract.turnsWinner(i);
          oneTurnsData.hash = (await Contract.turnsHash(i)).toHexString();
          oneTurnsData.totalPool = ethers.utils.formatEther(await Contract.turnsTotalPool(i));
          oneTurnsData.winerId = await Contract.turnsWainnerId(i);
          if (oneTurnsData.action === 1) {
            oneTurnsData.canBet = 1;
          } else {
            oneTurnsData.canBet = 0;
          }
          this.allTurnsData[this.nowTurn - i] = oneTurnsData;
        }
        // this.loading = 0;
      } catch (e) {
        console.log(e)
      }
    },
    //改用异步
    getHashAwardAllDataNew() {
      const Provider = new ethers.providers.JsonRpcProvider(this.rpc);
      const Contract = new ethers.Contract(this.contractAddress, abi, Provider);
      const that = this;
      Contract.nowTurn().then(function (nowTurn) {
        that.nowTurn = nowTurn
        Contract.oneBetFee().then(function (betFee) {
          that.betFee = ethers.utils.formatEther(betFee)
        })
        Contract.maxPlayersOneTurn().then(function (maxPlayersOneTurn) {
          that.maxPlayersOneTurn = maxPlayersOneTurn
        })
        Contract.loudFee100().then(function (loudFee) {
          that.loudFee = loudFee
        })
        Contract.manager().then(function (manager) {
          that.manager = manager
        })
        Contract.maxPlayersOneTurn().then(function (maxPlayersOneTurn) {
          that.maxPlayersOneTurn = maxPlayersOneTurn
        })
        Contract.pauseData().then(function (pauseData) {
          that.pauseData = pauseData
        })
        for (let i = that.nowTurn; i >= 0; i--) {
          if (!that.allTurnsData[that.nowTurn - i]) {
            that.allTurnsData[that.nowTurn - i] = {};
          }
          Contract.turnsActions(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].action = res
          })
          Contract.getOneturnsPlayers(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].players = res
          })
          Contract.turnsWinner(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].winner = res
          })
          Contract.turnsHash(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].hash = res.toHexString()
          })
          Contract.turnsTotalPool(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].totalPool = ethers.utils.formatEther(res)
          })
          Contract.turnsWainnerId(i).then(function (res) {
            that.allTurnsData[that.nowTurn - i].winerId = res
          })
        }


      });
    },


    actionsToMessage: function (actionId) {
      const messages = [
        '未开启阶段',
        '开启阶段（可以投注）',
        '投注结束，等待开奖阶段',
        '已结束阶段'
      ]
      return messages[actionId];
    },
    linkMessage: function () {
      return this.account ? this.account : '链接钱包'
    },
    linkAccount: async function () {
      if (typeof window.ethereum !== 'undefined') {
        console.log('MetaMask is installed!');
        this.account = (await window.ethereum.request({method: 'eth_requestAccounts'}))[0];
        console.log(this.account)
        this.checkChainId()
      } else {
        this.$message({
          message: '您还没有安装MetaMask,请先安装小狐狸之后再试',
          type: 'warning'
        });
      }
    },
    checkChainId: function () {
      console.log(window.ethereum.chainId)
      if (this.testChainId !== window.ethereum.chainId) {
        this.$message({
          message: '请切换到币安测试链，链id：0x61',
          type: 'warning'
        });
        return false
      }
      return true;
    },
    checkAccount: function () {

      if (!this.account) {
        this.$message({
          message: '请先链接钱包',
          type: 'warning'
        });
        return false
      }
      return true;
    },
    checkManager: function () {
      if (this.account.toUpperCase() !== this.manager.toUpperCase()) {

        this.$message({
          message: '您不是管理员没有权限操作',
          type: 'warning'
        });
        return false;
      }
      return true;
    }
  },
}
</script>

<style>
body {
  margin: 0;
  padding: 0;
}

#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;

}
</style>
