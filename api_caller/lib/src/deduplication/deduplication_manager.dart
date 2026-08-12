import 'dart:async';
import 'dart:convert';

import '../cancellation/cancel_token.dart';
import '../cancellation/cancellation_exception.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';

class _DeduplicationTracker {
  final Future<NetworkResponse<dynamic>> future;
  final CancelToken internalCancelToken;
  final Set<CancelToken> activeConsumers = <CancelToken>{};

  _DeduplicationTracker({
    required this.future,
    required this.internalCancelToken,
  });
}

/// Concurrency-safe manager that coalesces duplicate simultaneous HTTP requests
/// so that only a single network round-trip is executed while delivering
/// identical results to all subscribing consumers.
class DeduplicationManager {
  final Map<String, _DeduplicationTracker> _inflight =
      <String, _DeduplicationTracker>{};

  /// Generates a unique deduplication signature key for [request].
  String generateKey(NetworkRequest request) {
    final Map<String, dynamic> keyMap = <String, dynamic>{
      'method': request.method.toUpperCase(),
      'uri': request.uri.toString(),
      'queryParams': request.queryParameters,
      'body': request.body,
    };

    return jsonEncode(keyMap);
  }

  /// Executes [requestFetcher] or coalesces onto an active inflight operation.
  Future<NetworkResponse<T>> deduplicate<T>({
    required NetworkRequest request,
    required Future<NetworkResponse<dynamic>> Function(
            CancelToken? internalCancelToken)
        requestFetcher,
    CancelToken? cancelToken,
    bool enabled = true,
  }) async {
    if (!enabled) {
      final NetworkResponse<dynamic> res = await requestFetcher(cancelToken);
      return _castResponse<T>(res);
    }

    final String key = generateKey(request);

    _DeduplicationTracker? tracker = _inflight[key];

    if (tracker == null) {
      final CancelToken internalCancelToken = CancelToken();
      late final Future<NetworkResponse<dynamic>> future;

      future = requestFetcher(internalCancelToken).whenComplete(() {
        _inflight.remove(key);
      });
      unawaited(future.catchError((_, __) => NetworkResponse<dynamic>(
            statusCode: 500,
            headers: const <String, String>{},
            request: request,
          )));

      tracker = _DeduplicationTracker(
        future: future,
        internalCancelToken: internalCancelToken,
      );

      _inflight[key] = tracker;
    }

    if (cancelToken != null) {
      tracker.activeConsumers.add(cancelToken);
    }

    final Completer<NetworkResponse<dynamic>> consumerCompleter =
        Completer<NetworkResponse<dynamic>>();

    void cancellationListener(CancellationException ex) {
      if (consumerCompleter.isCompleted) return;

      if (cancelToken != null) {
        tracker?.activeConsumers.remove(cancelToken);
      }

      consumerCompleter.completeError(ex);

      if (tracker != null &&
          tracker.activeConsumers.isEmpty &&
          cancelToken != null) {
        tracker.internalCancelToken.cancel('All consumers cancelled request');
      }
    }

    if (cancelToken != null) {
      cancelToken.addListener(cancellationListener);
    }

    unawaited(tracker.future.then((res) {
      if (cancelToken != null) {
        cancelToken.removeListener(cancellationListener);
      }
      if (!consumerCompleter.isCompleted) {
        consumerCompleter.complete(res);
      }
    }).catchError((Object err, StackTrace st) {
      if (cancelToken != null) {
        cancelToken.removeListener(cancellationListener);
      }
      if (!consumerCompleter.isCompleted) {
        consumerCompleter.completeError(err, st);
      }
    }));

    final NetworkResponse<dynamic> response = await consumerCompleter.future;
    final Map<String, dynamic> extraMap =
        Map<String, dynamic>.from(response.extra);
    extraMap['is_deduplicated'] = true;

    return _castResponse<T>(response.copyWith<dynamic>(extra: extraMap));
  }

  NetworkResponse<T> _castResponse<T>(NetworkResponse<dynamic> response) {
    if (response.data == null) {
      return response.copyWith<T>(data: null);
    }
    return response.copyWith<T>(data: response.data as T?);
  }

  /// Returns current inflight request count.
  int get inflightCount => _inflight.length;
}
