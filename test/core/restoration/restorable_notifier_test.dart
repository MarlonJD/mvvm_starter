import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/restoration/restorable_notifier.dart";

void main() {
  test("restorable string notifier exposes ValueListenable only", () {
    final notifier = RestorableStringNotifier("");
    addTearDown(notifier.dispose);

    final exposed = notifier.listenable;
    expect(exposed, isA<ValueListenable<String>>());
    expect(exposed, isNot(isA<ValueNotifier<String>>()));

    notifier.value = "saved draft";

    expect(exposed.value, "saved draft");
    expect(notifier.toPrimitives(), "saved draft");
  });

  test("restorable bool notifier rejects non-bool primitives", () {
    final notifier = RestorableBoolNotifier(defaultValue: false);
    addTearDown(notifier.dispose);

    expect(
      () => notifier.fromPrimitives("not-bool"),
      throwsA(isA<ArgumentError>()),
    );
  });
}
