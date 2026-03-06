<template>
  <section class="space-y-5 pb-12">
    <h1 class="inline-flex items-center gap-2 leading-none text-3xl font-bold lowercase sm:text-4xl">
      <svg viewBox="0 0 24 24" class="icon-pack icon-head text-cyan-300" aria-hidden="true">
        <path d="m12 3 2.6 5.3 5.9.9-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.9z"/>
      </svg>
      reviews
    </h1>
    <div class="grid gap-6 md:grid-cols-2">
      <ReviewCard v-for="review in reviews" :key="review.id" :review="review" />
    </div>
  </section>
</template>

<script setup>
import ReviewCard from '../components/ReviewCard.vue'
import { reviews } from '../data/reviews'
</script>
