<template>
  <section class="space-y-5 pb-12">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <h1 class="inline-flex items-center gap-2 leading-none text-3xl font-bold lowercase sm:text-4xl">
        <svg viewBox="0 0 24 24" class="icon-pack icon-head text-cyan-300" aria-hidden="true">
          <path d="m12 3 2.6 5.3 5.9.9-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.9z"/>
        </svg>
        reviews
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
        <div v-if="filteredReviews.length" class="grid gap-6 md:grid-cols-2">
          <ReviewCard v-for="review in filteredReviews" :key="review.id" :review="review" />
        </div>

        <div v-else class="border border-line bg-panel/50 p-8 text-sm lowercase tracking-wide text-soft">
          no {{ activeCategory }} reviews yet
        </div>
      </div>
    </Transition>
  </section>
</template>

<script setup>
import { computed, ref } from 'vue'
import ReviewCard from '../components/ReviewCard.vue'
import { reviews } from '../data/reviews'

const activeCategory = ref('dev')

const filteredReviews = computed(() =>
  reviews.filter((review) => (review.category ?? 'dev') === activeCategory.value)
)
</script>
