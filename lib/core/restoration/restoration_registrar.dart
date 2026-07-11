import "package:flutter/widgets.dart";

/// Registers restorable properties without exposing a concrete State type.
abstract interface class RestorationRegistrar {
  /// Registers [property] with [restorationId].
  void register<T>(RestorableProperty<T> property, String restorationId);
}

/// [RestorationRegistrar] backed by a [RestorationMixin] State.
final class MixinRestorationRegistrar implements RestorationRegistrar {
  /// Creates a registrar for [state].
  const MixinRestorationRegistrar(this.state);

  /// State that owns restoration registration.
  final RestorationMixin state;

  @override
  void register<T>(RestorableProperty<T> property, String restorationId) {
    // Protected by design: this helper is only used from RestorationMixin State.
    // ignore: invalid_use_of_protected_member
    state.registerForRestoration(property, restorationId);
  }
}
