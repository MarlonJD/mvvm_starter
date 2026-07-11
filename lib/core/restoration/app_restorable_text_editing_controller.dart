import "package:flutter/widgets.dart";

/// Restorable text controller that is also usable before registration.
final class AppRestorableTextEditingController
    extends RestorableTextEditingController {
  /// Creates a restorable text controller.
  AppRestorableTextEditingController({String? text})
    : super.fromValue(
        text == null ? TextEditingValue.empty : TextEditingValue(text: text),
      );

  TextEditingController? _unregisteredController;

  @override
  TextEditingController get value {
    if (isRegistered) {
      return super.value;
    }
    return _unregisteredController ??= createDefaultValue();
  }

  @override
  void initWithValue(TextEditingController value) {
    _unregisteredController?.dispose();
    _unregisteredController = null;
    super.initWithValue(value);
  }

  @override
  void dispose() {
    _unregisteredController?.dispose();
    super.dispose();
  }
}
