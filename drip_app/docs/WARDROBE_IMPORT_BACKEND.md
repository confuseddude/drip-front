# Wardrobe from gallery photos: backend brief (start here)

**For:** the backend session. **From:** the app session, 2026-10-21. **Founder's priority: the
cut-outs.** Get clean cut-outs from real outfit photos first, then wire them into the import API.
The app side is done and on the founder's phone. It waits on `POST /wardrobe/imports`.

The full request with every field is in `BACKEND_REQUESTS.md` (same folder) → "2026-10-21" (#1–#6). This page
is the order of work, the bar for "clean", and the contract the app already speaks. The design doc
the founder approved: https://claude.ai/code/artifact/737ac4aa-2baf-49e0-b431-bb4bd9ac0e77.

## What the founder decided

- The user picks up to **50 photos** with the system photo picker (no gallery permission).
- **One person per photo** for now. Groups come in the next update; the phone sets most aside.
- **No review screen.** Pieces go straight into the wardrobe, so **repeats must be folded on the
  server**: a tee seen in 9 photos is one piece.
- **Wear history** from each photo's day.
- **Cut-outs as clean as possible.** No generated "product shots" for now.
- **Run it locally** on the founder's Windows laptop for prototyping. A worker or GPU host is
  decided later, from real timings.
- Push notifications are **parked**. The app uses local notifications for now.

## Order of work

### M1. A cut-out script and a contact sheet (do this first)

Build a script, for example `scripts/import-cutouts.ts <folder>`. For every photo in the folder,
it runs the pipeline below and writes:
- each piece's cut-out as a PNG;
- one **contact sheet** (HTML or a big PNG): the photo, then its pieces with slot, quality score
  and skip reason.

It needs no API, no database and no Inngest. It's the fastest loop for making the cut-outs good.

- **Test photos:** ask the founder for 20–30 of their own outfit photos. Ask for mirror selfies,
  full-body shots, a few awkward ones (bag across the body, hand in a pocket, layered jacket) and
  2–3 photos of the same outfit. Keep them in a **gitignored** folder (e.g.
  `_import-samples/`). They're private photos and must never be committed.
- **Report back** the contact sheet, the time per photo on the laptop, and where it falls short.

### M2. The import API and jobs, end to end with the phone

These are the endpoints and the `wardrobe-import/photo` job (contract below). Each photo's pieces
become wardrobe items with no folding yet, so the founder can run the full flow from the phone
against the laptop. Then add `wardrobe-import/cleanup`.

### M3. Folding repeats and "already owned"

Add the `wardrobe-import/group` step. Tune its thresholds on the M1 photos (the 2–3 repeated
outfits must fold into one piece each).

### M4. Wear history on `WardrobeItem`

Add `wearCount`, `lastWornOn` and `wornOn`, filled from `worn_log`. The app already shows them.

### M5. `wardrobeItemId` on `/reports`

Store the new field, so "Cut-out look off? Report it" reports are traceable.

**Later:** push tokens and FCM (#4), and `owned: true` on feed pieces (#6).

## The cut-out pipeline (per photo)

1. **Load.** Fix the photo's rotation. Keep the full image (the app sends 1600 px on the long
   edge) for the crops, and run `segformer_b2_clothes` at 1024, as `segmentClothes()` does.
2. **Skip** the photo, and record why, when:
   - there's no person, or the person is tiny;
   - there are **two or more large, separate person blobs** (a group).
3. **Split it into pieces** using the parser's ATR labels:

   | Labels | Slot |
   |---|---|
   | `Upper-clothes` | top or outer (the parser can't tell them apart; the tagger decides) |
   | `Pants`, `Skirt` | bottom |
   | `Dress` | dress |
   | `Left-shoe` + `Right-shoe` | **one** shoes piece (union of both) |
   | `Bag`, `Belt`, `Scarf`, `Hat`, `Sunglasses` | accessory |

   Ignore face, hair, skin, arms, legs and background. Drop regions under about 1.5 % of the
   person's area.
4. **Clean the mask.** This is where "clean" is won:
   - Scale the mask up to full resolution with a **smooth** resize (not nearest-neighbour), then
     threshold it.
   - Close small holes (a strap, hair or a necklace crossing the garment).
   - **Subtract the arm, hand and face labels**, so skin over or beside a sleeve doesn't stay in.
   - Keep the largest connected part. Drop specks.
   - Feather the edge by 1–2 px. Zero the hidden RGB, as `birefnet.ts` does, so no halo appears
     when it's resized.
   - Frame it on the **same transparent square as catalogue cut-outs**, so wardrobe pieces sit
     right in Studio.
   - Try BiRefNet **on the crop only** (small, so cheap), intersected with the parser mask, for
     sharper edges. Keep it only if the contact sheet shows it helps.
5. **Score each piece's quality** (0–1).
   - **Higher:** bigger.
   - **Lower:** touches the photo edge (cut off), or a large share is hidden (an arm or bag over
     it).
   - Mark a piece **unusable** when it's mostly cut off or mostly hidden, and leave it out.
6. **Embed it** with a CLIP or SigLIP image model through `@huggingface/transformers` (for example
   `Xenova/clip-vit-base-patch32`, 512-d). Also store a small LAB colour histogram, so the same cut
   in two colours isn't folded together.

**"Clean" means:**
- no background;
- no skin, hands or hair inside the piece;
- no bits of a neighbouring garment;
- smooth edges, with no stair-steps or halos;
- shoes as one pair;
- nothing visibly cut off.

The founder judges by eye on the contact sheet. Aim for most pieces being usable as they are; the
ones that aren't should be scored low and dropped, not shipped. A missing piece is better than an
ugly one, since there's no review screen.

## The API the app already calls (please keep it exactly)

| Method | Path | Body → response |
|---|---|---|
| POST | `/wardrobe/imports` | `{ count }` (1–50) → `201 { id, uploads: [{ uploadUrl, path }] }`. 409 if one is already `processing`; 429 over 3 a day. Sniff each photo's real type (JPEG, PNG or WebP). |
| POST | `/wardrobe/imports/:id/photos` | `{ photos: [{ path, takenOn? }], last }` → `202 { photosTotal }`. Called in batches of about 10. `takenOn` is `YYYY-MM-DD`. On `last: true`, the total is the number confirmed, and unconfirmed slots are deleted. |
| GET | `/wardrobe/imports/:id` | → `WardrobeImport` |
| GET | `/wardrobe/imports?active=true` | → `{ imports: WardrobeImport[] }` |
| DELETE | `/wardrobe/imports/:id` | → 204. Stops the jobs and deletes the photos. |

`WardrobeImport` = `{ id, status: processing|done|failed|cancelled, stage: photos|grouping,
photosTotal, photosDone, photosSkipped, piecesAdded, duplicatesMerged, alreadyOwned, createdAt }`.
`photosDone` includes skipped photos.

The app's side of this:
- It polls every 4 s while open, and every 15 s in the background.
- It shows "N new pieces · N repeats folded together".
- It refetches `GET /wardrobe/items` when the import is `done`.
- New items should have `origin: "import"` and `status: "ready"`.
- A 404 on `POST /wardrobe/imports` shows "Switching this on", so deploying is the switch.

Tables, the group step and the cleanup step are in `BACKEND_REQUESTS.md` #1–#2.

## Running it on the laptop

1. `npm run dev` (port 3001), and `npx inngest-cli@latest dev -u
   http://localhost:3001/api/inngest`.
2. The phone reaches it through `adb reverse tcp:3001 tcp:3001`.
3. The app runs with `flutter run --dart-define-from-file=config/local.json`, from the app repo's
   `drip_app` folder on branch `feat/wardrobe-import`. Debug builds allow HTTP to `localhost`.
4. Whether the local API uses the hosted Supabase or a local stack is your call. Note the choice
   in the README.
5. Record the time per photo and per 50-photo import. The founder decides on hosting from those
   numbers.

## Promises the app's privacy policy already makes

- Only photos the user picked reach us.
- Only clothes are kept. Faces and backgrounds are thrown away.
- **Photos are deleted within 24 hours of the pieces being cut out.**
- Photo days become wear history.
- Pieces are private.
- User photos are never used for training and never enter the catalogue.

## When you ship something

- Update `docs/API.md` and `docs/INTEGRATION.md` and the status table.
- Message the app session ("app ui") with what's live, so the phone can be pointed at it.
