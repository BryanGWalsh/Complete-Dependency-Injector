<script setup lang="ts">
import { computed } from 'vue'
import { withBase } from 'vitepress'

// Embeds one screen of the Flutter web demo app (docs/demo), built into /demo/.
const props = withDefaults(defineProps<{ route: string; height?: number; title?: string }>(), {
  height: 480,
  title: 'Live demo',
})

const src = computed(() => withBase(`/demo/?embed=1#${props.route}`))
const fullSrc = computed(() => withBase(`/demo/#${props.route}`))
</script>

<template>
  <figure class="demo-frame">
    <div class="demo-frame__bar">
      <span>{{ title }}</span>
      <a :href="fullSrc" target="_blank" rel="noopener">Open full screen ↗</a>
    </div>
    <iframe :src="src" :title="title" :style="{ height: `${height}px` }" loading="lazy" />
  </figure>
</template>

<style scoped>
.demo-frame {
  margin: 16px 0;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  overflow: hidden;
  background: var(--vp-c-bg-soft);
}
.demo-frame__bar {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 12px;
  font-size: 13px;
  color: var(--vp-c-text-2);
  border-bottom: 1px solid var(--vp-c-divider);
}
.demo-frame__bar a {
  color: var(--vp-c-brand-1);
  text-decoration: none;
}
.demo-frame iframe {
  display: block;
  width: 100%;
  border: 0;
  background: var(--vp-c-bg);
}
</style>
