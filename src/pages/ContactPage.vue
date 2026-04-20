<template>
  <section class="mx-auto max-w-4xl space-y-8 pb-10">
    <h1 class="inline-flex items-center gap-3 text-4xl font-bold lowercase sm:text-5xl">
      <svg viewBox="0 0 24 24" class="icon-pack icon-head text-cyan-300" aria-hidden="true">
        <rect x="3" y="5" width="18" height="14" rx="2"/>
        <path d="m3 7 9 6 9-6"/>
      </svg>
      <span class="text-white">contact</span>
    </h1>
    <p class="text-lg lowercase text-soft sm:text-xl">reach out for plugins, mods, edits, and more!</p>

    <article
      class="border border-line bg-panel/70 p-10 transition-[transform,box-shadow] duration-150 ease-out will-change-transform hover:shadow-[inset_0_0_0_1px_rgba(140,245,255,0.55)] sm:p-12"
      :style="{ transform: tiltTransform }"
      @mousemove="onMove"
      @mouseleave="onLeave"
    >
      <div class="space-y-4">
        <div>
          <p class="mb-1 text-xs lowercase tracking-wider text-soft">discord</p>
          <button
            type="button"
            class="text-2xl font-medium text-white transition-colors duration-300 ease-out hover:text-cyan-300 sm:text-3xl"
            :class="{ 'copy-text-flash': copiedDiscord }"
            @mousedown.prevent="copyDiscord"
          >
            <span class="text-mint">@</span>themikumc
          </button>
        </div>
        <div>
          <p class="mb-1 text-xs lowercase tracking-wider text-soft">email</p>
          <button
            type="button"
            class="text-2xl font-medium text-white transition-colors duration-300 ease-out hover:text-cyan-300 sm:text-3xl"
            :class="{ 'copy-text-flash': copiedEmail }"
            @mousedown.prevent="copyEmail"
          >
            themikumc@gmail.com
          </button>
        </div>
      </div>
    </article>
  </section>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const tiltTransform = ref('perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0)')
const copiedDiscord = ref(false)
const copiedEmail = ref(false)
let copiedDiscordTimer
let copiedEmailTimer
const canHover = () => window.matchMedia('(hover: hover) and (pointer: fine)').matches

const onMove = (event) => {
  if (!canHover()) return
  const rect = event.currentTarget.getBoundingClientRect()
  const nx = (event.clientX - rect.left) / rect.width - 0.5
  const ny = (event.clientY - rect.top) / rect.height - 0.5
  tiltTransform.value = `perspective(1000px) rotateX(${-ny * 6}deg) rotateY(${nx * 8}deg) translateZ(0)`
}

const onLeave = () => {
  tiltTransform.value = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0)'
}

const copyDiscord = async () => {
  try {
    await navigator.clipboard.writeText('themikumc')
    copiedDiscord.value = false
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        copiedDiscord.value = true
      })
    })
    window.clearTimeout(copiedDiscordTimer)
    copiedDiscordTimer = window.setTimeout(() => {
      copiedDiscord.value = false
    }, 620)
  } catch {}
}

const copyEmail = async () => {
  try {
    await navigator.clipboard.writeText('themikumc@gmail.com')
    copiedEmail.value = false
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        copiedEmail.value = true
      })
    })
    window.clearTimeout(copiedEmailTimer)
    copiedEmailTimer = window.setTimeout(() => {
      copiedEmail.value = false
    }, 620)
  } catch {}
}

onMounted(() => {
  if (!canHover()) {
    tiltTransform.value = 'none'
  }
})

onBeforeUnmount(() => {
  window.clearTimeout(copiedDiscordTimer)
  window.clearTimeout(copiedEmailTimer)
})
</script>
