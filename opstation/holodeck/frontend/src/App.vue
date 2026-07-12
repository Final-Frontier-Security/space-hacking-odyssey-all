<template>
  <div id="app">
    <HolodeckHome />
  </div>
</template>

<script>
import HolodeckHome from '@/views/HolodeckHome.vue';

export default {
  name: 'App',
  components: {
    HolodeckHome,
  },
};
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;700;900&family=Share+Tech+Mono&display=swap');

:root {
  --holo-bg: #0a0e1a;
  --holo-surface: #111827;
  --holo-border: #1e3a5f;
  --holo-accent: #fbbf24;
  --holo-accent-dim: #92400e;
  --holo-blue: #38bdf8;
  --holo-blue-dim: #0c4a6e;
  --holo-red: #ef4444;
  --holo-green: #22c55e;
  --holo-text: #e2e8f0;
  --holo-text-dim: #94a3b8;
  --holo-panel-radius: 2px;
}

* {
  box-sizing: border-box;
}

html, body {
  margin: 0;
  padding: 0;
  background-color: var(--holo-bg) !important;
  color: var(--holo-text);
  font-family: 'Share Tech Mono', monospace;
  min-height: 100vh;
}

#app {
  min-height: 100vh;
  background-color: var(--holo-bg);
}

/* Override Bootstrap dark cards */
.card {
  background-color: var(--holo-surface) !important;
  border: 1px solid var(--holo-border) !important;
  border-radius: var(--holo-panel-radius) !important;
  border-left: 3px solid var(--holo-accent) !important;
}

.card-title {
  font-family: 'Orbitron', sans-serif !important;
  font-weight: 700 !important;
  font-size: 0.9rem !important;
  text-transform: uppercase !important;
  letter-spacing: 1px !important;
  color: #fde68a !important;
}

.btn-primary {
  background-color: var(--holo-blue-dim) !important;
  border-color: var(--holo-blue) !important;
  color: var(--holo-blue) !important;
  font-family: 'Orbitron', sans-serif;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 1px;
  transition: all 0.2s;
}
.btn-primary:hover {
  background-color: var(--holo-blue) !important;
  color: var(--holo-bg) !important;
}

.btn-danger {
  background-color: transparent !important;
  border-color: var(--holo-red) !important;
  color: var(--holo-red) !important;
  font-family: 'Orbitron', sans-serif;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.btn-danger:hover {
  background-color: var(--holo-red) !important;
  color: #fff !important;
}

.btn-success {
  background-color: transparent !important;
  border-color: var(--holo-green) !important;
  color: var(--holo-green) !important;
  font-family: 'Orbitron', sans-serif;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.btn-success:hover {
  background-color: var(--holo-green) !important;
  color: var(--holo-bg) !important;
}

.btn-secondary {
  background-color: transparent !important;
  border-color: var(--holo-text-dim) !important;
  color: var(--holo-text-dim) !important;
  font-family: 'Orbitron', sans-serif;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.btn-secondary:hover {
  background-color: var(--holo-text-dim) !important;
  color: var(--holo-bg) !important;
}

.form-control {
  background-color: var(--holo-bg) !important;
  border: 1px solid var(--holo-border) !important;
  color: var(--holo-text) !important;
  font-family: 'Share Tech Mono', monospace;
  border-radius: var(--holo-panel-radius);
}
.form-control:focus {
  border-color: var(--holo-accent) !important;
  box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.15) !important;
}

.form-check-input:checked {
  background-color: var(--holo-accent) !important;
  border-color: var(--holo-accent) !important;
}

.list-group-item {
  background-color: var(--holo-surface) !important;
  border-color: var(--holo-border) !important;
  color: var(--holo-text) !important;
  font-family: 'Share Tech Mono', monospace;
  cursor: pointer;
  transition: all 0.15s;
}
.list-group-item:hover, .list-group-item-action:hover {
  background-color: var(--holo-blue-dim) !important;
  border-color: var(--holo-blue) !important;
  color: var(--holo-blue) !important;
}

.form-label {
  color: var(--holo-text);
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.modal-content {
  background-color: var(--holo-surface) !important;
  border: 1px solid var(--holo-red) !important;
  color: var(--holo-text);
}
.modal-header {
  border-bottom-color: var(--holo-border) !important;
}
.modal-footer {
  border-top-color: var(--holo-border) !important;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 6px;
}
::-webkit-scrollbar-track {
  background: var(--holo-bg);
}
::-webkit-scrollbar-thumb {
  background: var(--holo-border);
  border-radius: 3px;
}
::-webkit-scrollbar-thumb:hover {
  background: var(--holo-accent);
}
</style>
