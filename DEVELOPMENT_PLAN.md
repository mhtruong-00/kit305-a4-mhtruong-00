# Development Plan & Progress Tracker — KIT305 A4 (Flutter)

This file is the **single source of truth** for resuming work. When the user
says **"continue"**, the assistant should:

1. Open this file and find the first unchecked `[ ]` task (top to bottom).
2. Implement that one task.
3. Run `flutter analyze` and `flutter test` (both must pass).
4. Mark the task `[x]`, then commit with a clear message (one task = one commit).
5. Stop after that task (or continue to the next if asked).

> Toolchain note: Flutter SDK lives at `C:\flutter`. Prepend it to PATH in each
> shell: `$env:Path = "C:\flutter\bin;" + $env:Path`.
> iOS reference source (read-only) is cloned at `C:\Users\hgdgh\AndroidStudioProjects\A3-reference`.

---

## Project summary

Flutter port of the iOS (UIKit/Swift) **Interior Design Quoting App**.
Flow: Houses → Rooms → Windows + Floor Spaces → Product/Variant (live API) →
itemised Quote (per-room/per-item toggles, labour, discount %, notes, CSV).
Firestore schema (shared with A2/A3): top-level `houses`, `rooms`, `windows`,
`floorspaces` collections.

---

## Phase 0 — Setup & scaffolding ✅

- [x] Clone iOS reference, scaffold Flutter project (`kit305_a4`)
- [x] Add dependencies (firebase_core, cloud_firestore, image_picker, http, share_plus, intl, path_provider)
- [x] Theme: `AppColors` (purple/blue/orange) + `buildAppTheme()`

## Phase 1 — Data layer ✅

- [x] Models: House, Room, WindowItem, FloorSpace, Product (+ProductVariant), QuoteLineItem
- [x] `firestore_coerce.dart` numeric coercion helper
- [x] `FirestoreService` — CRUD, cascade delete, `duplicateRoom`, `loadQuoteData`
- [x] `ProductAPI` — fetch by category, tolerant JSON parsing
- [x] `QuoteCalculator` (+RoomQuote) — default rates, $200 labour, discount
- [x] `CompatibilityChecker` — panel-fitting logic
- [x] `CSVExporter` — multi-section CSV matching A2/A3
- [x] `ImageStore` (base64) + `PhotoPicker` (gallery only — A4 requirement)

## Phase 2 — Screens ✅

- [x] HouseListScreen (search, add, swipe edit/delete, quote)
- [x] HouseEditScreen (validation: name + address-with-letter, notes)
- [x] RoomListScreen (search, add, rename, duplicate, delete, thumbnails)
- [x] RoomDetailScreen (cover photo, Windows + Floor Spaces sections)
- [x] WindowEditScreen (dimensions, product, gallery photo, live price)
- [x] FloorSpaceEditScreen (dimensions, product, gallery photo, live price)
- [x] ProductListScreen (API load, search, compatibility)
- [x] ProductVariantScreen
- [x] QuoteScreen (per-room/item toggles, discount, notes banner, CSV share)
- [x] `main.dart` Firebase init + placeholder `firebase_options.dart`

## Phase 3 — Platform, docs, tests ✅

- [x] Android minSdk 23; iOS NSPhotoLibraryUsageDescription
- [x] README.md (device target, screens, references, AI acknowledgement)
- [x] THIRD_PARTY_PLUGINS.md
- [x] Unit tests (`test/logic_test.dart`) — quote calc + compatibility
- [x] `flutter analyze` clean, `flutter build web` succeeds, pushed to origin/main
- [x] Web platform support added
- [x] This development plan committed

---

## Phase 4 — Polish & robustness (PENDING)

Each item below is one commit-sized task. Work top to bottom.

- [x] Extract a reusable `EmptyState` widget and use it on House/Room/Product lists
- [x] Extract a reusable `LoadingIndicator` / centered spinner widget
- [x] Add pull-to-refresh (`RefreshIndicator`) to the Room list
- [ ] Add pull-to-refresh to the Room list
- [x] Show a SnackBar confirmation after adding/updating a house
- [x] Show a SnackBar confirmation after adding/updating a window and floor space
- [x] Centralise error handling into a small `showErrorSnack(context, e)` helper and adopt it across screens
- [ ] Add a confirmation SnackBar + undo affordance after deleting a room
- [ ] Add an item count summary header to RoomDetail (e.g. "2 windows • 1 floor")
- [ ] Add a per-house total preview badge on the House list rows
- [ ] Improve the Quote empty state (call-to-action to add rooms)
- [ ] Format currency via `intl` `NumberFormat.currency` instead of manual strings

## Phase 5 — UX & accessibility (PENDING)

- [ ] Add dark-theme support in `buildAppTheme()` and respect system brightness
- [ ] Add semantic labels / tooltips to icon buttons for accessibility
- [ ] Add input field focus order + "next/done" keyboard actions on edit forms
- [ ] Add an App "About" screen (version, author, references link) reachable from House list
- [ ] Add an app launcher icon (replace default) and app display name

## Phase 6 — Testing (PENDING)

- [ ] Unit test: `CSVExporter` output rows for a small quote
- [ ] Unit test: `Product.fromJson` parsing (array + wrapped payload, type coercion)
- [ ] Unit test: `QuoteCalculator` room/item exclusion behaviour
- [ ] Widget test: HouseEditScreen validation shows alerts
- [ ] Widget test: ProductListScreen renders products (with a fake API)

## Phase 7 — Submission prep (DO LAST)

- [ ] Run `flutterfire configure` with the real Firebase project (replaces placeholder)
- [ ] Manual test pass on the Android emulator (CRUD, photo gallery, quote, CSV)
- [ ] Final `flutter analyze` + `flutter test`
- [ ] `flutter clean` before exporting the ZIP (per assignment spec)
- [ ] Export ZIP via Android Studio / IDE
- [ ] Confirm GitHub repo is up to date and note the link in the submission comment

---

## Commit log mapping (for reference)

| # | Commit message (prefix) |
| --- | --- |
| 1 | Initial Flutter project scaffold |
| 2 | Add dependencies |
| 3 | Add data models + theme colours |
| 4 | Add service layer |
| 5 | Add app entry point + Firebase options + photo picker |
| 6 | Add all screens + unit tests |
| 7 | Configure platforms (Android minSdk / iOS usage strings) |
| 8 | Add README + third-party plugins doc |
| 9 | Add web platform support |
| 10 | Restore main.dart/README after flutter create overwrite |
| 11 | Add this development plan |









