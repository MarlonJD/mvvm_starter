import "dart:io";

import "package:path/path.dart" as path;

void main(List<String> arguments) {
  final root = _scanRoot(arguments);
  if (root == null) {
    exitCode = 64;
    return;
  }

  final libDirectory = Directory(path.join(root, "lib"));
  if (!libDirectory.existsSync()) {
    stderr.writeln(
      "FAIL: ${path.relative(libDirectory.path, from: root)} is missing.",
    );
    exitCode = 1;
    return;
  }

  final violations = <_Violation>[];
  final files =
      libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => path.extension(file.path) == ".dart")
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  for (final file in files) {
    _checkFile(root, file, violations);
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      "FAIL: found ${violations.length} MVVM boundary violation(s).",
    );
    for (final violation in violations) {
      stderr.writeln("${violation.file}:${violation.line}: ${violation.rule}");
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    "PASS: checked ${files.length} Dart runtime file(s) for MVVM boundaries.",
  );
}

void _checkFile(String root, File file, List<_Violation> violations) {
  final relative = path.relative(file.path, from: root);
  final normalized = path.normalize(relative).replaceAll(path.separator, "/");
  final basename = path.basename(file.path);
  final isView = basename.endsWith("_view.dart");
  final isViewModel = basename.endsWith("_view_model.dart");
  final isFeatureFile = normalized.startsWith("lib/features/");
  final isRestorationFile = normalized.startsWith("lib/core/restoration/");
  final lines = file.readAsLinesSync();

  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    final trimmed = line.trimLeft();
    final lineNumber = index + 1;
    final isImport = trimmed.startsWith("import ");

    if (isView && isImport && _forbiddenViewImport.hasMatch(trimmed)) {
      violations.add(
        _Violation(
          file: normalized,
          line: lineNumber,
          rule:
              "Views must receive dependencies through ViewModels, not import service locators, Drift, databases, or feature data layers.",
        ),
      );
    }
    if (isViewModel &&
        isImport &&
        _forbiddenViewModelImport.hasMatch(trimmed)) {
      violations.add(
        _Violation(
          file: normalized,
          line: lineNumber,
          rule: "ViewModels must not import Drift or app_database.dart.",
        ),
      );
    }
    if (isFeatureFile && _locatorCall.hasMatch(line)) {
      violations.add(
        _Violation(
          file: normalized,
          line: lineNumber,
          rule: "Feature files must not call the app service locator.",
        ),
      );
    }
    if (_imperativeApplicationRoute.hasMatch(line)) {
      violations.add(
        _Violation(
          file: normalized,
          line: lineNumber,
          rule:
              "Application routes must use go_router, not MaterialPageRoute or Navigator.push.",
        ),
      );
    }
    if (isRestorationFile &&
        isImport &&
        _forbiddenRestorationImport.hasMatch(trimmed)) {
      violations.add(
        _Violation(
          file: normalized,
          line: lineNumber,
          rule:
              "Restoration files must not import auth tokens, repositories, Drift, or database tables.",
        ),
      );
    }
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
    "Usage: dart run tool/check_mvvm_boundaries.dart [--root <path>]",
  );
  return null;
}

final _forbiddenViewImport = RegExp(
  r"package:get_it/|\bget_it\.dart|locator\.dart|package:drift/|app_database\.dart|features/[^/]+/data/",
);
final _forbiddenViewModelImport = RegExp(r"package:drift/|app_database\.dart");
final _locatorCall = RegExp(r"\blocator\s*(?:<[^>]+>)?\s*\(");
final _imperativeApplicationRoute = RegExp(
  r"\bMaterialPageRoute\s*(?:<[^>]+>)?\s*\(|\bNavigator\s*\.\s*push(?:Named|Replacement|AndRemoveUntil)?\s*\(",
);
final _forbiddenRestorationImport = RegExp(
  r"oidc_token|auth_repository\.dart|_repository\.dart|package:drift/|app_database\.dart",
);

final class _Violation {
  const _Violation({
    required this.file,
    required this.line,
    required this.rule,
  });

  final String file;
  final int line;
  final String rule;
}
