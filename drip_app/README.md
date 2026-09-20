# Drip — Flutter frontend

Mobile frontend for **Drip**, the outfit-of-the-day social app, built from the supplied Figma file
(`../canvas.fig`, 32 mobile screens). This phase is **frontend only**: all data comes from local mock
repositories, and no backend, auth provider or database is configured.

## Run

```bash
flutter pub get
flutter run                 # any connected Android / iOS device or emulator
flutter run -d chrome       # quickest way to try it (use a phone-sized window)
flutter test                # 24 tests: repositories, controllers, end-to-end flow, 5 screen sizes
flutter analyze
```

Requires Flutter 3.47+ (Dart 3.13). No environment variables are needed in this phase.

## Architecture

```
lib/
  core/            theme (tokens from Figma), shared widgets, formatting
  data/
    models/        plain immutable domain models
    mock/          ALL fake data lives here (never in widgets)
    repositories/  abstract interfaces + Mock* implementations
    providers.dart Riverpod wiring: swap a Mock* for an API-backed class here
  features/<x>/    screens + controllers (Riverpod Notifiers)
  routing/         go_router config, bottom-nav shell, auth/onboarding guard
```

`UI → controller (Riverpod) → repository interface → mock implementation`.
To connect a backend later, implement the interfaces in `data/repositories/*` against the API and return
them from `data/providers.dart`; screens and controllers don't change.

## What is real vs mocked

Real (works today): navigation and route guards, onboarding picks, session flag, follow/unfollow,
likes/saves, search + recents, category filters, wardrobe add/edit/remove, studio builder
(undo/reset/randomize/publish), Taylor consultation flow, shopping bag, OOTD posting, profile editing,
settings (persisted on device, incl. the skin that recolours the app), logout that wipes account state,
camera/gallery picking via `image_picker`.

Mock until a backend exists: the feed/catalogue data, garment detection, Taylor's blueprint,
photoshoot renders, followers lists, checkout (the bag has no payment step), password change.

## Design source

`reference/` (project root) holds PNG renders of every Figma frame used for visual comparison.
Fonts (DM Mono, Bungee, Manrope, Inter, Fredoka) and the symbol/emoji fallbacks are bundled in
`assets/fonts`; photos were exported from the Figma file to `assets/images`.
