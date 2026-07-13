import "dart:io";

import "package:path/path.dart" as path;

void main(List<String> arguments) {
  final root = _scanRoot(arguments);
  if (root == null) {
    exitCode = 64;
    return;
  }
  final files = _markdownFiles(root);
  final brokenLinks = <_BrokenLink>[];
  var checkedLinks = 0;

  for (final file in files) {
    final lines = file.readAsLinesSync();
    var inCodeFence = false;

    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith("```") || trimmed.startsWith("~~~")) {
        inCodeFence = !inCodeFence;
        continue;
      }
      if (inCodeFence) {
        continue;
      }

      for (final match in _markdownLinkPattern.allMatches(line)) {
        final rawTarget = match.group(1);
        if (rawTarget == null) {
          continue;
        }

        final target = _normalizeMarkdownTarget(rawTarget);
        if (target == null || _isExternalOrAnchor(target)) {
          continue;
        }

        checkedLinks += 1;
        final targetPath = _resolveTarget(root, file, target);
        if (!File(targetPath).existsSync() &&
            !Directory(targetPath).existsSync()) {
          brokenLinks.add(
            _BrokenLink(
              source: path.relative(file.path, from: root),
              line: index + 1,
              target: target,
            ),
          );
        }
      }
    }
  }

  if (brokenLinks.isNotEmpty) {
    stderr.writeln("FAIL: found ${brokenLinks.length} broken local link(s).");
    for (final link in brokenLinks) {
      stderr.writeln(
        "- ${link.source}:${link.line} -> ${link.target} does not exist",
      );
    }
    stderr.writeln(
      "Fix the target path or update the markdown link before continuing.",
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    "PASS: checked ${files.length} markdown file(s) and $checkedLinks local link(s).",
  );
}

String? _scanRoot(List<String> arguments) {
  if (arguments.isEmpty) {
    return Directory.current.absolute.path;
  }
  if (arguments.length == 2 && arguments.first == "--root") {
    return Directory(arguments.last).absolute.path;
  }
  stderr.writeln(
    "Usage: dart run tool/check_agent_harness_links.dart [--root <path>]",
  );
  return null;
}

final _markdownLinkPattern = RegExp(r"!?\[[^\]\n]*\]\(([^)\n]+)\)");

List<File> _markdownFiles(String root) {
  final rootFiles = ["AGENTS.md", "CLAUDE.md", "README.md"]
      .map((name) => File(path.join(root, name)))
      .where((file) => file.existsSync());

  final harnessFiles = Directory(path.join(root, "docs", "agent-harness"))
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => path.extension(file.path) == ".md");

  final files = [...rootFiles, ...harnessFiles]
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

String? _normalizeMarkdownTarget(String rawTarget) {
  var target = rawTarget.trim();
  if (target.isEmpty) {
    return null;
  }

  if (target.startsWith("<")) {
    final closingIndex = target.indexOf(">");
    if (closingIndex == -1) {
      return target.substring(1).trim();
    }
    return target.substring(1, closingIndex).trim();
  }

  for (final titleSeparator in [' "', " '"]) {
    final titleIndex = target.indexOf(titleSeparator);
    if (titleIndex > 0) {
      target = target.substring(0, titleIndex).trim();
      break;
    }
  }

  return target;
}

bool _isExternalOrAnchor(String target) {
  if (target.startsWith("#") || target.startsWith("//")) {
    return true;
  }
  return RegExp(r"^[a-zA-Z][a-zA-Z0-9+.-]*:").hasMatch(target);
}

String _resolveTarget(String root, File source, String target) {
  final pathTarget = Uri.decodeComponent(target.split("#").first);
  final resolved = pathTarget.startsWith("/")
      ? path.join(root, pathTarget.substring(1))
      : path.join(path.dirname(source.path), pathTarget);
  return path.normalize(resolved);
}

class _BrokenLink {
  const _BrokenLink({
    required this.source,
    required this.line,
    required this.target,
  });

  final String source;
  final int line;
  final String target;
}
