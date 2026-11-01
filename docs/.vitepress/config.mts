import { defineConfig } from 'vitepress'

const repo = 'https://github.com/BryanGWalsh/Complete-Dependency-Injector'

export default defineConfig({
  title: 'Complete Dependency Injector',
  description: 'Hierarchical, async-aware dependency injection for Dart and Flutter.',
  // Served from the root of complete-dependency-injector.bryangwalsh.com.
  // Override with DOCS_BASE (for example "/Complete-Dependency-Injector/") to preview on the default Pages URL.
  base: process.env.DOCS_BASE ?? '/',
  cleanUrls: true,
  // Only the site's own pages; the demo app and snippets have their own READMEs.
  srcExclude: ['README.md', 'demo/**', 'snippets/**'],
  lastUpdated: true,
  // The API reference (dartdoc) and the demo app (Flutter web) are generated
  // into public/ at build time, so VitePress can't see them when checking links.
  ignoreDeadLinks: [/^\/api\//, /^\/demo\//],
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/quick-start' },
      { text: 'Use cases', link: '/use-cases/async-services' },
      { text: 'Demos', link: '/demos/' },
      {
        text: 'API reference',
        items: [
          { text: 'Core (Dart)', link: '/api/core/index.html', target: '_self' },
          { text: 'Flutter', link: '/api/flutter/index.html', target: '_self' },
          { text: 'Core on pub.dev', link: 'https://pub.dev/documentation/complete_dependency_injector/latest/' },
          { text: 'Flutter on pub.dev', link: 'https://pub.dev/documentation/complete_dependency_injector_flutter/latest/' },
        ],
      },
    ],
    sidebar: [
      {
        text: 'Getting started',
        items: [
          { text: 'Installation', link: '/guide/installation' },
          { text: 'Quick start', link: '/guide/quick-start' },
          { text: 'Core concepts', link: '/guide/core-concepts' },
        ],
      },
      {
        text: 'Use cases',
        items: [
          { text: 'Async services', link: '/use-cases/async-services' },
          { text: 'Scoped services', link: '/use-cases/scoped-services' },
        ],
      },
      {
        text: 'Demos',
        items: [{ text: 'All demos', link: '/demos/' }],
      },
      {
        text: 'Reference',
        items: [{ text: 'API reference', link: '/guide/api-reference' }],
      },
    ],
    search: { provider: 'local' },
    socialLinks: [{ icon: 'github', link: repo }],
    editLink: {
      pattern: `${repo}/edit/main/docs/:path`,
      text: 'Edit this page on GitHub',
    },
    footer: {
      message: 'Released under the MIT License.',
    },
  },
})
