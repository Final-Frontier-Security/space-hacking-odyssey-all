import { createRouter, createWebHistory } from 'vue-router';
import CloakingDevice from '@/components/CloakingDevice.vue';
import CommandIntercepter from '@/components/CommandIntercepter.vue';
import CommandSender from '@/components/CommandSender.vue';
import ReadyRoom from '@/components/ReadyRoom.vue';

const routes = [
  {
    path: '/',
    redirect: '/command-sender'
  },
  {
    path: '/cloaking-device',
    name: 'CloakingDevice',
    component: CloakingDevice
  },
  {
    path: '/command-intercepter',
    name: 'CommandIntercepter',
    component: CommandIntercepter
  },
  {
    path: '/command-sender',
    name: 'CommandSender',
    component: CommandSender
  },
  {
    path: '/ready-room',
    name: 'ReadyRoom',
    component: ReadyRoom
  }
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
});

export default router;
