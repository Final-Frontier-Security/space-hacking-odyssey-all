<template>
  <div class="holo-panel">
    <div class="holo-panel-header">
      <h2 class="holo-panel-title">Command Transmitter</h2>
      <p class="holo-panel-desc">Direct command injection — send arbitrary commands to the satellite bus</p>
    </div>

    <div class="card">
      <div class="card-body">
        <div class="holo-step-indicator">
          <span v-for="(heading, idx) in headings" :key="idx"
                class="holo-step"
                :class="{ active: currentStep === idx + 1, completed: currentStep > idx + 1 }">
            {{ idx + 1 }}. {{ heading }}
          </span>
        </div>

        <form @submit.prevent="handleSubmit">
          <!-- Step 1: Target -->
          <div v-if="currentStep === 1" class="holo-step-content">
            <ul class="list-group">
              <li v-for="target in targets" :key="target.id"
                  class="list-group-item list-group-item-action"
                  @click="selectTarget(target)">
                {{ target.name }}
              </li>
            </ul>
          </div>

          <!-- Step 2: Command -->
          <div v-if="currentStep === 2" class="holo-step-content">
            <ul class="list-group">
              <li v-for="command in commands" :key="command.id"
                  class="list-group-item list-group-item-action"
                  @click="selectCommand(command)">
                {{ command.name }}
              </li>
            </ul>
            <button type="button" class="btn btn-secondary mt-3" @click="prevStep">← Back</button>
          </div>

          <!-- Step 3: Parameters -->
          <div v-if="currentStep === 3" class="holo-step-content">
            <div v-if="parameters.length === 0" class="holo-empty-state">
              No parameters required
            </div>
            <div v-for="param in parameters" :key="param.name" class="mb-3">
              <label :for="param.name" class="form-label">{{ param.description }}</label>
              <input :disabled="param.description.startsWith('CCSDS')"
                type="text"
                class="form-control"
                :id="param.name"
                v-model="param.default"
              />
            </div>
            <div class="holo-actions">
              <button type="button" class="btn btn-secondary" @click="prevStep">← Back</button>
              <button type="submit" class="btn btn-primary" @click="submitCommand">Transmit ▷</button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'CommandSender',
  data() {
    return {
      currentStep: 1,
      headings: ['Target', 'Command', 'Parameters'],
      targets: [],
      commands: [],
      parameters: [],
      selectedTarget: null,
      selectedCommand: null
    };
  },
  async created() {
    await this.fetchTargets();
  },
  methods: {
    async fetchTargets() {
      try {
        const response = await api.getTargets();
        this.targets = response.data;
      } catch (error) {
        console.error('Error fetching targets:', error);
      }
    },
    selectTarget(target) {
      this.selectedTarget = target;
      this.commands = this.selectedTarget.commands;
      this.nextStep();
    },
    selectCommand(command) {
      this.selectedCommand = command;
      this.parameters = command.parameters;
      this.nextStep();
    },
    nextStep() {
      if (this.currentStep < 3) this.currentStep++;
    },
    prevStep() {
      if (this.currentStep > 1) this.currentStep--;
    },
    async submitCommand() {
      try {
        await api.executeCommand(this.selectedTarget.id, this.selectedCommand.id, this.parameters);
        alert('Command transmitted');
        this.currentStep = 1;
      } catch (error) {
        console.error('Error sending command:', error);
        alert('Transmission failed');
      }
    }
  }
};
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

.holo-step-indicator {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--holo-border);
}

.holo-step {
  font-family: 'Orbitron', sans-serif;
  font-size: 0.65rem;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: var(--holo-text-dim);
  padding: 4px 8px;
  border-radius: 2px;
}

.holo-step.active {
  color: var(--holo-accent);
  background: rgba(245, 158, 11, 0.1);
  border: 1px solid var(--holo-accent-dim);
}

.holo-step.completed {
  color: var(--holo-green);
}

.holo-step-content {
  min-height: 200px;
}

.holo-empty-state {
  color: var(--holo-text-dim);
  font-style: italic;
  padding: 20px 0;
}

.holo-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--holo-border);
}
</style>
