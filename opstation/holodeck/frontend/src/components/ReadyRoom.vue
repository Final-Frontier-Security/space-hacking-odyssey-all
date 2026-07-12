<template>
  <div class="holo-panel">
    <div class="holo-panel-header">
      <h2 class="holo-panel-title">Ready Room</h2>
      <p class="holo-panel-desc">System configuration and command database management</p>
    </div>

    <div class="holo-grid">
      <!-- Settings -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Configuration</h5>
          <form @submit.prevent="saveSettings">
            <div class="mb-3" v-for="setting in settings" :key="setting.id">
              <label :for="`setting-${setting.id}`" class="form-label">{{ convertString(setting.name) }}</label>
              <input type="text" class="form-control" :id="`setting-${setting.id}`" :value="setting.value" />
            </div>
            <button type="submit" class="btn btn-primary">Save Config</button>
          </form>
        </div>
      </div>

      <!-- Commands -->
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Command Database</h5>
          <p class="holo-metric-inline">
            <span class="holo-metric-value-sm">{{ commandCount }}</span>
            <span class="holo-metric-label-sm">commands loaded</span>
          </p>

          <div class="holo-upload-section">
            <label class="form-label">Import Configuration</label>
            <div class="holo-upload-row">
              <input type="file" class="form-control" @change="handleFileChange" />
              <button type="button" class="btn btn-primary" :disabled="loading" @click="uploadFile">
                <span v-if="loading">...</span>
                <span v-else>Upload</span>
              </button>
            </div>
          </div>

          <div class="holo-danger-zone">
            <button type="button" class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#clearCommandsModal">
              Purge Database
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Clear confirmation modal -->
    <div class="modal fade" id="clearCommandsModal" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" style="font-family: 'Orbitron', sans-serif; font-size: 0.85rem; letter-spacing: 1px;">
              CONFIRM PURGE
            </h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            This will permanently remove all loaded command definitions. This action cannot be undone.
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" @click="clearCommands" class="btn btn-danger" data-bs-dismiss="modal">PURGE</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'ReadyRoom',
  data() {
    return {
      settings: [],
      commandCount: 0,
      file: null,
      loading: false
    };
  },
  created() {
    this.setup();
  },
  methods: {
    async setup() {
      try {
        this.updateCommandCount();
        const readyRoomResponse = await api.getReadyRoom();
        this.settings = readyRoomResponse.data;
      } catch (error) {
        console.error(error);
      }
    },
    async updateCommandCount() {
      const commandsResponse = await api.getCommandCount();
      this.commandCount = commandsResponse.data;
    },
    convertString(value) {
      value = value.split('_').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
      if (value.slice(-2) === 'Ip') value = value.slice(0, -2) + 'IP';
      return value;
    },
    async clearCommands() {
      try {
        const response = await api.deleteCOSMOSConfigs();
        alert(response.data);
        this.updateCommandCount();
      } catch (error) {
        console.error(error);
      }
    },
    handleFileChange(event) {
      this.file = event.target.files[0];
    },
    async uploadFile() {
      if (!this.file) {
        alert('Select a file first');
        return;
      }
      const configZip = new FormData();
      configZip.append('file', this.file);
      this.loading = true;
      try {
        const response = await api.uploadCOSMOSConfigZip(configZip);
        if (response.status === 200) {
          alert('Configuration uploaded');
          this.updateCommandCount();
        } else {
          alert('Upload failed');
        }
      } catch (error) {
        console.error('Error uploading:', error);
        alert('Upload error');
      } finally {
        this.loading = false;
      }
    },
    saveSettings() {
      alert('Settings saved');
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

.holo-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

@media (max-width: 768px) {
  .holo-grid { grid-template-columns: 1fr; }
}

.holo-metric-inline {
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin: 8px 0 16px;
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

.holo-upload-section {
  margin-bottom: 16px;
}

.holo-upload-row {
  display: flex;
  gap: 8px;
  align-items: center;
}

.holo-upload-row .form-control {
  flex: 1;
}

.holo-danger-zone {
  padding-top: 12px;
  border-top: 1px solid var(--holo-border);
}
</style>
