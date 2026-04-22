import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '../pages/HomePage.vue'
import SamplesPage from '../pages/SamplesPage.vue'
import ReviewsPage from '../pages/ReviewsPage.vue'
import ContactPage from '../pages/ContactPage.vue'

const routes = [
  { path: '/', name: 'home', component: HomePage },
  { path: '/samples', redirect: '/samples/dev' },
  { path: '/samples/:category(dev|editor)', name: 'samples', component: SamplesPage },
  { path: '/reviews', redirect: '/reviews/dev' },
  { path: '/reviews/:category(dev|editor)', name: 'reviews', component: ReviewsPage },
  { path: '/contact', name: 'contact', component: ContactPage }
]

export default createRouter({
  history: createWebHistory(),
  routes
})
