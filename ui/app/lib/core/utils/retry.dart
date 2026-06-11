/// Runs [action] once; on failure waits [delay] then retries at most [maxAttempts] times total.
Future<T> retryAsync<T>(
  Future<T> Function() action, {
  int maxAttempts = 2,
  Duration delay = const Duration(seconds: 1),
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (attempt >= maxAttempts) break;
      await Future<void>.delayed(delay);
    }
  }
  throw lastError!;
}
