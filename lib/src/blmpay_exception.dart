class BlmPayException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  final Object? response;

  const BlmPayException(this.message, {this.statusCode = 0, this.errorCode, this.response});

  @override
  String toString() => 'BlmPayException($statusCode${errorCode == null ? '' : ', $errorCode'}): $message';
}
