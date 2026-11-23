# Pixel Orbit Flutter v2.2.0

Retro pixel-art space shooter. This update replaces the cramped grid main menu with a scrollable galaxy-style hub, adds responsive tap targets, pilot profile ID, season countdown, pause overlay, original background music and game SFX, and improves touch ship movement.

## Features in this archive
- Galaxy-style home hub: Campaign, Classic, Endless, AI Arena practice, Season Pass preview, Clan entry.
- Profile and stable Pilot Code (`PO-XXXXXXXX`) backed by Supabase Auth.
- Friend lookup/request/accept/decline/removal using `pilot_profiles` and `friend_requests`.
- One-to-one pilot chat using `pilot_messages` (polling refresh).
- Clan create/join by code and clan chat using existing `clans`, `clan_members`, and `clan_chat` tables.
- Online leaderboard reads/writes to `po_scores`.
- Cloud saves to `pixelorbit_game_saves` with a local-vs-cloud timestamp check.
- Server event feed reads active entries from `pixel_game_events` alongside local notification journal.
- Music toggle/volume, SFX toggle, laser and enemy-explosion sounds, pause/resume/exit controls.

## Supabase configuration
The app uses the PixelOrbitServer project URL and its **publishable** key in `lib/online.dart`. Never replace it with a `service_role` or secret key in the mobile app.

In Supabase Dashboard → Authentication → Sign-in / Providers, enable **Anonymous Sign-ins** for guest accounts. The mobile client calls `signInAnonymously()` and then uses the authenticated UID for profile, friend, chat, and cloud-save operations. The existing RLS policies are relied on for ownership and friend access. If anonymous sign-in is unavailable, the app retains local progress and can still use public leaderboard endpoints where permitted.

No SQL migrations are applied by this archive. Existing table names, policies, and raid RPCs are used. The active public key was checked against the PixelOrbitServer project.

## Known incomplete / honest status
- Arena is still a local AI practice match; network PvP/matchmaking is not implemented.
- Season Pass rewards are preview cards; claiming and server-backed reward progression are not implemented.
- Co-op raid uses the existing `join_coop_raid` and `attack_coop_boss` RPCs for shared boss HP, phase, cooldown-limited attacks, and contribution rankings. The client refreshes raid state on a 3-second polling interval (not Supabase Realtime).
- Notifications show local journal items and currently active server events. Android push/FCM device registration is not yet wired; `push_subscriptions` is not used by the app yet.
- Source delimiters and package/assets wiring were checked here, but Flutter SDK is unavailable in this environment. `flutter analyze`, `flutter test`, and release APK build must still run in a Flutter environment/CI.

## Build APK
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
Release output: `build/app/outputs/flutter-apk/app-release.apk`.
The GitHub Actions workflow runs the release build and uploads an APK artifact when you push the project to GitHub.
