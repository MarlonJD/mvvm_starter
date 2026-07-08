import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";

void main() {
  test("English and Turkish translation keys match", () async {
    final english = await _readKeys("assets/translations/en-US.json");
    final turkish = await _readKeys("assets/translations/tr-TR.json");

    expect(turkish, english);
  });
}

Future<Set<String>> _readKeys(String path) async {
  final content = await File(path).readAsString();
  final data = jsonDecode(content) as Map<String, dynamic>;
  return data.keys.toSet();
}
