<template>
  <div class="holo-panel">
    <div class="holo-panel-header">
      <h2 class="holo-panel-title">Command Interceptor</h2>
      <p class="holo-panel-desc">Man-in-the-middle capture — intercept ground commands, modify, and replay</p>
    </div>

    <div class="holo-grid">
      <!-- Control -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Intercept Mode</h5>
          <div class="holo-switch-row">
            <label class="holo-switch">
              <input type="checkbox" :checked="interceptorActivated" @change="toggleInterceptor" />
              <span class="holo-switch-slider"></span>
            </label>
            <span class="holo-switch-label" :class="{ active: interceptorActivated }">
              {{ interceptorActivated ? 'CAPTURING' : 'STANDBY' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Clear -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Buffer</h5>
          <p class="holo-metric-inline">
            <span class="holo-metric-value-sm">{{ interceptedCommands.length }}</span>
            <span class="holo-metric-label-sm">commands captured</span>
          </p>
          <button @click="clearInterceptedCommands()" class="btn btn-danger btn-sm">Purge Buffer</button>
        </div>
      </div>
    </div>

    <!-- Intercepted commands list -->
    <div class="card" v-if="currentStep === 1">
      <div class="card-body">
        <h5 class="card-title">Intercepted Commands</h5>
        <div v-if="interceptedCommands.length === 0" class="holo-empty-state">
          No commands intercepted yet
        </div>
        <ul v-else class="list-group">
          <li v-for="command in interceptedCommands" :key="command.id"
              class="list-group-item list-group-item-action"
              @click="selectCommand(command)">
            <span class="holo-cmd-target">{{ command['command'].target.name }}</span>
            <span class="holo-cmd-sep">//</span>
            <span class="holo-cmd-name">{{ command['command'].name }}</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- Command detail / replay -->
    <div class="card" v-if="currentStep === 2">
      <div class="card-body">
        <h5 class="card-title">Modify &amp; Replay</h5>
        <form @submit.prevent="submitCommand">
          <div v-if="interceptedCommandParameters.length === 0" class="holo-empty-state">
            No parameters available
          </div>
          <div v-for="param in interceptedCommandParameters" :key="param.name" class="mb-3">
            <label :for="param.name" class="form-label">{{ param.description }}</label>
            <input :disabled="param.description.startsWith('CCSDS')"
              type="text"
              class="form-control"
              :id="param.name"
              v-model="param.default"
            />
          </div>
          <div class="holo-actions">
            <button type="button" @click="deselectCommand" class="btn btn-secondary">← Back</button>
            <button type="submit" class="btn btn-primary">Forward Command ▷</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'CommandIntercepter',
  data() {
    return {
      interceptorActivated: false,
      interceptedCommands: [],
      interceptedCommandParameters: [],
      selectedTarget: null,
      selectedCommand: null,
      intervalId: null,
      currentStep: 1
    };
  },
  created() {
    this.setup();
  },
  beforeUnmount() {
    this.clearInterval();
  },
  methods: {
    async setup() {
      try {
        const response = await api.getInterceptorStatus();
        this.interceptorActivated = !(response.data.status === "Deactivated");
        if (this.interceptorActivated) this.startInterval();
      } catch (error) {
        console.error(error);
      }
    },
    async clearInterceptedCommands() {
      const response = await api.clearInterceptedCommands();
      this.interceptedCommands = [];
      alert(response.data.message);
    },
    async toggleInterceptor() {
      try {
        if (this.interceptorActivated) {
          await api.stopInterceptor();
          this.clearInterval();
        } else {
          await api.startInterceptor();
          this.startInterval();
        }
        this.interceptorActivated = !this.interceptorActivated;
      } catch (error) {
        alert(error);
      }
    },
    startInterval() {
      this.intervalId = setInterval(async () => {
        try {
          const response = await api.getInterceptedCommands();
          this.interceptedCommands = response.data;
        } catch (error) {
          console.error(error);
        }
      }, 5000);
    },
    clearInterval() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        this.intervalId = null;
      }
    },
    selectCommand(command) {
      this.selectedCommand = command;
      let joinedParams = [];
      for (let parameter of command.command.parameters) {
        for (let interceptedParameter of command.parameters) {
          if (parameter.id === interceptedParameter.base_parameter_id) {
            if (!parameter.name.includes("CCSDS")) {
              parameter.default = interceptedParameter.value;
            }
          }
        }
        joinedParams.push(parameter);
      }
      this.interceptedCommandParameters = joinedParams;
      this.selectedTarget = command.command.target;
      this.currentStep = 2;
    },
    deselectCommand() {
      this.selectedCommand = null;
      this.selectedTarget = null;
      this.currentStep = 1;
      this.interceptedCommandParameters = [];
    },
    async submitCommand() {
      try {
        await api.executeCommand(this.selectedTarget.id, this.selectedCommand.command.id, this.interceptedCommandParameters);
        alert('Command replayed');
        this.currentStep = 1;
      } catch (error) {
        console.error('Error replaying command:', error);
        alert('Replay failed');
        this.currentStep = 1;
      }
    }
  }
};
</script>

<style scoped>
.holo-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
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

.holo-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

@media (max-width: 768px) {
  .holo-grid { grid-template-columns: 1fr; }
}

.holo-switch-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 8px;
}

.holo-switch {
  position: relative;
  width: 48px;
  height: 24px;
}
.holo-switch input { opacity: 0; width: 0; height: 0; }
.holo-switch-slider {
  position: absolute;
  inset: 0;
  background: var(--holo-border);
  border-radius: 24px;
  cursor: pointer;
  transition: 0.3s;
}
.holo-switch-slider::before {
  content: '';
  position: absolute;
  width: 18px; height: 18px;
  left: 3px; bottom: 3px;
  background: var(--holo-text-dim);
  border-radius: 50%;
  transition: 0.3s;
}
.holo-switch input:checked + .holo-switch-slider { background: var(--holo-accent-dim); }
.holo-switch input:checked + .holo-switch-slider::before {
  transform: translateX(24px);
  background: var(--holo-accent);
}

.holo-switch-label {
  font-family: 'Orbitron', sans-serif;
  font-size: 0.7rem;
  letter-spacing: 1px;
  color: var(--holo-text-dim);
}
.holo-switch-label.active { color: var(--holo-accent); }

.holo-metric-inline {
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin: 8px 0;
}
.holo-metric-value-sm {
  font-family: 'Orbitron', sans-serif;
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--holo-blue);
}
.holo-metric-label-sm {
  font-size: 0.7rem;
  color: var(--holo-text-dim);
}

.holo-cmd-target {
  color: var(--holo-blue);
  font-weight: bold;
}
.holo-cmd-sep {
  color: var(--holo-text-dim);
  margin: 0 6px;
}
.holo-cmd-name {
  color: var(--holo-text);
}

.holo-empty-state {
  color: var(--holo-text-dim);
  font-style: italic;
  padding: 16px 0;
}

.holo-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--holo-border);
}
</style>
