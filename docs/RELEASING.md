# Releasing

## 1. Create a signing key (once)

Keep this file and its passwords safe and **never commit them**. If you lose the key you can't publish updates under the same app ID.

```bash
keytool -genkey -v -keystore ~/tonrail-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tonrail
```

## 2. Point the build at it

Create `android/key.properties` (already in `.gitignore`):

```properties
storeFile=/absolute/path/to/tonrail-release.jks
storePassword=your-store-password
keyAlias=tonrail
keyPassword=your-key-password
```

Without this file, release builds are signed with the debug key and are only fit for local testing.

## 3. Bump the version

In `pubspec.yaml`, raise `version: X.Y.Z+N`. `N` (the build number) must go up on every release. Add the changes to [CHANGELOG.md](../CHANGELOG.md).

## 4. Check and build

```bash
flutter analyze
flutter test
flutter build apk --release --split-per-abi   # smaller per-device APKs
flutter build apk --release                   # one universal APK
flutter build appbundle --release             # for Google Play
```

Outputs are in `build/app/outputs/`. Install the APK on a real phone and check that it connects to the headphones before publishing; the release build is shrunk with R8.

## 5. Publish

1. Tag the commit: `git tag v1.0.0 && git push origin v1.0.0`.
2. Create a GitHub release for the tag, paste the changelog section and attach the APKs.
