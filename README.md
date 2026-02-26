# Crazy Cabz (Driver App)

Crazy Cabz is a Flutter-based driver application for transport agents. It records rides, performs live GPS tracking, and calculates fares based on time and distance. This repository contains the driver-facing mobile/desktop app and the services needed to persist ride history to Firebase (Firestore, Realtime Database, Storage).

Key features
- Ride lifecycle tracking (create, navigate, arrive, pickup, complete, cancel)
- Persistent ride history and per-ride events
- Live GPS tracking and history saving
- Firebase integration (Firestore + Realtime Database + Storage)
- Local-first behavior with resilient Firebase writes (try/catch guards)

Quick start
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Install required tools for your target platform (Android Studio, Xcode, Visual Studio for Windows builds)
3. Run in debug:
```powershell
flutter pub get
flutter run
```

Firebase
- Before using remote features, configure Firebase for your project and publish rules (see `FIREBASE_SECURITY_RULES.md`).

Repository name suggestion: `crazy-cabz-driver`

If you want, I can initialize a local git repo and help push this to GitHub under that name.
