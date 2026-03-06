<template>
  <article
    class="border border-line bg-panel/70 p-8 sm:p-10 transition-[transform,box-shadow] duration-150 ease-out will-change-transform hover:shadow-[inset_0_0_0_1px_rgba(140,245,255,0.55)]"
    :style="{ transform: tiltTransform }"
    @mousemove="onMove"
    @mouseleave="onLeave"
  >
    <div class="mb-5 flex items-center gap-1">
      <span
        v-for="star in 5"
        :key="star"
        class="text-xl leading-none"
        :class="star <= (review.rating ?? 5) ? 'text-cyan-200' : 'text-slate-600'"
      >
        ★
      </span>
    </div>
    <p class="mb-6 text-lg leading-relaxed text-slate-100 sm:text-xl">"{{ review.quote }}"</p>
    <footer class="space-y-2">
      <p class="text-lg font-semibold text-white sm:text-xl">{{ review.name }}</p>
      <p class="text-sm lowercase tracking-wide text-soft">{{ review.role }}</p>
    </footer>
  </article>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  review: {
    type: Object,
    required: true
  }
})

const tiltTransform = ref('perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0)')

const onMove = (event) => {
  const rect = event.currentTarget.getBoundingClientRect()
  const nx = (event.clientX - rect.left) / rect.width - 0.5
  const ny = (event.clientY - rect.top) / rect.height - 0.5
  tiltTransform.value = `perspective(1000px) rotateX(${-ny * 6}deg) rotateY(${nx * 8}deg) translateZ(0)`
}

const onLeave = () => {
  tiltTransform.value = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0)'
}
</script>
