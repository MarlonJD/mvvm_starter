/// Source of a persisted network-example result.
enum DataOrigin {
  /// The current request returned this data from the remote service.
  remote,

  /// The remote request failed and the local snapshot is within its TTL.
  localFresh,

  /// The remote request failed and the local snapshot is older than its TTL.
  localStale,
}

/// Complete local snapshot read from one persistence scope.
final class LocalSnapshot<T> {
  /// Creates a local snapshot.
  const LocalSnapshot({required this.value, required this.fetchedAt});

  /// Stored data for the selected scope.
  final T value;

  /// Latest remote-fetch time in the snapshot, or null when it is empty.
  final DateTime? fetchedAt;
}

/// Data plus its source and remote-fetch timestamp.
final class PersistedResult<T> {
  /// Creates a persisted result.
  const PersistedResult({
    required this.value,
    required this.origin,
    required this.fetchedAt,
  });

  /// Returned data.
  final T value;

  /// Source used to fulfill the request.
  final DataOrigin origin;

  /// Time at which the snapshot was last fetched from the remote service.
  final DateTime fetchedAt;
}
