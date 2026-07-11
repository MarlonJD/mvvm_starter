import "dart:io";

import "package:crypto/crypto.dart";
import "package:path/path.dart" as path;

const sqliteVersion = "3.3.4";
const sqliteUri =
    "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.4/sqlite3.wasm";
const sqliteSha256 =
    "cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3";

Future<void> main() async {
  final root = Directory.current.absolute;
  final webDirectory = Directory(path.join(root.path, "web"));
  final sqliteTarget = File(path.join(webDirectory.path, "sqlite3.wasm"));
  final sqliteTemporary = File(
    path.join(webDirectory.path, ".sqlite3-$sqliteVersion.wasm.tmp"),
  );
  final workerSource = File(path.join(webDirectory.path, "drift_worker.dart"));
  final workerTarget = File(path.join(webDirectory.path, "drift_worker.js"));

  try {
    if (!workerSource.existsSync()) {
      throw StateError(
        "Missing ${path.relative(workerSource.path, from: root.path)}",
      );
    }

    await _downloadSqlite(sqliteTemporary);
    await _verifySqlite(sqliteTemporary);
    await _replaceFile(sqliteTemporary, sqliteTarget);
    await _compileWorker(workerSource, workerTarget, root);

    stdout.writeln(
      "Updated web/sqlite3.wasm ($sqliteVersion) and web/drift_worker.js.",
    );
  } on Object catch (error) {
    stderr.writeln("Failed to update Drift web assets: $error");
    exitCode = 1;
  } finally {
    if (sqliteTemporary.existsSync()) {
      sqliteTemporary.deleteSync();
    }
  }
}

Future<void> _downloadSqlite(File destination) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(sqliteUri));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        "SQLite download returned HTTP ${response.statusCode}",
        uri: Uri.parse(sqliteUri),
      );
    }
    final sink = destination.openWrite();
    try {
      await response.pipe(sink);
    } finally {
      await sink.close();
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _verifySqlite(File file) async {
  final digest = sha256.convert(await file.readAsBytes()).toString();
  if (digest != sqliteSha256) {
    throw StateError(
      "SQLite SHA-256 mismatch: expected $sqliteSha256, received $digest",
    );
  }
}

Future<void> _replaceFile(File source, File destination) async {
  if (destination.existsSync()) {
    destination.deleteSync();
  }
  await source.rename(destination.path);
}

Future<void> _compileWorker(
  File source,
  File destination,
  Directory root,
) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    "compile",
    "js",
    "-O4",
    "-o",
    destination.path,
    source.path,
  ], workingDirectory: root.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw ProcessException(
      Platform.resolvedExecutable,
      ["compile", "js", "-O4", "-o", destination.path, source.path],
      "Dart worker compilation failed",
      result.exitCode,
    );
  }
  if (!destination.existsSync() || destination.lengthSync() == 0) {
    throw StateError("Dart worker compilation produced no output");
  }

  for (final suffix in [".deps", ".map"]) {
    final auxiliary = File("${destination.path}$suffix");
    if (auxiliary.existsSync()) {
      auxiliary.deleteSync();
    }
  }
}
