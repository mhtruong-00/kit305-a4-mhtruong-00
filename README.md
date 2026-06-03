# KIT305 Assignment 4 — Interior Design Quoting App (Flutter)

A cross-platform Flutter port of my Assignment 2 (Android) / Assignment 3 (iOS)
**interior design quoting tool** for salespeople. The app lets a salesperson
manage houses (job sites), record rooms, measure windows and floor spaces,
choose products/variants from a live API, and generate an itemised, shareable
quote.

---

## Recommended Device / Simulator

- **Android emulator** — Pixel 6, **API 34 (Android 14)**, portrait.
- Also runs on an **iOS Simulator** (iPhone 15, iOS 17) and in **Chrome** (web)
  for quick testing.
- Minimum Android SDK is **23** (required by Firebase).

### Before running — Firebase setup (marker note)

This repo ships with a **placeholder** `lib/firebase_options.dart` so the
project compiles. To connect to a Firestore database, regenerate the real
config with the FlutterFire CLI from the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then run:

```bash
flutter pub get
flutter run
```

The Firestore schema matches my Android/iOS apps (top-level `houses`, `rooms`,
`windows`, `floorspaces` collections), so the same database can be reused.

---

## App Screens and How They Interrelate

| Screen | Purpose | Navigates to |
| --- | --- | --- |
| **HouseListScreen** | Live list of all houses with search, add, swipe-to-delete, edit, and a Quote action. Home screen. | HouseEditScreen, RoomListScreen, QuoteScreen |
| **HouseEditScreen** | Add/edit a house (customer name, address, free-form **Notes**). Validates non-empty name and an address containing at least one letter. | pops back on save |
| **RoomListScreen** | Live list of rooms for a house with search, add (dialog), rename, **duplicate** (leading swipe — copies all windows + floors), and delete. Rows show a photo thumbnail. | RoomDetailScreen, QuoteScreen |
| **RoomDetailScreen** | A room's cover photo (gallery) plus two sections — **Windows** and **Floor Spaces** — each with add/edit/swipe-delete. | WindowEditScreen, FloorSpaceEditScreen |
| **WindowEditScreen** | Add/edit a window: width × height (mm), product + variant, gallery photo, live price preview. Validates 1–20 000 mm. | ProductListScreen |
| **FloorSpaceEditScreen** | Add/edit a floor space: width × depth (mm), product + variant, gallery photo, live price preview. Validates 1–20 000 mm. | ProductListScreen |
| **ProductListScreen** | Loads products from the KIT305 API filtered by category, with search and window **compatibility** checking (panel fitting). | ProductVariantScreen, returns selection |
| **ProductVariantScreen** | Lists the variants of the chosen product and returns the selected variant. | returns variant |
| **QuoteScreen** | Per-room sectioned quote with include/exclude switches per room **and** per item, a coloured **Notes** banner, subtotal / labour / **discount %** / final total, and **CSV share**. | system share sheet |

### Navigation flow

```
HouseListScreen
 ├── HouseEditScreen           (add / edit)
 ├── RoomListScreen
 │     ├── RoomDetailScreen
 │     │     ├── WindowEditScreen ── ProductListScreen ── ProductVariantScreen
 │     │     └── FloorSpaceEditScreen ── ProductListScreen ── ProductVariantScreen
 │     └── QuoteScreen
 └── QuoteScreen               (from house list)
```

### Custom features (carried over from A2/A3)

- **Discount tool** — enter a 0–100 % discount on the quote screen; the final
  total and CSV update live.
- **Notes** — a per-house notes field that appears as a banner when generating
  the quote.
- **Duplicate room** — swipe a room right to copy it (with all of its windows
  and floor spaces), so repeated layouts don't need re-measuring.

---

## Product API

- All products: `https://utasbot.dev/kit305_2026/product`
- Window products: `https://utasbot.dev/kit305_2026/product?category=window`
- Floor products: `https://utasbot.dev/kit305_2026/product?category=floor`

---

## References

| Resource | URL / Description |
| --- | --- |
| KIT305 tutorial material | University of Tasmania KIT305 unit tutorials (Flutter, Firestore, networking). Built upon as permitted; not individually referenced. |
| My own Assignment 2 (Android) and Assignment 3 (iOS) | The data model, validation rules, quote/labour/discount maths, compatibility logic, and CSV format were designed by me in those assignments and re-implemented here in Dart. |
| Flutter `cloud_firestore` docs | <https://pub.dev/packages/cloud_firestore> |
| Flutter `image_picker` docs | <https://pub.dev/packages/image_picker> |
| Flutter `share_plus` docs | <https://pub.dev/packages/share_plus> |
| KIT305 Product API | <https://utasbot.dev/kit305_2026/product> |

### Third-party plugins

See **`THIRD_PARTY_PLUGINS.md`** for the full list of pub.dev plugins, authors,
and where each is used.

### Generative AI acknowledgement

I used **GitHub Copilot** as an assistant to help port my existing iOS
(Assignment 3, UIKit/Swift) application to Flutter/Dart. Specifically, Copilot
helped translate the structure of my Swift view controllers, models, and
services into the equivalent Flutter widgets and Dart classes, and helped with
boilerplate such as `StreamBuilder` wiring, `Dismissible` swipe actions, and
Firestore query syntax.

The application design, data model, Firestore schema, validation rules, and all
business logic (quote/labour/discount maths and the product-compatibility
panel-fitting algorithm) are my own, carried over from my Android (A2) and iOS
(A3) assignments. Every AI suggestion was read, edited, and tested (including
the unit tests in `test/logic_test.dart`) before being kept.

> I did not paste large blocks of code from any online template or repository
> other than my own previous assignment work and the KIT305 tutorial material.

---

## Running the tests

```bash
flutter test
```

Unit tests in `test/logic_test.dart` cover the quote calculator (rates, labour,
discount) and the product compatibility checker (panel fitting).

