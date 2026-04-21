<template>
  <section class="space-y-5 pb-12">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <h1 class="inline-flex items-center gap-2 leading-none text-3xl font-bold lowercase sm:text-4xl">
        <svg viewBox="0 0 24 24" class="icon-pack icon-head text-cyan-300" aria-hidden="true">
          <path d="M3 8a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
        </svg>
        samples
      </h1>

      <div class="inline-flex w-fit border border-line bg-black p-1">
        <button
          type="button"
          class="px-4 py-2 text-sm font-semibold lowercase tracking-[0.18em] transition-colors duration-200"
          :class="activeCategory === 'dev' ? 'bg-cyan-950/70 text-white' : 'text-soft hover:text-cyan-200'"
          @click="activeCategory = 'dev'"
        >
          dev
        </button>
        <button
          type="button"
          class="px-4 py-2 text-sm font-semibold lowercase tracking-[0.18em] transition-colors duration-200"
          :class="activeCategory === 'editor' ? 'bg-cyan-950/70 text-white' : 'text-soft hover:text-cyan-200'"
          @click="activeCategory = 'editor'"
        >
          editor
        </button>
      </div>
    </div>

    <Transition name="page-swap" mode="out-in">
      <div :key="activeCategory">
        <div v-if="filteredSamples.length" class="grid gap-4 md:grid-cols-2">
          <button
            v-for="sample in filteredSamples"
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
                v-if="sample.type === 'external'"
                :src="sample.src"
                :alt="sample.name"
                class="h-full w-full object-cover object-top transition-transform duration-300 group-hover:scale-[1.02]"
              />
              <img
                v-else-if="sample.type === 'image'"
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

            <div class="space-y-2 p-3">
              <div class="flex items-start justify-between gap-3">
                <div class="space-y-1">
                  <p class="text-base font-semibold lowercase text-white">{{ sample.name }}</p>
                  <p class="text-xs lowercase tracking-wide text-soft">{{ sample.caption }}</p>
                </div>

                <div v-if="sample.type === 'external'" class="flex items-center gap-2">
                  <a
                    v-for="link in sample.links"
                    :key="link.id"
                    :href="link.href"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex h-9 w-9 items-center justify-center border border-line bg-black/80 text-white transition-colors duration-200 hover:border-cyan-300 hover:text-cyan-200"
                    :aria-label="link.label"
                    @click.stop
                  >
                    <svg v-if="link.id === 'youtube'" viewBox="0 0 24 24" class="icon-pack h-4 w-4 text-red-400" aria-hidden="true">
                      <rect x="3" y="6" width="18" height="12" rx="4"/>
                      <path d="m10 9 5 3-5 3z" fill="currentColor" stroke="none"/>
                    </svg>
                    <svg v-else viewBox="0 0 24 24" class="icon-pack h-4 w-4 text-cyan-300" aria-hidden="true">
                      <path d="M14 4v8.2a3.3 3.3 0 1 1-2.1-3.1V4.5c1.3 1.5 3 2.4 5.1 2.5v2.2A8 8 0 0 1 14 8.1V4z"/>
                    </svg>
                  </a>
                </div>
              </div>
            </div>
          </button>
        </div>

        <div v-else class="border border-line bg-panel/50 p-8 text-sm lowercase tracking-wide text-soft">
          no {{ activeCategory }} samples yet
        </div>
      </div>
    </Transition>

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

    <Transition name="sample-modal">
      <div
        v-if="activeLinkSample"
        class="sample-modal-root fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4"
        @click.self="closeLinkSample"
      >
        <div class="relative w-full max-w-md border border-line bg-black p-6">
          <button
            type="button"
            class="absolute right-3 top-3 z-10 border border-line bg-black px-3 py-1 text-sm lowercase text-white transition-all duration-200 ease-out hover:border-cyan-300 hover:text-cyan-200"
            @click="closeLinkSample"
          >
            close
          </button>

          <div class="space-y-4">
            <p class="text-xl font-semibold lowercase text-white">{{ activeLinkSample.name }}</p>

            <div class="grid gap-3">
              <a
                v-for="link in activeLinkSample.links"
                :key="link.id"
                :href="link.href"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center justify-between border border-line bg-panel/70 px-4 py-3 text-sm font-semibold lowercase tracking-[0.16em] text-white transition-colors duration-200 hover:border-cyan-300 hover:text-cyan-200"
              >
                <span class="inline-flex items-center gap-2">
                  <svg v-if="link.id === 'youtube'" viewBox="0 0 24 24" class="icon-pack h-4 w-4 text-red-400" aria-hidden="true">
                    <rect x="3" y="6" width="18" height="12" rx="4"/>
                    <path d="m10 9 5 3-5 3z" fill="currentColor" stroke="none"/>
                  </svg>
                  <svg v-else viewBox="0 0 24 24" class="icon-pack h-4 w-4 text-cyan-300" aria-hidden="true">
                    <path d="M14 4v8.2a3.3 3.3 0 1 1-2.1-3.1V4.5c1.3 1.5 3 2.4 5.1 2.5v2.2A8 8 0 0 1 14 8.1V4z"/>
                  </svg>
                  <span>{{ link.label }}</span>
                </span>
                <span class="text-soft">open</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <Transition name="sample-modal">
      <div
        v-if="activeEmbedSample"
        class="sample-modal-root fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4"
        @click.self="closeEmbedSample"
      >
        <div class="relative aspect-video w-[92vw] max-w-6xl border border-line bg-black">
          <button
            type="button"
            class="absolute right-3 top-3 z-10 border border-line bg-black px-4 py-1.5 text-sm lowercase text-white transition-all duration-200 ease-out hover:scale-105 hover:border-cyan-300 hover:text-cyan-200 hover:shadow-[0_0_14px_rgba(126,247,255,0.45)]"
            @click="closeEmbedSample"
          >
            close
          </button>
          <iframe
            :src="activeEmbedSample.embedUrl"
            :title="activeEmbedSample.name"
            class="h-full w-full"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            allowfullscreen
            referrerpolicy="strict-origin-when-cross-origin"
          ></iframe>
        </div>
      </div>
    </Transition>
  </section>
