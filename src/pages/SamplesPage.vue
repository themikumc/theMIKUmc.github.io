<template>
  <section class="space-y-5 pb-12">
    <h1 class="inline-flex items-center gap-2 leading-none text-3xl font-bold lowercase sm:text-4xl">
      <svg viewBox="0 0 24 24" class="icon-pack icon-head text-cyan-300" aria-hidden="true">
        <path d="M3 8a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
      </svg>
      samples
    </h1>

    <div class="grid gap-4 md:grid-cols-2">
      <button
        v-for="sample in samples"
        :key="sample.id"
        type="button"
        class="sample-card group border border-line bg-panel/70 text-left transition-transform duration-150 ease-out will-change-transform"
        :style="cardStyle(sample.id)"
        @mousemove="onCardMove(sample.id, $event)"
        @mouseleave="onCardLeave(sample.id)"
        @click="openSample(sample, $event)"
      >
        <div class="relative aspect-video w-full overflow-hidden border-b border-line bg-black">
          <img
            v-if="sample.type === 'image'"
            :src="sample.src"
            :alt="sample.name"
            class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.02]"
          />
          <video
            v-else
            :poster="sample.poster"
            :src="sample.src"
            muted
            preload="metadata"
            playsinline
            class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.02]"
          />

          <div class="pointer-events-none absolute inset-0 bg-black/55 opacity-0 transition-opacity duration-200 group-hover:opacity-100">
            <p class="absolute left-3 right-3 top-3 text-sm lowercase leading-relaxed text-white">
              {{ sample.description }}
            </p>
          </div>
        </div>

        <div class="space-y-1 p-3">
          <p class="text-base font-semibold lowercase text-white">{{ sample.name }}</p>
          <p class="text-xs lowercase tracking-wide text-soft">{{ sample.caption }}</p>
        </div>
      </button>
    </div>

    <Transition name="sample-modal">
      <div
        v-if="activeSample"
        class="sample-modal-root fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4"
        @click.self="closeSample"
      >
        <div
          ref="modalPanelEl"
          class="sample-modal-panel relative h-[82vh] w-[92vw] max-w-6xl border border-line bg-black"
        >
          <button
            type="button"
            class="absolute right-3 top-3 z-10 border border-line bg-black px-4 py-1.5 text-sm lowercase text-white transition-all duration-200 ease-out hover:scale-105 hover:border-cyan-300 hover:text-cyan-200 hover:shadow-[0_0_14px_rgba(126,247,255,0.45)]"
            @click="closeSample"
          >
            close
          </button>

          <img
            v-if="activeSample.type === 'image'"
            :src="activeSample.src"
            :alt="activeSample.name"
            class="h-full w-full object-contain"
          />
          <video
            v-else
            :src="activeSample.src"
            :poster="activeSample.poster"
            controls
            autoplay
            class="h-full w-full object-contain"
          />
        </div>
      </div>
    </Transition>
  </section>
</template>

<script setup>
import { nextTick, ref } from 'vue'
import { samples } from '../data/samples'

const activeSample = ref(null)
const cardTransforms = ref({})
const modalPanelEl = ref(null)
const launchRect = ref(null)
const isClosing = ref(false)
const canHover = () => window.matchMedia('(hover: hover) and (pointer: fine)').matches

const cardStyle = (id) => ({
  transform: cardTransforms.value[id] ?? 'perspective(1000px) rotateX(0deg) rotateY(0deg)'
})

const onCardMove = (id, event) => {
  if (!canHover()) return
  const rect = event.currentTarget.getBoundingClientRect()
  const nx = (event.clientX - rect.left) / rect.width - 0.5
  const ny = (event.clientY - rect.top) / rect.height - 0.5
  cardTransforms.value[id] = `perspective(1000px) rotateX(${-ny * 7}deg) rotateY(${nx * 9}deg) translateZ(0)`
}

const onCardLeave = (id) => {
  if (!canHover()) return
  cardTransforms.value[id] = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0)'
}

const openSample = async (sample, event) => {
  launchRect.value = event.currentTarget.getBoundingClientRect()
  activeSample.value = sample
  await nextTick()
  if (!modalPanelEl.value || !launchRect.value) return
  const panelRect = modalPanelEl.value.getBoundingClientRect()
  const dx = launchRect.value.left - panelRect.left
  const dy = launchRect.value.top - panelRect.top
  const sx = launchRect.value.width / panelRect.width
  const sy = launchRect.value.height / panelRect.height
  modalPanelEl.value.animate(
    [
      { transform: `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})`, opacity: 0.55 },
      { transform: 'translate(0px, 0px) scale(1, 1)', opacity: 1 }
    ],
    {
      duration: 380,
      easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
      fill: 'both'
    }
  )
}

const closeSample = async () => {
  if (isClosing.value) return
  if (!modalPanelEl.value || !launchRect.value) {
    activeSample.value = null
    return
  }
  isClosing.value = true
  const panelRect = modalPanelEl.value.getBoundingClientRect()
  const dx = launchRect.value.left - panelRect.left
  const dy = launchRect.value.top - panelRect.top
  const sx = launchRect.value.width / panelRect.width
  const sy = launchRect.value.height / panelRect.height
  const anim = modalPanelEl.value.animate(
    [
      { transform: 'translate(0px, 0px) scale(1, 1)', opacity: 1 },
      { transform: `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})`, opacity: 0.55 }
    ],
    {
      duration: 320,
      easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
      fill: 'both'
    }
  )
  await anim.finished
  activeSample.value = null
  launchRect.value = null
  isClosing.value = false
}
</script>
