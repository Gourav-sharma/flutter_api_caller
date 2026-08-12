import 'dart:async';

import '../request/network_request.dart';
import 'cancellation_exception.dart';

/// Token used to initiate or observe HTTP request cancellation.
class CancelToken {
  bool _isCancelled = false;
  String? _reason;
  CancellationException? _cancellationException;
  final Completer<CancellationException> _completer =
      Completer<CancellationException>();
  final List<void Function(CancellationException)> _listeners =
      <void Function(CancellationException)>[];

  /// Returns true if cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Returns the cancellation reason string if available.
  String? get reason => _reason;

  /// Future resolving when cancellation is triggered.
  Future<CancellationException> get whenCancelled => _completer.future;

  /// Triggers cancellation for all associated network operations.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    _cancellationException = CancellationException(
      message: 'Request was cancelled${reason != null ? ': $reason' : ''}.',
      reason: reason,
    );
    _completer.complete(_cancellationException);

    final List<void Function(CancellationException)> callbacks =
        List<void Function(CancellationException)>.from(_listeners);
    for (final listener in callbacks) {
      listener(_cancellationException!);
    }
  }

  /// Registers a callback listener executed when token is cancelled.
  void addListener(void Function(CancellationException) listener) {
    if (_isCancelled && _cancellationException != null) {
      listener(_cancellationException!);
    } else {
      _listeners.add(listener);
    }
  }

  /// Removes a previously registered cancellation listener callback.
  void removeListener(void Function(CancellationException) listener) {
    _listeners.remove(listener);
  }

  /// Throws [CancellationException] if this token has been cancelled.
  void throwIfCancelled([NetworkRequest? request]) {
    if (_isCancelled) {
      throw CancellationException(
        message: 'Request was cancelled${_reason != null ? ': $_reason' : ''}.',
        reason: _reason,
        request: request,
      );
    }
  }
}
