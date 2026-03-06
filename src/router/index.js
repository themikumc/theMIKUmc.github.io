import { createRouter, createWebHashHistory } from 'vue-router'
import HomePage from '../pages/HomePage.vue'
import SamplesPage from '../pages/SamplesPage.vue'
import ReviewsPage from '../pages/ReviewsPage.vue'
import ContactPage from '../pages/ContactPage.vue'

const routes = [
  { path: '/', name: 'home', component: HomePage },
  { path: '/samples', name: 'samples', component: SamplesPage },
  { path: '/reviews', name: 'reviews', component: ReviewsPage },
  { path: '/contact', name: 'contact', component: ContactPage }
]

export default createRouter({
  history: createWebHashHistory(),
  routes
})
