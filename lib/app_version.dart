/// App version, compiled in by tools/build_web.sh: the name from pubspec.yaml, the build number
/// from CI (GitHub Actions run number) and the commit (BUILD_ID, see update_checker.dart).
/// Empty in development builds (`flutter run`).
const appVersion = String.fromEnvironment('APP_VERSION');
const buildNumber = String.fromEnvironment('BUILD_NUMBER');
