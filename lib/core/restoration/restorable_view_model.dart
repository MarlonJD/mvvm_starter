import "package:mvvm_starter/core/restoration/restoration_registrar.dart";

/// Contract for ViewModels that own Flutter restorable properties.
abstract interface class RestorableViewModel {
  /// Registers restorable properties with [registrar].
  void registerRestorableProperties(RestorationRegistrar registrar);

  /// Releases ViewModel resources.
  void dispose();
}
