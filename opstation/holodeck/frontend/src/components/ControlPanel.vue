<template>
  <div class="holo-panel">
    <div class="holo-panel-header">
      <h2 class="holo-panel-title">Control Panel</h2>
      <p class="holo-panel-desc">Direct system operations</p>
    </div>

    <div class="card">
      <div class="card-body">
        <h5 class="card-title">Operations</h5>
        <div class="holo-btn-grid">
          <button disabled class="btn btn-primary" @click="deployBackdoor">Deploy Backdoor</button>
          <button disabled class="btn btn-secondary" @click="downlink">Downlink</button>
          <button class="btn btn-danger" @click="kill42">Stop Simulation</button>
          <button class="btn btn-success" @click="start42">Start Simulation</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'ControlPanel',
  methods: {
    deployBackdoor() {
      this.executeCommand("scp -o StrictHostKeyChecking=no -i /home/Operator/.ssh/groundstation.pem /home/Operator/Desktop/backdoor/backdoor.so ubuntu@moonlighter.spacevehicle.space:/opt/nos3/fsw/build/exe/cpu1/cf/backdoor.so");
    },
    downlink() {
      this.executeCommand("scp -o StrictHostKeyChecking=no -i /home/Operator/.ssh/groundstation.pem ubuntu@moonlighter.spacevehicle.space:/opt/nos3/fsw/build/exe/cpu1/data/*.txt /home/Operator/Desktop/havoc/downlink/");
    },
    kill42() {
      this.executeCommand("docker stop $(docker ps -a -q)");
    },
    start42() {
      this.executeCommand("/home/Operator/Desktop/42-start.sh");
    },
    async executeCommand(command) {
      try {
        await api.executeShellCommand(command);
        alert('Command executed');
      } catch (error) {
        console.error('Error:', error);
        alert('Execution failed');
      }
    }
  }
}
</script>

<style scoped>
.holo-panel {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.holo-panel-header { margin-bottom: 8px; }
.holo-panel-title {
  font-family: 'Orbitron', sans-serif;
  font-weight: 700;
  font-size: 1.1rem;
  color: var(--holo-text);
  letter-spacing: 2px;
  text-transform: uppercase;
  margin: 0;
}
.holo-panel-desc {
  font-size: 0.8rem;
  color: var(--holo-text-dim);
  margin: 4px 0 0;
}
.holo-btn-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 12px;
}
</style>
