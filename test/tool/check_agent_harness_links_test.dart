import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:path/path.dart" as path;

void main() {
  test("link checker accepts a root and reports exact broken links", () async {
    final repositoryRoot = Directory.current.absolute.path;
    final checker = path.join(
      repositoryRoot,
      "tool",
      "check_agent_harness_links.dart",
    );
    final temporaryRoot = await Directory.systemTemp.createTemp(
      "agent-harness-links-",
    );
    addTearDown(() => temporaryRoot.delete(recursive: true));
    final harnessDirectory = Directory(
      path.join(temporaryRoot.path, "docs", "agent-harness"),
    );
    await harnessDirectory.create(recursive: true);
    await File(
      path.join(harnessDirectory.path, "README.md"),
    ).writeAsString("# Harness\n");
    final agentsFile = File(path.join(temporaryRoot.path, "AGENTS.md"));
    await agentsFile.writeAsString("[Harness](docs/agent-harness/README.md)\n");

    final passing = await _runChecker(checker, temporaryRoot.path);

    expect(passing.exitCode, 0, reason: "${passing.stderr}");

    await agentsFile.writeAsString(
      "[Missing](docs/agent-harness/missing.md)\n",
    );
    final failing = await _runChecker(checker, temporaryRoot.path);

    expect(failing.exitCode, 1);
    expect(
      failing.stderr,
      contains("AGENTS.md:1 -> docs/agent-harness/missing.md does not exist"),
    );
  });
}

Future<ProcessResult> _runChecker(String checker, String root) {
  final flutterRoot = Platform.environment["FLUTTER_ROOT"];
  final dartExecutable = flutterRoot == null
      ? "dart"
      : path.join(flutterRoot, "bin", "cache", "dart-sdk", "bin", "dart");
  return Process.run(dartExecutable, [
    checker,
    "--root",
    root,
  ], workingDirectory: Directory.current.path);
}
