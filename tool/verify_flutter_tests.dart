import "dart:async";
import "dart:convert";
import "dart:io";

Future<void> main() async {
  final process = await Process.start("flutter", const ["test", "--machine"]);
  var discoveredTests = 0;

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
        stdout.writeln(line);
        final event = _decodeEvent(line);
        if (_isRuntimeTestStart(event)) {
          discoveredTests += 1;
        }
      });
  final stderrDone = stderr.addStream(process.stderr);
  final processExitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);

  stdout.writeln("Discovered runtime tests: $discoveredTests");
  if (processExitCode != 0) {
    exitCode = processExitCode;
    return;
  }
  if (discoveredTests == 0) {
    stderr.writeln(
      "FAIL: flutter test reported zero non-synthetic testStart events.",
    );
    exitCode = 1;
  }
}

Map<String, Object?>? _decodeEvent(String line) {
  try {
    final decoded = jsonDecode(line);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

bool _isRuntimeTestStart(Map<String, Object?>? event) {
  if (event?["type"] != "testStart") {
    return false;
  }
  final test = event?["test"];
  if (test is! Map<String, Object?>) {
    return false;
  }
  final name = test["name"];
  if (name is! String || name.isEmpty) {
    return false;
  }
  return !name.startsWith("loading ") &&
      name != "(setUpAll)" &&
      name != "(tearDownAll)";
}
