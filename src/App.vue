<template>
  <div class="min-h-screen bg-black text-white antialiased">
    <div class="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-5 py-6 sm:px-8">
      <header class="nav-shell mb-10 border-b border-line pb-6">
        <nav class="flex items-center justify-between text-base lowercase tracking-wide text-soft sm:text-lg">
          <span class="text-xl font-semibold text-white sm:text-2xl">miku</span>
          <div class="flex items-center gap-8 sm:gap-10">
            <router-link to="/" class="inline-flex items-center gap-2 transition-colors duration-300 ease-out hover:text-cyan-300" active-class="text-cyan-300">
              <svg viewBox="0 0 24 24" class="icon-pack icon-nav" aria-hidden="true">
                <path d="M3 11.5 12 4l9 7.5"/>
                <path d="M5 10.5V20h14v-9.5"/>
              </svg>
              home
            </router-link>
            <router-link to="/contact" class="inline-flex items-center gap-2 transition-colors duration-300 ease-out hover:text-cyan-300" active-class="text-cyan-300">
              <svg viewBox="0 0 24 24" class="icon-pack icon-nav" aria-hidden="true">
                <rect x="3" y="5" width="18" height="14" rx="2"/>
                <path d="m3 7 9 6 9-6"/>
              </svg>
              contact
            </router-link>
            <router-link to="/samples" class="inline-flex items-center gap-2 transition-colors duration-300 ease-out hover:text-cyan-300" active-class="text-cyan-300">
              <svg viewBox="0 0 24 24" class="icon-pack icon-nav" aria-hidden="true">
                <path d="M3 8a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
              </svg>
              samples
            </router-link>
            <router-link to="/reviews" class="inline-flex items-center gap-2 transition-colors duration-300 ease-out hover:text-cyan-300" active-class="text-cyan-300">
              <svg viewBox="0 0 24 24" class="icon-pack icon-nav" aria-hidden="true">
                <path d="m12 3 2.6 5.3 5.9.9-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.9z"/>
              </svg>
              reviews
            </router-link>
          </div>
        </nav>
      </header>

      <main class="flex-1">
        <router-view v-slot="{ Component }">
          <component v-if="!transitionsReady" :is="Component" />
          <Transition v-else name="page-swap" mode="out-in">
            <component :is="Component" :key="route.fullPath" />
          </Transition>
        </router-view>
      </main>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'

const transitionsReady = ref(false)
const route = useRoute()

onMounted(() => {
  transitionsReady.value = true
})
</script>
