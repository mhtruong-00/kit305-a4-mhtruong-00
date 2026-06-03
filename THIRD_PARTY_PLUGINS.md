# Third-Party Plugins — KIT305 Assignment 4

All plugins below are added via `pubspec.yaml` from [pub.dev](https://pub.dev).
None of them provide the majority of the app's functionality; they are
infrastructure/UI helpers only.

| Plugin | Link | Author / Publisher | Where it is used in the app |
| --- | --- | --- | --- |
| `firebase_core` | <https://pub.dev/packages/firebase_core> | Firebase (firebase.google.com) | Initialises Firebase in `main.dart` before the app starts. |
| `cloud_firestore` | <https://pub.dev/packages/cloud_firestore> | Firebase (firebase.google.com) | All data persistence — `FirestoreService` reads/writes the houses, rooms, windows and floorspaces collections. |
| `image_picker` | <https://pub.dev/packages/image_picker> | Flutter Team (flutter.dev) | Picking a photo from the gallery in `PhotoPicker`, used by the room/window/floor edit screens. |
| `http` | <https://pub.dev/packages/http> | Dart Team (dart.dev) | Fetching products from the KIT305 product API in `ProductAPI`. |
| `share_plus` | <https://pub.dev/packages/share_plus> | Flutter Community (fluttercommunity.dev) | Sharing the generated quote CSV from `QuoteScreen`. |
| `path_provider` | <https://pub.dev/packages/path_provider> | Flutter Team (flutter.dev) | Getting the temporary directory to write the quote CSV file before sharing. |
| `intl` | <https://pub.dev/packages/intl> | Dart Team (dart.dev) | Formatting the timestamp used in the exported CSV file name. |
| `cupertino_icons` | <https://pub.dev/packages/cupertino_icons> | Flutter Team (flutter.dev) | Icon font included by default in the Flutter template. |

