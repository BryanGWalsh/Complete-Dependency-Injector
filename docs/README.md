# Documentation site

Source for complete-dependency-injector.bryangwalsh.com, built with [VitePress](https://vitepress.dev).

- `guide/`: the guide pages.
- `snippets/`: a Dart package holding every code sample shown on the site. Pages import regions of these files with `<<< @/snippets/...#region`, and CI analyzes and tests the package so samples can't drift from the API.
- `use-cases/` and `demos/`: use-case guides and the demos page.
- `demo/`: a Flutter web app with one screen per demo. CI builds it into `public/demo/`, pages embed screens with `<DemoFrame route="/tables" />`, and the Flutter samples on the site are imported from its `lib/demos/` files.
- `public/api/` and `public/demo/`: generated in CI (git-ignored).

## Run locally

```sh
cd docs
npm install
npm run dev
```

To include the API reference locally, generate it first from each package directory:

```sh
(cd complete_dependency_injector && dart doc --output ../docs/public/api/core)
(cd complete_dependency_injector_flutter && dart doc --output ../docs/public/api/flutter)
```

To include the demos locally:

```sh
(cd docs/demo && flutter build web --base-href /demo/ --pwa-strategy=none --no-web-resources-cdn --output ../public/demo)
```

## Deploy

`.github/workflows/docs.yml` builds the site on every pull request and deploys it to GitHub Pages on pushes to `main`.
