# Drip — Flutter frontend

Mobile frontend for **Drip**, the outfit-of-the-day social app, built from the supplied Figma file
(`../canvas.fig`, 32 mobile screens). This phase is **frontend only**: all data comes from local mock
repositories, and no backend, auth provider or database is configured.

## Run

```bash
flutter pub get
flutter run                 # any connected Android / iOS device or emulator
flutter run -d chrome       # quickest way to try it (use a phone-sized window)
flutter test                # 59 tests: repositories, controllers, flows, nav + swipe gestures, themes, 5 screen sizes
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
  routing/         go_router config, floating-nav shell, auth/onboarding guard
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


## Refinement pass: what changed

Everything below is uncommitted working-tree work on top of the original Figma build. The information architecture,
data layer and existing screens were kept; this pass refines look, motion, navigation and performance.

### Home
- Restructured to the hand-drawn wireframe: DRIP wordmark + messages/notifications (with a real unread dot) →
  horizontally scrolling **Stories** → the **featured fit** → a "Today's Drip" info bar (with the Ask Taylor entry) →
  a two-column grid of fresh fits → floating navigation.
- Stories are larger (76px), with an accent→secondary ring for unseen and a hairline once seen, plus a "Your story" add.
- Featured fit: tap opens it in the Fashion Scroll (the image expands into place); double-tap likes with a heart burst.
- **Search left the Home header.** It lives in **Discover** (which already has the search field); reach it from the
  "SEARCH & DISCOVER →" link on Home.
- Pull to refresh, skeleton placeholders shaped like the real layout while loading.

### Fashion Scroll (`/scroll`)
- Immersive, full-bleed vertical pager: one fit per screen, snapping, next image pre-cached.
- Creator row with follow, caption, tag chips, a "shop the look" strip ("N pieces · $total"), views and DRIP score.
- Action rail: like, comments, save, share, with counts. Comments and share open glass sheets (comments can be posted).
- Double-tap to like, end-of-feed card that takes you back to the top, opens on a specific fit via `?id=`.
- The Home card's photo flies into place (Hero) with an animating corner radius. This only happens when you open
  from a card, never during a tab swipe.

### Navigation and gestures
- Floating glass bottom bar, **icons only** (no labels; semantic labels are kept for screen readers). The "$" slot
  became the ellipse-and-star **reel** glyph (`lib/core/widgets/nav_glyphs.dart`, fitted to the reference).
- Tap a tab, or drag on the bar to scrub the selection lens (1:1 tracking, haptic ticks, rubber-band at the ends,
  momentum projection on release).
- **Swipe anywhere on a tab root** to move to the neighbouring tab (Home ↔ Scroll ↔ Wardrobe ↔ You). The screen follows
  the finger with resistance, buzzes when the swipe is far enough, and a short quick flick also counts. Horizontal
  lists (stories, the theme bar, carousels) claim their own drags first, so nothing fights.
- Tab changes are a plain sideways page push (position only, no fading) so they stay cheap on mid-range phones.

### Themes ("worlds")
13 poster-based themes (`lib/core/theme/drip_skin.dart`). The default is the black/white/red/blue flare poster. A theme
is a whole world, not a recolour:
- **Ground**: the tinted near-black the app sits on (blue-black, oxblood-black, moss-black...).
- **Surfaces**: cards, inputs, chips and borders are re-derived from the ground and poster wash
  (`AppColors.useSurfaces`); the default theme keeps the original Figma values exactly.
- **Headline typeface**: poster caps (Bungee), soft and rounded (Fredoka) or clean editorial (Manrope ExtraBold).
- **Glass character**: clarity (frosted paper → clear crystal) and corner roundness (archival = squarer,
  bloom = pillowy). The Home cards' corners follow it too.
- **Backdrop**: a quiet composition: the poster as faint texture plus one pool of its light, placed differently per theme.
- **Accent / secondary**: used sparingly (create button, story rings, links, chips, profile handle and ring).
- Switch from the **customization bar** (Profile and Settings: colour swatches, one tap) or the **poster carousel**
  (`/themes`), which previews the entire app live and reverts if you leave without applying.
- Changing theme cross-fades the backdrop and rebuilds the app once so every screen takes the new surfaces and type.

### App icon
- The launcher icon is the poster of the selected theme; the default is the flare poster. "Match App Icon to Theme" in
  Settings turns this off (the default icon returns).
- Android: one `<activity-alias>` per theme + a small Kotlin channel (`MainActivity.kt`). iOS: alternate icon sets +
  a Swift channel (`AppDelegate.swift`). Dart side: `lib/core/platform/app_icon.dart`.
- **Android swaps the icon only when you leave the app.** Switching the alias while the app is open restarted it (it
  looked like a crash right after changing theme). iOS can only change the icon in the foreground and never restarts,
  so it is debounced instead.

### Launch and loading
- ~1.1s launch sequence: the wordmark resolves out of a blur, the red "i" drop pulses, tap to skip; it pre-warms the
  feed, stories and catalogue and pre-caches images. Native launch screens use the base colour so there is no white flash.
- One loading language: shimmer skeletons with a shared clock (`core/widgets/skeleton.dart`), a drop-pulse indicator,
  tinted image placeholders, and designed failure states (no blank flashes, no spinners over content).

### Visual refinement
- **Glass** (`core/widgets/glass.dart`) is the translucent material: floating nav, big plates and sheets get a real
  backdrop blur; small chips are tinted only (a live blur per chip was too costly).
- Calmer overall: solid saturated accent slabs became quiet tinted pills, the nav lens is neutral glass, the create
  button is smaller with no glow, and the backdrop is dark and quiet.
- Motion vocabulary in `core/motion.dart` (durations, ease-out curves, critically damped springs, semantic haptics);
  reduced-motion turns movement into short fades. Accessible labels, 44px hit targets, high-contrast solid glass.

### Performance
- Tab transitions no longer fade whole screens (two offscreen layers per change); they slide.
- Thin glass surfaces no longer run a live blur (the Fashion Scroll had ~7 over a full-screen photo); regular/thick blur
  strengths lowered.
- Backdrop image uses an opacity parameter instead of an `Opacity` layer; avatars decode at their display size.
- Hero flights are disabled for tab moves; the swipe wrapper repaints only a translated layer.

### Tests and tooling
- `flutter test`: 59 tests (repositories, controllers, flows, nav tap/drag/rubber-band, swipe-anywhere, Home → Scroll,
  likes/comments/share, themes and live preview, icon-swap timing per platform, launch, five screen sizes).
- `flutter test tool/capture_test.dart --dart-define=OUT=<dir>` renders real screenshots (fonts, assets, blur) of key
  screens and skins for visual review.
- `python tool/build_assets.py` (needs `posters/poster_XX.jpg`) regenerates theme art, the wordmark and the icons;
  then `dart run flutter_launcher_icons`.

### Known limits
- iOS alternate icons and the Swift channel are written but **not built or run** (no Mac here).
- The poster art was captured at ~658px, so enlarged icons are slightly grainy.
- Launchers can take a few seconds to refresh a changed icon.
- Nothing has been committed or pushed yet, by request.
