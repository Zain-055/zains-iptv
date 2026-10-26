# ZAIN'S IPTV

ZAIN'S IPTV is a Flutter-based IPTV player for loading and browsing M3U/M3U8 playlists from local files or remote URLs. It supports category filtering, live channel browsing, favorites, offline cached playback, and a simplified TV-style interface.

## Features

- Import local `.m3u`, `.m3u8`, or `.txt` playlists
- Load playlists from remote URLs
- Load and combine multiple remote playlists at once (one URL per line)
- Search and filter channels by name or category
- Tune directly to numbered channels with the number keys on a TV remote
- Offline fallback to the last cached playlist
- TV-friendly layout with large touch targets and focusable controls
- Cross-platform live playback for HLS/M3U8 and other common stream formats, including Windows
- Broader device codec support through the bundled media playback engine
- Channel numbers follow playlist order and work regardless of the active category or search filter
- Fixed orange-on-black theme
- Keeps unavailable streams in the channel list so playback can retry automatically
- Recovers from extended buffering with a bounded, exponential reconnect schedule
- Persistent settings and playlist metadata

Stream availability is checked during playback rather than playlist import. A failed stream displays a no-signal screen, retries automatically, and keeps previous/next channel controls available. Original local playlist files and remote playlist sources are never modified.

## Getting started

1. Install Flutter 3.13.4 or newer.
2. Run the following from the project root:

   ```bash
   flutter pub get
   flutter run
   ```

3. On first launch, load a valid IPTV playlist to begin using the app.

## Downloads

GitHub Releases provide the signed Android APK and the Windows x64 executable. Download the Windows ZIP for the complete runnable app bundle; the standalone executable depends on the runtime files in that ZIP.

The Android APK is signed with the project's existing release key. Install it over an existing copy to upgrade while preserving app data.

## Testing

```bash
flutter test
```

## Android release build

The Android release build uses a private signing key configured locally:

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Set the absolute path to your existing keystore, its password, the key alias, and the key password.
3. For Google Play, build an Android App Bundle with `flutter build appbundle --release`. To create one sideloadable APK for the Android CPU architectures supported by Flutter, run `flutter build apk --release`. This universal APK is larger than per-architecture APKs because it includes native libraries for all configured ABIs. Android OS version and device compatibility still depend on the app's minimum SDK and the device's supported architecture.

Release builds enable Android code shrinking and resource shrinking. App Bundles and split APKs package only the native libraries needed for each device, unlike a universal APK.

Do not commit `android/key.properties` or your keystore. Keep backups of the signing key: Android app updates must be signed with the same key (or the configured Play App Signing key).

Sideloaded APKs may still trigger Play Protect or device-specific verification notices. Signing verifies the APK publisher and integrity, but cannot guarantee that every store, device, or verification service will show no warnings. For Google Play distribution, upload an Android App Bundle and use Play App Signing.

The Android APK also supports Android TV through the Leanback launcher entry in the Android manifest. The release workflow builds Windows, Linux, macOS, and unsigned iOS artifacts on their respective GitHub-hosted runners. Push the project to GitHub or run the workflow manually, then download the artifacts from the completed Actions run. The iOS artifact is unsigned and must be signed with an Apple development/distribution identity before installing on a device or distributing it.

To publish Windows downloads, push a version tag such as `v1.0.2`. GitHub Actions creates a release with both the Windows executable and a ZIP containing the complete Windows app. Use the ZIP to run the app, since the executable depends on the accompanying Flutter runtime files.
