import "dart:io";

import "package:crypto/crypto.dart";
import "package:path/path.dart" as path;

const _sqliteSha256 =
    "cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3";

void main(List<String> arguments) {
  final root = _scanRoot(arguments);
  if (root == null) {
    exitCode = 64;
    return;
  }

  final failures = <String>[];
  final androidManifest = _read(
    root,
    "android/app/src/main/AndroidManifest.xml",
    failures,
  );
  _requireContains(
    androidManifest,
    "android.permission.INTERNET",
    "android/app/src/main/AndroidManifest.xml must declare android.permission.INTERNET",
    failures,
  );
  _requireContains(
    androidManifest,
    'android:allowBackup="false"',
    "android/app/src/main/AndroidManifest.xml must disable application backup",
    failures,
  );
  if (androidManifest.contains('android:taskAffinity=""')) {
    failures.add(
      "android/app/src/main/AndroidManifest.xml must not clear taskAffinity",
    );
  }

  for (final relative in [
    "macos/Runner/DebugProfile.entitlements",
    "macos/Runner/Release.entitlements",
  ]) {
    final entitlements = _read(root, relative, failures);
    _requirePlistBooleanTrue(
      entitlements,
      "com.apple.security.network.client",
      "$relative must enable outbound networking",
      failures,
    );
  }

  final sqlite = File(path.join(root, "web", "sqlite3.wasm"));
  final worker = File(path.join(root, "web", "drift_worker.js"));
  _requireNonEmpty(sqlite, root, failures);
  _requireNonEmpty(worker, root, failures);
  if (sqlite.existsSync() && sqlite.lengthSync() > 0) {
    final digest = sha256.convert(sqlite.readAsBytesSync()).toString();
    if (digest != _sqliteSha256) {
      failures.add(
        "web/sqlite3.wasm SHA-256 mismatch: expected $_sqliteSha256, received $digest",
      );
    }
  }

  final androidGradle = _read(root, "android/app/build.gradle", failures);
  _requireContains(
    androidGradle,
    "appAuthRedirectScheme",
    "android/app/build.gradle must configure the AppAuth redirect placeholder",
    failures,
  );
  _requireContains(
    androidGradle,
    "mvvmstarter",
    "android/app/build.gradle must use the mvvmstarter callback scheme",
    failures,
  );

  for (final relative in ["ios/Runner/Info.plist", "macos/Runner/Info.plist"]) {
    final plist = _read(root, relative, failures);
    _requireContains(
      plist,
      "CFBundleURLTypes",
      "$relative must declare CFBundleURLTypes",
      failures,
    );
    _requireContains(
      plist,
      "mvvmstarter",
      "$relative must register the mvvmstarter callback scheme",
      failures,
    );
  }

  for (final relative in [
    "ios/Runner/DebugProfile.entitlements",
    "ios/Runner/Release.entitlements",
    "macos/Runner/DebugProfile.entitlements",
    "macos/Runner/Release.entitlements",
  ]) {
    final entitlements = _read(root, relative, failures);
    _requireContains(
      entitlements,
      "keychain-access-groups",
      "$relative must declare keychain-access-groups",
      failures,
    );
  }

  final xcodeProject = _read(
    root,
    "ios/Runner.xcodeproj/project.pbxproj",
    failures,
  );
  final debugEntitlementCount =
      "CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;"
          .allMatches(xcodeProject)
          .length;
  if (debugEntitlementCount != 2) {
    failures.add(
      "ios/Runner.xcodeproj/project.pbxproj must assign DebugProfile.entitlements to Debug and Profile",
    );
  }
  _requireContains(
    xcodeProject,
    "CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;",
    "ios/Runner.xcodeproj/project.pbxproj must assign Release.entitlements to Release",
    failures,
  );

  if (failures.isNotEmpty) {
    stderr.writeln(
      "FAIL: found ${failures.length} platform configuration issue(s).",
    );
    for (final failure in failures) {
      stderr.writeln("- $failure");
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    "PASS: platform networking, Drift web assets, OIDC callbacks, and Keychain configuration are valid.",
  );
}

String _read(String root, String relative, List<String> failures) {
  final file = File(path.join(root, relative));
  if (!file.existsSync()) {
    failures.add("$relative is missing");
    return "";
  }
  return file.readAsStringSync();
}

void _requireContains(
  String source,
  String expected,
  String diagnostic,
  List<String> failures,
) {
  if (!source.contains(expected)) {
    failures.add(diagnostic);
  }
}

void _requirePlistBooleanTrue(
  String source,
  String key,
  String diagnostic,
  List<String> failures,
) {
  final enabled = RegExp(
    "<key>${RegExp.escape(key)}</key>\\s*<true\\s*/>",
  ).hasMatch(source);
  if (!enabled) {
    failures.add(diagnostic);
  }
}

void _requireNonEmpty(File file, String root, List<String> failures) {
  final relative = path.relative(file.path, from: root);
  if (!file.existsSync()) {
    failures.add("$relative is missing");
  } else if (file.lengthSync() == 0) {
    failures.add("$relative is empty");
  }
}

String? _scanRoot(List<String> arguments) {
  if (arguments.isEmpty) {
    return Directory.current.absolute.path;
  }
  if (arguments.length == 2 && arguments.first == "--root") {
    return Directory(arguments.last).absolute.path;
  }
  stderr.writeln(
    "Usage: dart run tool/check_platform_network_config.dart [--root <path>]",
  );
  return null;
}
