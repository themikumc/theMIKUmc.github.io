<template>
  <section class="h-[calc(100dvh-11rem)] overflow-hidden md:h-[calc(100dvh-12rem)]">
    <div
      ref="heroEl"
      class="hero-grid flex min-h-[calc(100vh-11rem)] flex-col items-center justify-center gap-4 text-center transition-transform duration-75 ease-out will-change-transform md:min-h-[calc(100vh-12rem)]"
      :class="{ 'hero-grid-active': heroGridActive }"
      :style="heroFollowStyle"
      @mousemove="onHeroMove"
      @mouseleave="onHeroLeave"
    >
      <div class="avatar-aura rise-1">
        <img
          src="/pfp.png"
          alt="theMIKUmc profile picture"
          class="h-32 w-32 rounded-full border border-line object-cover object-top"
        />
      </div>
      <h1 class="name-fluid name-enter text-5xl font-semibold tracking-tight sm:text-7xl">theMIKUmc</h1>
      <div class="divider-wrap divider-grow self-center">
        <div class="divider-line divider-flow h-px"></div>
      </div>
      <p class="rise-3 bright-cyan-text text-base font-semibold lowercase tracking-[0.35em] sm:text-lg">dev</p>
      <router-link
        to="/contact"
        class="rise-4 relative z-10 mt-6 border border-cyan-300/70 bg-[#0a2b38] px-6 py-2 text-sm font-semibold lowercase tracking-[0.18em] !text-white transition-colors duration-300 hover:bg-[#0f3b4c] hover:!text-white sm:text-base"
      >
        contact me
      </router-link>
    </div>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const heroEl = ref(null)
const heroGridActive = ref(false)
const heroX = ref(0)
const heroY = ref(0)
const heroTargetX = ref(0)
const heroTargetY = ref(0)
const smoothScrollY = ref(0)
const targetScrollY = ref(0)
let motionRaf = 0
let prevHtmlOverflowY = ''
let prevBodyOverflowY = ''

const heroFollowStyle = computed(() => ({
  '--grid-parallax': `${smoothScrollY.value * 0.42}px`,
  transform: `translate3d(${heroX.value}px, ${heroY.value + smoothScrollY.value * 0.36}px, 0)`
}))

const updateHeroGridLight = (clientX, clientY) => {
  if (!heroEl.value) return
  const rect = heroEl.value.getBoundingClientRect()
  const px = ((clientX - rect.left) / rect.width) * 100
  const py = ((clientY - rect.top) / rect.height) * 100
  heroEl.value.style.setProperty('--mx', `${px}%`)
  heroEl.value.style.setProperty('--my', `${py}%`)
}

const onHeroMove = (event) => {
  if (!heroEl.value) return
  const rect = heroEl.value.getBoundingClientRect()
  const nx = (event.clientX - rect.left) / rect.width - 0.5
  const ny = (event.clientY - rect.top) / rect.height - 0.5
  updateHeroGridLight(event.clientX, event.clientY)
  heroTargetX.value = nx * 6
  heroTargetY.value = ny * 5
}

const onHeroLeave = () => {
  heroTargetX.value = 0
  heroTargetY.value = 0
}

const onWindowPointerMove = (event) => {
  heroGridActive.value = true
  updateHeroGridLight(event.clientX, event.clientY)
}

const onWindowPointerLeave = () => {
  heroGridActive.value = false
}

const onWindowScroll = () => {
  targetScrollY.value = window.scrollY || 0
}

const smoothStep = () => {
  heroX.value += (heroTargetX.value - heroX.value) * 0.18
  heroY.value += (heroTargetY.value - heroY.value) * 0.18
  smoothScrollY.value += (targetScrollY.value - smoothScrollY.value) * 0.08
  motionRaf = requestAnimationFrame(smoothStep)
}

onMounted(() => {
  prevHtmlOverflowY = document.documentElement.style.overflowY
  prevBodyOverflowY = document.body.style.overflowY
  document.documentElement.style.overflowY = 'hidden'
  document.body.style.overflowY = 'hidden'
  motionRaf = requestAnimationFrame(smoothStep)
  window.addEventListener('mousemove', onWindowPointerMove, { passive: true })
  window.addEventListener('mouseleave', onWindowPointerLeave)
  window.addEventListener('scroll', onWindowScroll, { passive: true })
  targetScrollY.value = window.scrollY || 0
  smoothScrollY.value = targetScrollY.value
})

onBeforeUnmount(() => {
  document.documentElement.style.overflowY = prevHtmlOverflowY || 'auto'
  document.body.style.overflowY = prevBodyOverflowY || 'hidden'
  cancelAnimationFrame(motionRaf)
  window.removeEventListener('mousemove', onWindowPointerMove)
  window.removeEventListener('mouseleave', onWindowPointerLeave)
  window.removeEventListener('scroll', onWindowScroll)
})
</script>
