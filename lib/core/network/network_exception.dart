/// Typed transport and protocol failure categories.
enum NetworkExceptionKind {
  /// The configured request timeout elapsed.
  timeout,

  /// The request could not reach or complete with the remote service.
  transport,

  /// The remote service rejected the request as invalid.
  badRequest,

  /// Authentication is missing, expired, or invalid.
  unauthorized,

  /// The authenticated identity lacks permission.
  forbidden,

  /// The remote service rate-limited the request.
  rateLimited,

  /// The remote service failed while processing the request.
  server,

  /// The response shape does not match the expected contract.
  invalidPayload,

  /// A GraphQL response contains protocol-level errors.
  graphql,
}

/// A response-safe network failure that never contains response bodies.
final class NetworkException implements Exception {
  /// Creates a typed network exception.
  const NetworkException({
    required this.kind,
    required this.context,
    this.statusCode,
    this.cause,
  });

  /// Creates a timeout failure.
  const NetworkException.timeout([String context = "request.timeout"])
    : this(kind: NetworkExceptionKind.timeout, context: context);

  /// Creates a transport failure.
  const NetworkException.transport(String context, {Object? cause})
    : this(
        kind: NetworkExceptionKind.transport,
        context: context,
        cause: cause,
      );

  /// Creates an invalid-payload failure.
  const NetworkException.invalidPayload(String context, {Object? cause})
    : this(
        kind: NetworkExceptionKind.invalidPayload,
        context: context,
        cause: cause,
      );

  /// Creates a GraphQL protocol failure.
  const NetworkException.graphql([String context = "graphql.errors"])
    : this(kind: NetworkExceptionKind.graphql, context: context);

  /// Failure category.
  final NetworkExceptionKind kind;

  /// Stable diagnostic context without remote response content.
  final String context;

  /// HTTP status code, when available.
  final int? statusCode;

  /// Original non-sensitive cause, when available.
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? "" : ", status: $statusCode";
    return "NetworkException($kind, $context$status)";
  }
}
