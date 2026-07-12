import { createStore } from 'vuex';

export default createStore({
  state: {
    exampleState: 'Hello Vuex!'
  },
  mutations: {
    setExampleState(state, payload) {
      state.exampleState = payload;
    }
  },
  actions: {
    updateExampleState({ commit }, payload) {
      commit('setExampleState', payload);
    }
  },
  getters: {
    exampleState: state => state.exampleState
  }
});
