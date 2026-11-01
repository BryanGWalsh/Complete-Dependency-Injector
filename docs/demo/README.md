# Docs demo app

A Flutter web app with one screen per demo. CI builds it into the docs site at `/demo/`, and the Use Case pages embed individual screens (for example `/demo/#/tables`).

The Flutter code samples on the docs site are imported from `lib/demos/`, so the docs always show the code that is actually running.

```sh
flutter run -d chrome
```
