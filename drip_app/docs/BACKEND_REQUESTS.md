# Backend requests from the app

From the Flutter session, for the backend session. Newest first. Each request says what the app
does today without it, so nothing is blocked.

## 2026-10-21: build the wardrobe from the user's gallery photos (big; founder-approved)

The founder wants Wardrobe to work like Google Photos' Wardrobe. The user shares outfit photos and
gets back a sorted wardrobe of clean cut-outs of what they already own. The design doc the founder
reviewed is at https://claude.ai/code/artifact/737ac4aa-2baf-49e0-b431-bb4bd9ac0e77. **The founder's
decisions:**

- **The system photo picker, never gallery access.** The app uses Android's Photo Picker (and the
  iOS picker), so there's no `READ_MEDIA_IMAGES` and no Play declaration.
- **At most 50 photos per import.** The user picks as many as they like within that.
- **One person per photo in this version.** Group photos are "coming in the next update". The app
  sets them aside before upload; the server should skip any that get through.
- **No review screen.** Pieces go straight into the wardrobe. A bad cut-out is reported from its
  page (#5). So **duplicates must be folded on the server**: a tee seen in 9 photos is one piece.
- **Wear history from photo dates.** Each photo's day counts as a day the piece was worn.
- **A push notification when it's done**, so the user can leave the app (#4).
- **Cut-outs as clean as possible.** Generated "clean product shots" are not for now.
- **Run it locally for prototyping** (on the founder's laptop) before deciding between a separate
  worker and a GPU host (#2, "Running it locally").

### What the app does today (branch `feat/wardrobe-import`)

1. **Welcome screen** (`/wardrobe/import`): "Welcome to your wardrobe" and what works best (just
   you, mirror selfies or full-body shots, good light, fits you love). The privacy line promises
   what's in "Privacy promises" below.
2. **Pick**, up to 50 photos. The picker resizes them to 1600 px on the long edge (JPEG, quality
   88) and keeps the EXIF date.
3. **On-phone checks (ML Kit)**, with nothing uploaded yet. The phone sets aside:
   - photos with 2 or more faces (a group);
   - photos with no face and no body (no one in them);
   - photos that are too dark;
   - near-identical repeats (burst shots).

   It reads each photo's EXIF date.
4. **Upload.** `POST /wardrobe/imports`, then a PUT of each photo to its slot, 3 at a time. Photos
   are confirmed in batches of 10 with `POST …/photos`, and the last batch says `last: true`. A
   photo that fails twice is left out.
5. **Follow.** The app polls `GET /wardrobe/imports/:id` every 4 s in the app and every 15 s
   while the user is in another app. An Android foreground service keeps that alive and shows an
   ongoing "Building your wardrobe" progress notification.
6. **Done.** The app shows a "Your wardrobe is ready" notification (or a toast in the app), and a
   banner on Wardrobe reports "23 new pieces, 6 repeats folded together". Then it refetches
   `GET /wardrobe/items`.
7. **Resume.** The app stores the import id. On the next launch it calls `GET
   /wardrobe/imports/:id`, or `GET /wardrobe/imports?active=true` if it has no id.

**Until the endpoints exist**, a 404 on `POST /wardrobe/imports` shows "Switching this on: try again
soon". Debug builds can also preview the remaining steps against a stand-in server.

### 1. The gallery import API (needed)

| Method | Path | Body → response |
|---|---|---|
| POST | `/wardrobe/imports` | `{ count }` (1–50) → `201 { id, uploads: [{ uploadUrl, path }] }`, one slot per photo. 400 for a bad count, 409 if the user already has a `processing` import, 429 over **3 imports a day**. Slots aren't tied to a content type: the app sends `image/jpeg` (or `image/png`/`image/webp`), so sniff the real type with sharp. |
| POST | `/wardrobe/imports/:id/photos` | `{ photos: [{ path, takenOn? }], last: bool }` → `202 { photosTotal }`. Called several times (batches of about 10). `takenOn` is `YYYY-MM-DD` (EXIF has no time zone, so only the day is sent). Paths must be this import's slots; a path confirmed twice is ignored. On `last: true`, `photosTotal` becomes the number confirmed, and the slots never confirmed are deleted. 404 if not yours. |
| GET | `/wardrobe/imports/:id` | → `WardrobeImport`. 404 if not yours. |
| GET | `/wardrobe/imports?active=true` | → `{ imports: WardrobeImport[] }`, the user's `processing` imports, newest first (in practice 0 or 1). |
| DELETE | `/wardrobe/imports/:id` | → 204. Stops its jobs and deletes its photos and crops. Pieces already created stay. |

`WardrobeImport` = `{ id, status: processing|done|failed|cancelled, stage: photos|grouping,
photosTotal, photosDone, photosSkipped, piecesAdded, duplicatesMerged, alreadyOwned, createdAt }`.
- `photosDone` counts photos finished, including skipped ones, so the bar reaches the end.
- `stage: grouping` is the last step, after every photo is done.
- `photosSkipped` counts photos with no one in them, groups and unreadable photos.
- `duplicatesMerged` counts cut-outs folded into another piece from the same import.
- `alreadyOwned` counts pieces matched to something already in the wardrobe (#3).

**Storage.** Use the private bucket, under `wardrobe-imports/<user>/<import>/…`, with paths derived
from ids, so a retry overwrites rather than duplicates (as `runWardrobeItem` does today).

**Tables** (one migration, owner-only RLS like `wardrobe_items`):
- `wardrobe_imports(id, user_id, status, stage, photos_total, photos_done, photos_skipped,
  pieces_added, duplicates_merged, already_owned, last_received, created_at, finished_at)`.
- `wardrobe_import_photos(id, import_id, path, taken_on, status queued|done|skipped|failed,
  skip_reason)`.
- `wardrobe_detections(id, photo_id, slot, crop_path, bbox, quality, embedding vector(512),
  colour lab[])`. Needs `pgvector`.
- `wardrobe_items` gains `origin = 'import'`, `import_id`, and `embedding vector(512)` (for #3
  and #6).

### 2. The pipeline: photo → clean pieces, repeats folded (needed)

Three Inngest functions, like `wardrobe-process`.

**`wardrobe-import/photo`** runs once per confirmed photo, with low concurrency (2) because of RAM.
1. Download the photo, fix its rotation, and keep the full 1600 px for the crops. Run
   `segformer_b2_clothes` at 1024, as `segmentClothes` does.
2. **Skip** the photo (counted in `photosSkipped`, with a `skip_reason`) when:
   - the person region is tiny or missing;
   - it splits into **two or more large, separate person blobs** (a group).
3. **One region per piece**, using the parser's ATR labels:
   - `Upper-clothes` → top or outer. The parser can't tell them apart, so the tagger decides.
   - `Pants`, `Skirt` → bottom.
   - `Dress` → dress.
   - `Left-shoe` + `Right-shoe` → **one** shoes piece (their union).
   - `Bag`, `Belt`, `Scarf`, `Hat`, `Sunglasses` → accessory.
   - Ignore face, hair, skin, arms, legs and background.

   Drop regions under about 1.5 % of the person's area.
4. **Make the cut-out as clean as possible.** This is the founder's priority, and the steps are
   cheap:
   - Scale the mask up to 1600 px with a smooth resize, not nearest-neighbour.
   - Close small holes (where a strap or hair crosses the garment).
   - Subtract the arm, hand and face labels, so skin over a sleeve doesn't stay in.
   - Keep the largest connected part.
   - Feather the edge by 1–2 px, and zero the hidden RGB as `birefnet.ts` already does.
   - Frame it on the same transparent square as catalogue cut-outs, so wardrobe pieces look
     consistent in Studio.
   - Worth testing: run BiRefNet **on the crop only** (small, so cheap) and intersect it with the
     parser mask for sharper edges. Keep it only if it visibly helps on real photos.
5. **Score each crop**, so the best one represents the piece later. Higher is larger. It drops when
   the crop touches the photo edge (cut off) or a lot of it is hidden by an arm or a bag.
6. **Embed each crop** with a CLIP or SigLIP image model through `@huggingface/transformers` (for
   example `Xenova/clip-vit-base-patch32`, 512-d). Also store a small LAB colour histogram, so two
   tees of the same cut but different colours aren't folded together.
7. Mark the photo done and add 1 to `photos_done`. When every photo is done and `last` has
   arrived, send `wardrobe-import/group`.

**`wardrobe-import/group`** runs once per import (`stage = grouping`).
1. **Fold repeats.** Within each slot, cluster the import's crops by cosine similarity (start
   around 0.88) **and** close colour. Tune both on the founder's real photos.
2. Each cluster becomes one piece. Its cut-out is the cluster's best-scoring crop, and its dates are
   every `taken_on` in the cluster.
3. **Already owned?** Compare each cluster with the user's existing `wardrobe_items` in the same
   slot. On a match, don't create a piece: add the dates to that item's wear history (#3) and count
   it in `alreadyOwned`.
4. Otherwise create a `wardrobe_items` row: `origin 'import'`, `status 'ready'`, the cut-out, and
   the embedding. Tag it with the existing tagger **once per piece**, not once per crop.
5. Write the wear history (#3). Set `status = done`, the counts and `finished_at`. Then send the
   push (#4).
6. On an unrecoverable error, set `status = failed` and still send a push saying it stopped.

**`wardrobe-import/cleanup`** runs every hour.
- Delete the originals and leftover crops **24 hours after `finished_at`** (the privacy policy
  promises this).
- Delete slots never confirmed.
- An import with no `last` after 2 hours, or stuck in `processing` for 6 hours, becomes `failed`,
  and its files are cleaned up.

**Running it locally (founder's call for prototyping).** The models already run on the CPU or
DirectML (`onnx-device.ts`), so the founder's Windows laptop can do the work:
1. `npm run dev` (port 3001) and `npx inngest-cli@latest dev -u
   http://localhost:3001/api/inngest`, as in the README.
2. The phone reaches the laptop through `adb reverse tcp:3001 tcp:3001`.
3. The app runs with `flutter run --dart-define-from-file=config/local.json` (on the app branch;
   `API_BASE_URL=http://localhost:3001`). Debug builds allow plain HTTP to `localhost` for this.

Whether the local API points at the hosted Supabase project (simplest: the same sign-in and data)
or at a local stack is your call. Please add the steps to the README. A separate worker or a GPU
host is a later conversation with the founder, once real timings exist. **Please record the time
per photo and per import on the laptop.**

### 3. Wear history on `WardrobeItem` (needed; the app reads it today)

Add to `WardrobeItem`:
- **`wearCount`**: the number of days.
- **`lastWornOn`**: `YYYY-MM-DD`, or null.
- **`wornOn`**: `YYYY-MM-DD[]`, newest first, at most 30.

Count them from the worn calendar: the import writes one `worn_log` row per photo day
(`isPlanned: false`, the item ids from that photo), so the calendar shows them too. Add a `source`
column (`photo|manual`) if you want to tell them apart. The app shows:
- "WORN 4× · 14 FEB" on the cards;
- a Most worn / Least worn sort;
- a "Not worn lately" shelf (last worn over 180 days ago);
- a Wear history card on the item page.

Items without these fields just don't show them. Also return **`origin: 'import'`** for these
items (the app labels them "From your photos").

### 4. Push notifications (needed for "it's ready" after the app is closed)

The app's local notifications only work while its process is alive. The foreground service covers
switching apps, but not swiping Drip away. For that we need Firebase Cloud Messaging:

1. **Founder (manual).** Create a Firebase project. Add the Android app `com.drip.drip` and download
   `google-services.json` for the app. Create a service account with the "Firebase Cloud Messaging
   API" role for the backend.
2. **Backend.**
   - Add `POST /me/push-tokens { token, platform: android|ios }` (an upsert) and `DELETE
     /me/push-tokens/:token`, backed by a table `push_tokens(user_id, token, platform,
     updated_at)`.
   - When an import ends, send an FCM HTTP v1 message to the user's tokens: `notification: { title:
     "Your wardrobe is ready", body: "23 new pieces are in your wardrobe." }`, `data: { route:
     "wardrobe", importId }`.
   - Delete tokens FCM reports as `UNREGISTERED`.
   - Account deletion removes the user's tokens.
3. **App.** Once `google-services.json` exists, I'll add `firebase_messaging`, register the token
   after sign-in and route taps to `/wardrobe`. The local notifications stay for the in-app case.

### 5. Reports can carry the wardrobe piece (small)

Each wardrobe piece's page has "Cut-out look off? Report it". It sends `POST /reports` with `kind:
"image"`, `screen: "wardrobe.item"` and a new **`wardrobeItemId`** (uuid). That field is ignored
today as unknown. Please store it (a nullable column on `bug_reports`) so a bad cut-out can be
found. Admin tooling that shows the cut-out would make these quick to triage. The message can be
the app's default ("The cut-out of this piece looks off.") when the user writes nothing.

### 6. The user's own clothes in the feed (nice to have; the founder asked for it)

"Start using those clothes in the feed as well."
- Match each wardrobe piece's embedding to catalogue garments in the same slot (nearest neighbour
  above a threshold).
- In `GET /scroll` and the Home feeds, boost fits that contain a matched garment a little. Send
  **`owned: true`** on those pieces in `Outfit.pieces`.
- The app already reads `owned` (optional). The piece sheet then says "YOU OWN ONE LIKE THIS"
  instead of "IN THIS FIT".

Taylor's "only my wardrobe" already uses the wardrobe. Gap picks (what the closet is missing) can
come later.

### Privacy promises (the app's policy now says these, so the backend must keep them)

- Drip only receives the photos the user picks. The phone sets the others aside before upload.
- Only clothes are kept. Faces and backgrounds are thrown away.
- **Photos are deleted from our servers within 24 hours of the pieces being cut out.**
- The day a photo was taken becomes the piece's wear history.
- Imported pieces are private to the user, like every wardrobe item.

## 2026-10-09: fits in the user's price range, and the style quiz

### Status of earlier requests

| Request | Status |
|---|---|
| 10-06 #1 username and display name | **Done** (in `docs/API.md`). |
| 10-05 #3 saved pieces, #4 paging, #5 material | Still open, all low priority. |

### 1. Keep the Scroll in the user's price range (needed: the founder's top complaint)

**What's wrong.** Onboarding asks "usual spend a piece" (`onboardingPrefs.budget`, ₹500–15,000).
In `personalize.ts` that's one soft term, `+0.8 × fitBudget`, beside collage score, colour (0.7),
style, occasions and behaviour. A pricey fit that scores well on the others still lands near the
top, so a ₹2,000 user sees ₹12,000 fits early. A fit with no priced pieces gets no budget penalty,
so it beats a fit that's slightly over budget. This is a ranking problem, not an app one: the app
already sends the budget, and the feed comes back in the server's order.

**Don't add storage buckets or a table per price range.** Storage buckets hold files, not fits.
Copying fits into a table per price range duplicates rows, goes stale when a store changes a price,
and would make the app page across buckets itself. One sort key in the ranking does the same job
and keeps prices in one place.

**Short v1: price bands as the first sort key in `GET /scroll`.**
1. Find the user's limits.
   - Each piece: `budget` (per piece).
   - The whole fit: from the new quiz answer `onboardingPrefs.quiz.spend` (see #2):

     | `spend` | Fit limit |
     |---|---|
     | `u2k` | ₹2,000 |
     | `2to5k` | ₹5,000 |
     | `5to10k` | ₹10,000 |
     | `10kplus` | no limit |

     If they haven't answered it, there's no fit limit.
2. Give each fit a band from its priced pieces (`price_inr > 0`):
   - **`in`**: every priced piece is at most 1.2 × `budget`, and the fit's total is within the fit
     limit (if there is one).
   - **`stretch`**: no piece is over 2 × `budget`, or the total is at most 1.5 × the fit limit.
   - **`over`**: everything else.
   - **`null`**: no priced pieces, or no budget. Rank these with `stretch`.
3. Order by band (`in`, then `stretch`/`null`, then `over`), then by today's score within each band.
   The user gets every fit in budget first, and the next band only when those run out: the
   "when one bucket ends, show the next" idea, as a sort rather than storage. The existing
   per-user, per-day, per-prefs cache and the cursor keep working, because the order is still
   fixed for the day. A `PATCH /me` that changes `budget` or `quiz` already re-ranks.
4. Return the band on each `Outfit`: **`budgetBand: "in" | "stretch" | "over" | null`**.
   - The app reads it today (optional; missing is fine).
   - The Scroll's shop strip says "· in your budget" for `in` and "· above your budget" for
     `over`, so a price jump past the end of a band isn't a surprise.
5. Keep the budget term in the score; it now only orders fits within a band.

**Worth checking in the catalogue.** If few fits come in under ₹2,000–3,000 a piece, the `in`
band runs out in a few swipes whatever we rank. A count of fits per band for a few budgets
(₹1,500 / ₹3,000 / ₹6,000) would show what the pipeline should bank more of.

**Also note.** Onboarding's budget is per piece, but the Scroll shows the fit's total. A
four-piece fit at ₹2,000 a piece shows "₹8,000 total" to a ₹2,000 user and *looks* over budget
even when it's `in`. The band label in the app is there for exactly this.

### 2. Use the style quiz in the ranking (nice to have: the answers are already saved)

**What the app does.**
- Home's **Style Quiz** tile (it used to say "after beta") opens 10 one-tap multiple-choice
  questions. Every question can be skipped.
- Answers are saved with the existing `PATCH /me`, inside `onboardingPrefs`. The other keys are
  kept, and the payload is small, well under the 4,096-char cap.
- No new endpoint or column is needed.

```
onboardingPrefs.quiz = {
  "v": 1, "at": "2026-10-09",          // version and day answered (UTC)
  "spend":   "u2k" | "2to5k" | "5to10k" | "10kplus",            // whole-outfit budget
  "buy":     "deal" | "exact" | "styled" | "brand",             // what makes them buy
  "next":    "work" | "night" | "trip" | "function" | "everyday",  // dressing for next
  "volume":  "quiet" | "statement" | "loud" | "mood",           // how bold
  "colour":  "neutral" | "pop" | "full" | "black",              // colour comfort zone
  "matters": "comfort" | "cut" | "fabric" | "trend",            // what matters in a piece
  "where":   "highstreet" | "marketplace" | "local" | "thrift", // where they shop
  "when":    "sales" | "need" | "monthly" | "impulse",          // when they shop
  "weather": "humid" | "dry" | "mild" | "cold",                 // climate
  "explore": "safe" | "mix" | "push"                            // how adventurous the feed is
}
```
Any key can be missing (skipped). The question ids and option ids are stable. The screen copy is
in `lib/features/quiz/style_quiz.dart`.

**Short v1, cheapest first:**
- `spend`: the fit limit in #1. This is the one that matters for buying.
- `next`: map it onto `/meta` occasions, then reuse the existing `+0.25` occasion term.

  | `next` | Occasions |
  |---|---|
  | `work` | the work/college ones |
  | `night` | night out, late-night dinner |
  | `trip` | travel |
  | `function` | wedding, festive |
  | `everyday` | casual |

- `colour`:
  - `neutral` or `black`: treat as `paletteHasNeutral` with extra weight.
  - `full`: soften the palette-miss penalty.
- `volume` and `explore`:
  - `quiet` or `safe`: rank down the fits furthest from the user's aesthetics.
  - `loud` or `push`: let roughly 1 in 5 cards come from outside their aesthetics.
- `weather`:
  - `humid` or `dry`: rank down wool, fleece, leather and puffers.
  - `cold`: rank up layers and outerwear.
- `buy = deal` or `when = sales`: rank up pieces with an `original_price` above `price`, once the
  catalogue has sale prices.
- `where`, `matters`: keep for later; store-type and fabric data aren't in the catalogue yet.

## 2026-10-06: usernames and display names, and where earlier requests stand

### Status of earlier requests

| Request | Status |
|---|---|
| 10-05 (later) #1 `POST /reports` | **Done and live.** The app keeps a report on the phone on 429, 5xx or offline, and resends it. |
| 10-05 (later) #2 public profile photo on account deletion | **Closed.** The API has no public user content, and the app's photo handling is being reworked on the app side (no backend work). |
| 10-05 #1 garment `id` on `Outfit.pieces` | **Done.** + WARDROBE and + STUDIO in the Scroll use it. |
| 10-05 #2 `buyUrl` on `StudioPiece` | **Done.** VISIT shows for every catalogue piece in the Studio picker. |
| 10-05 #3 saved pieces, #4 paging, #5 material | Still open, all low priority. |
| 10-03 Studio canvas and occasion feeds | Done. |

### 1. Username and display name (needed: the profile editor calls these today)

**Why.** The profile editor (You → edit profile) lets users pick an @username and a display name.
`PATCH /me` accepts only `onboardingPrefs`, `skinTone` and `styleTags`, so both edits fail with
a 400 today, and `GET /me/username-available` is a 404.

**What the app does today.** It shows the fields, checks the username rules on the phone, and
shows the server's error when saving. Until this ships, people see their Google name.

**Contract the app already sends and reads:**

```
PATCH /me { "username": "vighnesh.k" }
  → 200, the same body as GET /me (the app reads `username` at the top level or `user.username`)
  → 409 { error } when it's taken; 400 { error } when it breaks the rules

PATCH /me { "displayName": "Vighnesh" }      // 1–40 chars after trimming
PATCH /me { "displayName": null }            // clear it: back to the Google name
  → 200, the same body as GET /me (`displayName` at the top level or `user.display_name`)

GET /me/username-available?u=vighnesh.k
  → 200 { "username": "vighnesh.k", "available": true }
  → 200 { "username": "drip", "available": false, "reason": "That username is reserved" }

GET /me  → also returns "username" and "displayName" (null until set)
```

**Username rules** (the app checks the same ones first, in `usernameProblem` in
`lib/data/repositories/account_repository.dart`; please mirror them exactly):
- `^[a-z0-9._]{3,24}$` (lower case: the app lower-cases what's typed)
- at least one letter or number
- reserved: `drip, admin, support, help, official, team, taylor, staff, me, settings, api`
- unique, case-insensitively

**Short v1.** Migration (schema change: founder approval): `users.username text null` with a
unique index on `lower(username)` and a check constraint for the pattern; `users.display_name
text null` with `char_length(trim(display_name)) between 1 and 40`. Extend the `PATCH /me` zod
body with `username` and `displayName` (nullable), and map a unique violation to 409. Add
`GET /me/username-available` (auth required, rate-limited like other reads; it may answer
`available: false` with `reason` instead of 400 for a bad pattern).

**Privacy.** The app's privacy policy says nothing a user adds is public in the beta. So keep
both visible only to their owner (`GET /me`) until there are public profiles. When those ship,
the app updates the policy first. `DELETE /me` already removes the row.

---

## 2026-10-05 (later): bug reports and the privacy policy (done)

### 1. `POST /reports`: bug reports from the app (needed; one new table, founder approval)

**Why.** The feed now has a **Report a bug** button (below Share). The user picks a kind, writes
what happened, and can attach the fit on screen.

**What the app does today.** It posts to `/reports`. On 404 (not deployed), a network error or a
5xx, it keeps the report on the phone (up to 20) and sends the waiting ones with the next report.
A 400 drops it rather than retrying forever.

**Contract the app sends** (signed-in users only, `Authorization: Bearer`):

```json
POST /reports
{ "kind": "broken | wrong_piece | image | slow | other",
  "message": "The shoes link opens a hat",        // 3–1000 chars
  "screen": "scroll",
  "fitId": "uuid",                                // optional: the fit on screen
  "appVersion": "1.0.0+1",
  "platform": "android 14 …",                     // Platform.operatingSystem + version
  "createdAt": "2026-10-05T15:20:00.000Z" }       // when the user sent it (may be earlier than receipt)
→ 201 { "id": "uuid" }
```

**Short v1.** Migration `…_bug_reports.sql`: `bug_reports (id uuid pk, user_id uuid references
users on delete cascade, kind text check in (…), message text check length 3–1000, screen text,
fit_id uuid null, app_version text, platform text, reported_at timestamptz, created_at timestamptz
default now(), status text default 'new')`. RLS: a user can insert their own and read none (admins
read via the service role or an admin view). Zod-validate the body, rate-limit like other writes
(for example 10 an hour), and capture a PostHog `bug_reported` event with `kind` only. No
attachments in v1.

**Privacy.** The app's policy says reports carry only the above (never photos) and are deleted
with the account. The `on delete cascade` covers the second part.

### 2. Account deletion must remove the public profile photo

The app's new privacy policy says deleting the account removes everything, straight away.
`DELETE /me` removes the private bucket's files. Please check it also removes the **public**
profile photo (`/me/photo`, from the profile-editing work) and any copies in the CDN, and add it
if not.

## 2026-10-05: shop the look (Scroll) and the Studio piece picker (#1, #2 done)

**Context.** Tapping a garment in a Scroll collage now opens a sheet with the fit's pieces. Each
piece has BUY, **+ STUDIO** (puts it on the Studio canvas) and **+ WARDROBE**
(`POST /wardrobe/items { garmentId }`). The Studio's new piece picker has a **Saved** tab and a
VISIT button. Branch `feat/studio-picker` in drip-front.

### 1. A garment id on `Outfit.pieces` (needed; tiny, no schema change)

**Why.** + WARDROBE and + STUDIO need the piece's garment id, and `OutfitPiece` (in
`src/domain/outfit.ts`) doesn't carry one.

**What the app does today.** It looks the piece up with `GET /studio/pieces?slot=&subcategory=`
and matches by cut-out URL, then by title. That endpoint returns only the newest 50 per slot, so
older garments aren't found, and the user sees "This piece isn't in the Drip catalogue yet".

**Short v1.** Add `id` (the `garments.id`) to `OutfitPiece`. `loadOutfits` already selects
`fit_items → garment`; add `id` to that select and to the mapped piece. The app reads `id` (or
`garmentId`) and stops matching once it's there.

```ts
export interface OutfitPiece {
  id: string | null; // garments.id: for POST /wardrobe/items and Studio fits
  name: string | null;
  …
}
```

### 2. `buyUrl` on `StudioPiece` (nice to have; no schema change)

**Why.** The Studio picker's VISIT button needs the store page. `garments.buy_url` exists, but
`StudioPiece` doesn't return it.

**What the app does today.** It shows VISIT only for pieces it has seen in the user's saved or
liked fits (it takes their `buyUrl` from those).

**Short v1.** Add `buy_url` to `GARMENT_COLS` in `src/api/user-fits.ts` and
`buyUrl: g.buy_url ?? null` to `garmentPiece()`. Wardrobe pieces stay `null`.

### 3. The user's saved pieces for the Studio picker (nice to have)

**Why.** The picker's **Saved** tab shows the catalogue pieces from fits the user saved or liked.

**What the app does today.** It reads `GET /studio` (saved and liked fits), then fetches
`/studio/pieces` for the slot and keeps the pieces that match by cut-out or title. It's capped by
the same 50-newest limit.

**Short v1.** `GET /studio/pieces?slot=&source=saved`: the published garments in that slot that
appear in the caller's `saved_fits` or liked fits, newest save first, as `StudioPiece[]`. Once
it's there, the app calls it for the Saved tab.

### 4. Paging on `GET /studio/pieces` (later)

The catalogue tab stops at the newest 50 per slot (`.limit(50)`). A `cursor` (the same
offset-style one as `/scroll`) would let the picker keep loading as the user swipes. Not urgent at
today's catalogue size.

### 5. Material (later, only if the pipeline has it)

The founder wants the piece's material in the sheet ("cotton", "denim"). `garments` has no
material column, so this depends on the catalog pipeline or the discovery products
(`DripProduct.material`) extracting it. If it lands, add `material: string | null` to
`OutfitPiece` and `StudioPiece`; the app has a line for it.

---

## 2026-10-03: Studio canvas and occasion feeds (done)

Shipped in `feat/app-requests-1003` with migration `…0012`. The app uses it: every accessory, box
and z saved on user fits; `GET /scroll?occasion=`; `home: true` occasions; `brand` on Studio
pieces. The original write-up follows for reference.

### 1. Studio fits: several accessories, and where each piece sits

**Why.** The Studio canvas now lets users place pieces anywhere and resize them, and wear up to
6 accessories (bag, eyewear, watch, jewellery…). `user_fit_items` has `primary key (user_fit_id,
slot)` and the API refuses two items with the same slot, so a fit can hold one accessory and no
placement.

**What the app does today.** It saves one accessory to the server and keeps the extra accessories
and every piece's position on the phone (SharedPreferences, keyed by fit id). Extras don't count
toward the drip rate and don't sync across devices.

#### Short v1 solution (one migration, small API change)

Migration `…0012_user_fit_canvas.sql`:

```sql
alter table public.user_fit_items
  add column position int not null default 0,   -- 0 for core slots; 0..5 for accessories
  add column box_x real, add column box_y real,  -- placement, fractions of the canvas (0–1)
  add column box_w real, add column box_h real,
  add column z int;                              -- draw order, higher = on top
alter table public.user_fit_items drop constraint user_fit_items_pkey;
alter table public.user_fit_items add primary key (user_fit_id, slot, position);
alter table public.user_fit_items add constraint user_fit_items_position_ck
  check ((slot = 'accessory' and position between 0 and 5) or (slot <> 'accessory' and position = 0));
alter table public.user_fit_items add constraint user_fit_items_box_ck
  check (box_x is null or (box_x between -1 and 2 and box_y between -1 and 2
                           and box_w > 0 and box_w <= 1.5 and box_h > 0 and box_h <= 1.5));
```

`save_user_fit`: read `position`, `box_x/y/w/h`, `z` from each `p_items` element (all optional;
`position` defaults to 0). RLS policies are unchanged.

API (`src/api/user-fits.ts`):
- `FitBody.items[]` accepts optional `position` (int), `box: {x, y, w, h}` and `z`.
- Replace "one item per slot" with: at most one per core slot, at most 6 `accessory` items, and
  `(slot, position)` unique. `.max(CATEGORIES.length)` becomes `.max(11)`.
- `UserFit.pieces[]` returns `position`, `box` (or null) and `z`.
- `dripRate`: score with all accessories (or the first only, your call; tell us which).
- Catalogue outfits allow at most 4 accessories, one per kind (`MAX_ACCESSORIES`, `docs/FITS.md`).
  The app currently allows 6 of any kind. If you'd rather user fits follow the same rule, enforce
  it here and the app will match: cap at 4 and swap a same-kind accessory instead of adding it.

Contract example:

```json
POST /studio/fits
{ "name": "Beach", "items": [
  { "slot": "top", "garmentId": "…", "box": {"x":0.21,"y":0.03,"w":0.58,"h":0.4}, "z": 2 },
  { "slot": "accessory", "position": 0, "garmentId": "…", "box": {"x":0.8,"y":0.2,"w":0.17,"h":0.2}, "z": 5 },
  { "slot": "accessory", "position": 1, "wardrobeItemId": "…" }
] }
```

`box` absent or null means "put it where the layout says", which is what the app does for pieces
the user hasn't moved.

**Once it ships,** the app sends every accessory and every box, reads them back, and stops keeping
them on the phone. Fits saved before then keep working (no boxes = layout positions).

*Even faster stopgap, not recommended:* a `user_fits.canvas jsonb` blob the app owns. It skips
RLS checks on the extra pieces (the publish gate) and would store image URLs that expire, so the
item-row change above is worth the extra hour.

### 2. `GET /scroll?occasion=<id>`

**Why.** Home now has "Shop by occasion" cards; tapping one opens the Scroll on fits for that
occasion.

**What the app does today.** It pages through the normal ranked `/scroll` and keeps fits whose
`formality` falls in a band it picked per occasion. That reads up to 6 pages per screen and gets
thin quickly.

**Short v1 solution.** Accept an optional `occasion` on `/scroll`: filter the ranked candidates by
the occasion's formality band (and prefer its vibe styles if you like), keep the same cursor and
paging, and cache the ranked list per `(user, day, occasion)`. 400 for an unknown id.

Add the missing ones to `OCCASIONS` in `src/domain/meta.ts` (ids and bands as the app uses them
now; adjust the bands freely):

| id | label | formality |
|---|---|---|
| date-night | Date night | 2–4 |
| concert | Concerts | 1–3 |
| late-night-dinner | Late-night dinner | 3–4 |
| university | University | 1–2 |
| parties | Parties | 1–3 |
| clubs | Clubs | 2–4 |
| picnics | Picnics | 1–2 |
| derbies | Derbies | 4–5 |
| golf | Golf | 2–3 |
| sports | Sports | 1–2 |
| family-events | Family events | 2–4 |
| wedding | Weddings | 4–5 |

`date-night`, `concert` and `wedding` already exist with these bands, and the app now uses the same
ids. The other nine are new. Taylor's occasion picker lists every `OCCASIONS` label, so if the Home
ones shouldn't all show up there, add a flag such as `home: true` rather than a second list.

### 3. Nice to have (not blocking)

- **A display title on `Outfit`.** The app shows `colourStory` as the title ("blue · brown · black
  · grey"), which reads like a tag list. Even a generated "Navy shirt + cargo" would be better.
- **`brand` on Outfit pieces and Studio pieces.** The cards and Fit Analysis have a slot for it.

### Not needed for v1

Search, Discover, the wardrobe rotation flag and the social layer stay "after beta" in the app.
