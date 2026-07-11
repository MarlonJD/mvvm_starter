import "dart:io";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";

const _sqliteSha256 =
    "cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3";

void main() {
  test("Android release networking permission is configured", () {
    final root = Directory.current;
    final androidManifest = File(
      "${root.path}/android/app/src/main/AndroidManifest.xml",
    ).readAsStringSync();
    expect(
      androidManifest,
      contains("android.permission.INTERNET"),
      reason: "Android release networking requires INTERNET permission.",
    );
  });

  test(
    "macOS debug and release network client entitlements are configured",
    () {
      final root = Directory.current;
      for (final relativePath in [
        "macos/Runner/DebugProfile.entitlements",
        "macos/Runner/Release.entitlements",
      ]) {
        final entitlements = File(
          "${root.path}/$relativePath",
        ).readAsStringSync();
        expect(
          entitlements,
          contains("com.apple.security.network.client"),
          reason: "$relativePath must allow outbound network connections.",
        );
        expect(
          entitlements,
          contains("<true/>"),
          reason: "$relativePath must enable the network client entitlement.",
        );
      }
    },
  );

  test("Drift web assets exist and SQLite has the pinned hash", () {
    final root = Directory.current;
    final sqliteWasm = File("${root.path}/web/sqlite3.wasm");
    final driftWorker = File("${root.path}/web/drift_worker.js");
    expect(sqliteWasm.existsSync(), isTrue);
    expect(driftWorker.existsSync(), isTrue);
    expect(sqliteWasm.lengthSync(), greaterThan(0));
    expect(driftWorker.lengthSync(), greaterThan(0));
    expect(
      sha256.convert(sqliteWasm.readAsBytesSync()).toString(),
      _sqliteSha256,
    );
  });

  test(
    "native OIDC callbacks and secure-storage entitlements are configured",
    () {
      final root = Directory.current.path;
      final androidGradle = File(
        "$root/android/app/build.gradle",
      ).readAsStringSync();
      final androidManifest = File(
        "$root/android/app/src/main/AndroidManifest.xml",
      ).readAsStringSync();
      expect(androidGradle, contains("appAuthRedirectScheme"));
      expect(androidGradle, contains("mvvmstarter"));
      expect(androidManifest, contains('android:allowBackup="false"'));
      expect(androidManifest, isNot(contains('android:taskAffinity=""')));

      for (final relativePath in [
        "ios/Runner/Info.plist",
        "macos/Runner/Info.plist",
      ]) {
        final plist = File("$root/$relativePath").readAsStringSync();
        expect(plist, contains("CFBundleURLTypes"));
        expect(plist, contains("mvvmstarter"));
      }

      for (final relativePath in [
        "ios/Runner/DebugProfile.entitlements",
        "ios/Runner/Release.entitlements",
        "macos/Runner/DebugProfile.entitlements",
        "macos/Runner/Release.entitlements",
      ]) {
        final file = File("$root/$relativePath");
        expect(file.existsSync(), isTrue, reason: "$relativePath must exist");
        final entitlements = file.readAsStringSync();
        expect(entitlements, contains("keychain-access-groups"));
      }

      final xcodeProject = File(
        "$root/ios/Runner.xcodeproj/project.pbxproj",
      ).readAsStringSync();
      expect(
        "CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;".allMatches(
          xcodeProject,
        ),
        hasLength(2),
      );
      expect(
        xcodeProject,
        contains("CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;"),
      );
    },
  );
}
