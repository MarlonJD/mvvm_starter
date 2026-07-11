import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

final class _RestorableValueListenable<T> extends ChangeNotifier
    implements ValueListenable<T> {
  _RestorableValueListenable(this._value);

  T _value;

  @override
  T get value => _value;

  void setValue(T value) {
    if (_value == value) {
      return;
    }
    _value = value;
    notifyListeners();
  }
}

/// Restorable property that exposes a read-only [ValueListenable].
abstract base class RestorableNotifier<T> extends RestorableProperty<T> {
  /// Creates a restorable notifier with [defaultValue].
  RestorableNotifier(this.defaultValue)
    : _listenable = _RestorableValueListenable<T>(defaultValue);

  /// Default value used when no restoration data exists.
  final T defaultValue;

  final _RestorableValueListenable<T> _listenable;

  /// Public read-only listenable.
  ValueListenable<T> get listenable => _listenable;

  /// Current value.
  T get value => _listenable.value;

  /// Updates the current value and marks restoration data dirty.
  set value(T value) {
    if (_listenable.value == value) {
      return;
    }
    _listenable.setValue(value);
    notifyListeners();
  }

  @override
  T createDefaultValue() => defaultValue;

  @override
  void initWithValue(T value) {
    _listenable.setValue(value);
  }

  @override
  void dispose() {
    _listenable.dispose();
    super.dispose();
  }
}

/// Restorable string property with safe listenable exposure.
final class RestorableStringNotifier extends RestorableNotifier<String> {
  /// Creates a restorable string notifier.
  RestorableStringNotifier(super.defaultValue);

  @override
  String fromPrimitives(Object? data) {
    if (data is String) {
      return data;
    }
    throw ArgumentError.value(data, "data", "Expected a String.");
  }

  @override
  Object? toPrimitives() => value;
}

/// Restorable integer property with safe listenable exposure.
final class RestorableIntNotifier extends RestorableNotifier<int> {
  /// Creates a restorable integer notifier.
  RestorableIntNotifier(super.defaultValue);

  @override
  int fromPrimitives(Object? data) {
    if (data is int) {
      return data;
    }
    throw ArgumentError.value(data, "data", "Expected an int.");
  }

  @override
  Object? toPrimitives() => value;
}

/// Restorable boolean property with safe listenable exposure.
final class RestorableBoolNotifier extends RestorableNotifier<bool> {
  /// Creates a restorable boolean notifier.
  RestorableBoolNotifier({required bool defaultValue}) : super(defaultValue);

  @override
  bool fromPrimitives(Object? data) {
    if (data is bool) {
      return data;
    }
    throw ArgumentError.value(data, "data", "Expected a bool.");
  }

  @override
  Object? toPrimitives() => value;
}
