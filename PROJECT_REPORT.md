# Crazy Cabz — Driver App (Project Report)

Date: 2026-02-26

## One-line summary
Flutter-based driver application with live GPS tracking, end-to-end ride lifecycle logging, and Firebase-backed persistence (Firestore + Realtime Database + Storage) that records every action and event for robust ride history and real-time rider updates.

## Elevator pitch
Built a production-capable driver app in Flutter that tracks rides from creation through completion, records all ride events and GPS history into Firebase, and mirrors active ride state to Realtime Database for live rider/dispatch updates. The system favors local-first resiliency (local storage + background sync) and is designed to keep the driver experience smooth even if cloud writes fail.

## Role & responsibilities
- Full-stack mobile engineer (Flutter / Dart): designed and implemented driver-side ride tracking and Firebase persistence.
- Features owner for ride lifecycle, live tracking, and ride history.
- Implemented robust error handling to keep app behavior local-first while safely writing to cloud services.
- Wrote documentation, testing checklist, and integration guides for backend and ops teams.

## Tech stack
- Frontend: Flutter (Dart)
- State management: flutter_bloc, riverpod
- Cloud: Firebase Firestore, Firebase Realtime Database, Firebase Storage
- Libraries: geolocator, google_maps_flutter, dio, firebase_core, firebase_auth, firebase_database, firebase_storage, hive/shared_preferences for local storage

## High-level features implemented
- Full ride lifecycle persistence: create, navigate to pickup, arrive, passenger picked up, navigate to destination, arrive at destination, complete or cancel.
- Event logging: every action is saved as a discrete event (`ride_events`) and appended to ride documents.
- GPS tracking: continuous GPS points saved to `gps_tracking` collection; route-level tracking points collected.
- Real-time mirroring: active ride state mirrored to Realtime Database (`active_rides` / `live_tracking`).
- Local-first behavior: active ride and ride history stored locally (Hive/shared_preferences); cloud writes wrapped in try/catch.

## Architecture summary
- Client (Flutter) — primary write and source of truth for driver actions.
- Local cache — Hive / SharedPreferences stores active ride and ride history for offline-first UX.
- Cloud:
  - Firestore: durable records, collections such as `rides`, `ride_history`, `ride_events`, `gps_tracking`, `notifications`, `support_tickets`.
  - Realtime Database: `active_rides/{rideId}` and `live_tracking/{driverId}` for low-latency real-time updates.
  - Storage: media/uploads (profile photos, ride photos).

## Data model (key collections / nodes)
- Firestore: `rides`, `ride_history`, `ride_events`, `gps_tracking`, `drivers`, `riders`, `notifications`, `earnings`, `support_tickets`.
- Realtime Database: `active_rides/{rideId}`, `live_tracking/{driverId}`.

## Key source files added/modified
- Added:
  - `lib/core/services/ride_tracking_service.dart`
  - `lib/core/services/ride_firebase_integration.dart`
  - `lib/core/services/ride_firebase_integration_examples.dart`
  - Documentation: `FIREBASE_RIDE_TRACKING_GUIDE.md`, `FIREBASE_TRACKING_TESTING_CHECKLIST.md`, `QUICK_INTEGRATION_REFERENCE.md`
- Modified:
  - `lib/features/rides/presentation/bloc/route_bloc.dart`
  - `lib/shared/widgets/persistent_navigation_wrapper.dart`
  - `pubspec.yaml` (package name -> crazy_cabz)

## Implementation highlights
- Local-first resilience with non-blocking cloud writes.
- Redundant event storage for analytics plus quick reads.
- Realtime DB for live updates; Firestore for durable storage and analytics.
- Platform guards to avoid MissingPluginException on unsupported platforms.

## Testing & QA
- Manual tests for local load/save of active rides and ride history.
- Recommendations for unit and integration tests: unit tests for `ride_tracking_service`, BLoC tests for `RouteBloc`, integration test for full ride lifecycle.

## CI / Deployment recommendations
- Add GitHub Actions to run `flutter analyze` and `flutter test` on push/PR.
- Use CI secrets for Firebase/service keys.

## Security notes
- Do not commit `google-services.json` or `GoogleService-Info.plist` (already in `.gitignore`).
- Use Firebase security rules that enforce auth checks for read/write.

## How to demo / reproduce locally
1. Clone repo:

```powershell
git clone https://github.com/achireddybeduduri-7727/crazy-cabz-driver.git
```

2. Install Flutter & platform tools.
3. Get packages:

```powershell
flutter pub get
```

4. Configure Firebase locally (optional) and run the app:

```powershell
flutter run -d windows
```

## Resume bullets (ready-to-copy)
- Built “Crazy Cabz” — a Flutter driver app with live GPS tracking and Firebase-based ride lifecycle logging (Firestore + Realtime DB + Storage).
- Implemented local-first architecture with background sync and robust error handling to ensure smooth driver UX under intermittent connectivity.

## Interview talking points
- Local-first approach benefits for drivers.
- Trade-offs between Firestore and Realtime Database.
- Handling platform incompatibilities and graceful degradation.

## Files & links
- Repo: https://github.com/achireddybeduduri-7727/crazy-cabz-driver
- Key files:
  - `lib/core/services/ride_tracking_service.dart`
  - `lib/core/services/ride_firebase_integration.dart`
  - `lib/features/rides/presentation/bloc/route_bloc.dart`

---

If you want this exported to PDF automatically, I can try to convert it locally (requires `pandoc`) or add a GitHub Actions workflow to generate the PDF on push and upload it as an artifact — which would let you download the PDF from the repository Actions page. Tell me which you prefer and I'll proceed.