</template>

<script setup>
import { computed, nextTick, ref } from 'vue'
import { samples } from '../data/samples'

const activeSample = ref(null)
const activeLinkSample = ref(null)
const activeEmbedSample = ref(null)
const activeCategory = ref('dev')
const cardTransforms = ref({})
const modalPanelEl = ref(null)
const launchRect = ref(null)
const isClosing = ref(false)
const canHover = () => window.matchMedia('(hover: hover) and (pointer: fine)').matches

const filteredSamples = computed(() =>
  samples.filter((sample) => (sample.category ?? 'dev') === activeCategory.value)
)

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

const getYouTubeEmbedUrl = (href) => {
  try {
    const url = new URL(href)
    let id = ''
    if (url.hostname.includes('youtu.be')) {
      id = url.pathname.replace('/', '')
    } else if (url.hostname.includes('youtube.com')) {
      id = url.searchParams.get('v') ?? ''
    }
    return id ? `https://www.youtube.com/embed/${id}?autoplay=1&rel=0` : ''
  } catch {
    return ''
  }
}

const openSample = async (sample, event) => {
  if (sample.type === 'external') {
    if (sample.links?.length === 1 && sample.links[0].id === 'youtube') {
      const embedUrl = getYouTubeEmbedUrl(sample.links[0].href)
      if (embedUrl) {
        activeEmbedSample.value = { name: sample.name, embedUrl }
        return
      }
    }
    activeLinkSample.value = sample
    return
  }
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

const closeLinkSample = () => {
  activeLinkSample.value = null
}

const closeEmbedSample = () => {
  activeEmbedSample.value = null
}
</script>
