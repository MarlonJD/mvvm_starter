import "package:mvvm_starter/core/result/result.dart";

/// Protocol-neutral source for an optional HTTP Authorization header value.
abstract interface class AuthorizationHeaderProvider {
  /// Returns a complete Authorization value, or null for anonymous requests.
  Future<Result<String?>> authorizationHeader({bool forceRefresh = false});
}
