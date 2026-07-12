<template>
  <div class="holodeck-shell">
    <!-- Top bar -->
    <header class="holo-header">
      <div class="holo-header-left">
        <div class="holo-header-accent"></div>
        <span class="holo-title">HOLODECK</span>
        <span class="holo-subtitle">// TACTICAL SYSTEMS</span>
      </div>
      <div class="holo-header-right">
        <span class="holo-status-dot"></span>
        <span class="holo-status-text">SYSTEMS ONLINE</span>
      </div>
    </header>

    <!-- Navigation -->
    <nav class="holo-nav">
      <router-link
        v-for="item in navItems"
        :key="item.path"
        :to="item.path"
        class="holo-nav-item"
        :class="{ active: $route.path === item.path }"
      >
        <span class="holo-nav-icon">{{ item.icon }}</span>
        <span class="holo-nav-label">{{ item.label }}</span>
      </router-link>
    </nav>

    <!-- Content -->
    <main class="holo-content">
      <router-view></router-view>
    </main>

    <!-- Bottom status bar -->
    <footer class="holo-footer">
      <span>STARDATE {{ stardate }}</span>
      <span>CONN: ENCRYPTED</span>
      <span>NODE: OPSTATION-01</span>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'HolodeckHome',
  data() {
    return {
      navItems: [
        { path: '/cloaking-device', label: 'Cloaking Device', icon: '◈' },
        { path: '/command-intercepter', label: 'Interceptor', icon: '⊛' },
        { path: '/command-sender', label: 'Command Tx', icon: '▷' },
        { path: '/ready-room', label: 'Ready Room', icon: '⌘' },
      ]
    };
  },
  computed: {
    stardate() {
      const now = new Date();
      const start = new Date(now.getFullYear(), 0, 0);
      const diff = now - start;
      const oneDay = 1000 * 60 * 60 * 24;
      const day = Math.floor(diff / oneDay);
      return `${now.getFullYear()}.${day.toString().padStart(3, '0')}`;
    }
  }
};
</script>

<style scoped>
.holodeck-shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

/* Header */
.holo-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background: linear-gradient(90deg, #111827 0%, #0a0e1a 100%);
  border-bottom: 1px solid var(--holo-border);
}

.holo-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.holo-header-accent {
  width: 4px;
  height: 28px;
  background: var(--holo-accent);
  border-radius: 2px;
}

.holo-title {
  font-family: 'Orbitron', sans-serif;
  font-weight: 900;
  font-size: 1.3rem;
  letter-spacing: 4px;
  color: var(--holo-accent);
}

.holo-subtitle {
  font-size: 0.7rem;
  color: var(--holo-text-dim);
  letter-spacing: 2px;
  text-transform: uppercase;
}

.holo-header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.holo-status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--holo-green);
  animation: pulse-dot 2s infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

.holo-status-text {
  font-size: 0.7rem;
  color: var(--holo-green);
  letter-spacing: 1px;
}

/* Navigation */
.holo-nav {
  display: flex;
  padding: 0 24px;
  gap: 2px;
  background: var(--holo-bg);
  border-bottom: 1px solid var(--holo-border);
}

.holo-nav-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  text-decoration: none;
  color: var(--holo-text-dim);
  font-family: 'Orbitron', sans-serif;
  font-size: 0.7rem;
  font-weight: 500;
  letter-spacing: 1px;
  text-transform: uppercase;
  border-bottom: 2px solid transparent;
  transition: all 0.2s;
}

.holo-nav-item:hover {
  color: var(--holo-text);
  background: rgba(56, 189, 248, 0.05);
}

.holo-nav-item.active {
  color: var(--holo-accent);
  border-bottom-color: var(--holo-accent);
  background: rgba(245, 158, 11, 0.05);
}

.holo-nav-icon {
  font-size: 1rem;
}

.holo-nav-label {
  white-space: nowrap;
}

/* Content */
.holo-content {
  flex: 1;
  padding: 24px;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
}

/* Footer */
.holo-footer {
  display: flex;
  justify-content: space-between;
  padding: 8px 24px;
  font-size: 0.65rem;
  color: var(--holo-text-dim);
  letter-spacing: 1px;
  text-transform: uppercase;
  border-top: 1px solid var(--holo-border);
  background: var(--holo-surface);
}
</style>
