import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'http://localhost:5001/api',
  withCredentials: false, // This is the default
  headers: {
    Accept: 'application/json'
  }
});

export default {
  getTargets() {
    return apiClient.get('/target');
  },
  getTarget(target_id) {
    return apiClient.get('/target/' + target_id);
  },
  getTargetCommand(target_id, command_id) {
    return apiClient.get('/target/' + target_id + '/command/' + command_id);
  },
  executeCommand(target_id, command_id, parameters) {
    return apiClient.post('/target/' + target_id + '/command/' + command_id + '/execute', parameters);
  },
  startInterceptor() {
    return apiClient.post('/interceptor/start');
  },
  stopInterceptor() {
    return apiClient.post('/interceptor/stop');
  },
  getInterceptorStatus() {
    return apiClient.get('/interceptor/status');
  },
  getInterceptedCommands() {
    return apiClient.get('/interceptor/command');
  },
  getInterceptedCommand(intercepted_command_id) {
    return apiClient.get('/interceptor/command/' + intercepted_command_id);
  },
  clearInterceptedCommands() {
    return apiClient.post('/interceptor/clear');
  },
  getCloakStatus() {
    return apiClient.get('/cloak');
  },
  activateCloak() {
    return apiClient.post('/cloak/activate');
  },
  deactivateCloak() {
    return apiClient.post('/cloak/deactivate');
  },
  getReadyRoom() {
    return apiClient.get('/readyroom');
  },
  updateReadyRoom(config) {
    return apiClient.post('/readyroom/target', config);
  },
  uploadCOSMOSConfigZip(configs) {
    return apiClient.post('/readyroom/cosmos/upload', configs, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
  },
  deleteCOSMOSConfigs() {
    return apiClient.delete('/readyroom/cosmos');
  },
  getCommandCount() {
    return apiClient.get('/readyroom/command/count');
  }
};
