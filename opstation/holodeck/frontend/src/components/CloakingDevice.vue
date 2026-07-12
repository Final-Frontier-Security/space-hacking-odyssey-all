<template>
  <div class="holo-panel">
    <div class="holo-panel-header">
      <h2 class="holo-panel-title">Cloaking Device</h2>
      <p class="holo-panel-desc">Telemetry replay attack — captures packets then loops them to mask real satellite state</p>
    </div>

    <div class="holo-grid">
      <!-- Control -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Engage Cloak</h5>
          <div class="holo-switch-row">
            <label class="holo-switch">
              <input type="checkbox" :checked="cloakActivated" @change="toggleCloak" />
              <span class="holo-switch-slider"></span>
            </label>
            <span class="holo-switch-label" :class="{ active: cloakActivated }">
              {{ cloakActivated ? 'ENGAGED' : 'DISENGAGED' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Status -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Cloak Status</h5>
          <div class="holo-status-indicator">
            <span class="holo-status-badge" :class="statusClass">
              {{ statusMessages[cloakStatus].message }}
            </span>
          </div>
          <div v-if="cloakActivated && cloakStatus === 'packet_collection'" class="holo-metric">
            <span class="holo-metric-value">{{ packetCount }}</span>
            <span class="holo-metric-label">packets captured</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'CloakingDevice',
  data() {
    return {
      cloakActivated: false,
      cloakStatus: "Deactivated",
      packetCount: 0,
      intervalId: null,
      statusMessages: {
        "Deactivated": { message: "Disengaged", class: "off" },
        "Activated": { message: "Engaged", class: "on" },
        "packet_collection": { message: "Capturing Packets", class: "collecting" },
        "sending_packets": { message: "Replaying Telemetry", class: "active" }
      }
    };
  },
  computed: {
    statusClass() {
      return this.statusMessages[this.cloakStatus]?.class || 'off';
    }
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
        const response = await api.getCloakStatus();
        this.cloakActivated = !(response.data.status === "Deactivated");
        this.packetCount = response.data.packet_count;
        if (this.cloakActivated) {
          this.startInterval();
        }
      } catch (error) {
        console.error(error);
      }
    },
    async toggleCloak() {
      try {
        if (this.cloakActivated) {
          const response = await api.deactivateCloak();
          this.clearInterval();
          this.cloakStatus = response.data.status;
        } else {
          const response = await api.activateCloak();
          this.startInterval();
          this.cloakStatus = response.data.status;
        }
        this.cloakActivated = !this.cloakActivated;
      } catch (error) {
        alert(error);
      }
    },
    startInterval() {
      this.intervalId = setInterval(async () => {
        try {
          const response = await api.getCloakStatus();
          this.cloakStatus = response.data.status;
          this.packetCount = response.data.packet_count;
        } catch (error) {
          console.error(error);
        }
      }, 2000);
    },
    clearInterval() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        this.intervalId = null;
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

.holo-panel-header {
  margin-bottom: 8px;
}

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

/* Custom switch */
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

.holo-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

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
  width: 18px;
  height: 18px;
  left: 3px;
  bottom: 3px;
  background: var(--holo-text-dim);
  border-radius: 50%;
  transition: 0.3s;
}

.holo-switch input:checked + .holo-switch-slider {
  background: var(--holo-accent-dim);
}

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

.holo-switch-label.active {
  color: var(--holo-accent);
}

/* Status */
.holo-status-indicator {
  margin-top: 8px;
}

.holo-status-badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 2px;
  font-family: 'Orbitron', sans-serif;
  font-size: 0.65rem;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.holo-status-badge.off {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid var(--holo-red);
  color: var(--holo-red);
}

.holo-status-badge.on,
.holo-status-badge.active {
  background: rgba(34, 197, 94, 0.1);
  border: 1px solid var(--holo-green);
  color: var(--holo-green);
}

.holo-status-badge.collecting {
  background: rgba(56, 189, 248, 0.1);
  border: 1px solid var(--holo-blue);
  color: var(--holo-blue);
  animation: pulse-badge 1.5s infinite;
}

@keyframes pulse-badge {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* Metrics */
.holo-metric {
  margin-top: 16px;
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.holo-metric-value {
  font-family: 'Orbitron', sans-serif;
  font-size: 2rem;
  font-weight: 700;
  color: var(--holo-blue);
}

.holo-metric-label {
  font-size: 0.7rem;
  color: var(--holo-text-dim);
  text-transform: uppercase;
  letter-spacing: 1px;
}
</style>
