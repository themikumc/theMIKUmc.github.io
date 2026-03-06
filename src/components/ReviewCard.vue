<template>
  <article
    class="border border-line bg-panel/70 p-8 sm:p-10 transition-[transform,box-shadow] duration-150 ease-out will-change-transform hover:shadow-[inset_0_0_0_1px_rgba(140,245,255,0.55)]"
    :style="{ transform: tiltTransform }"
    @mousemove="onMove"
    @mouseleave="onLeave"
  >
    <div class="mb-5 flex items-center gap-1">
      <span
        v-for="(fill, index) in starFills"
        :key="index"
        class="relative inline-block text-xl leading-none text-slate-600"
      >
        ★
        <span class="absolute left-0 top-0 overflow-hidden text-cyan-200" :style="{ width: `${fill * 100}%` }">★</span>
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
import { computed, ref } from 'vue'

const props = defineProps({
  review: {
    type: Object,
    required: true
  }
})

const rating = computed(() => {
  const value = Number(props.review.rating ?? 5)
  if (Number.isNaN(value)) return 5
  return Math.max(0, Math.min(5, value))
})

const starFills = computed(() =>
  Array.from({ length: 5 }, (_, index) => Math.max(0, Math.min(1, rating.value - index)))
)

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
