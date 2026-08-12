import 'dart:async';

import '../exceptions/connection_exception.dart';
import '../request/network_request.dart';
import 'connectivity_policy.dart';
import 'connectivity_service.dart';

/// Manager coordinating network status inspection and connectivity policy enforcement.
class ConnectivityManager {
  final ConnectivityService service;

  ConnectivityManager({
    ConnectivityService? service,
  }) : service = service ?? const AlwaysConnectedConnectivityService();

  /// Returns current connectivity state.
  Future<bool> isConnected() => service.isConnected();

  /// Observable stream of connectivity status changes.
  Stream<bool> get statusStream => service.statusStream;

  /// Ensures connectivity requirements are met for [request] according to [policy].
  Future<void> handleConnectivity(
    NetworkRequest request,
    ConnectivityPolicy policy,
  ) async {
    final bool connected = await service.isConnected();
    if (connected) return;

    if (policy == ConnectivityPolicy.failFast) {
      throw ConnectionException(
        message: 'No active network connectivity available.',
        request: request,
      );
    }

    if (policy == ConnectivityPolicy.waitForConnection) {
      await waitForConnectivity(request);
    }
  }

  /// Blocks execution until [service.statusStream] emits a true (connected) state.
  Future<void> waitForConnectivity(
    NetworkRequest request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await service.isConnected()) return;

    final Completer<void> completer = Completer<void>();
    late StreamSubscription<bool> sub;

    sub = service.statusStream.listen((bool connected) {
      if (connected && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
      }
    });

    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      await sub.cancel();
      throw ConnectionException(
        message: 'Timed out waiting for network connectivity restoration.',
        request: request,
      );
    }
  }
}
