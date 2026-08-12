import 'dart:async';

/// Abstract service interface contract for observing network connectivity state.
abstract class ConnectivityService {
  /// Asynchronously returns true if an active internet connection exists.
  Future<bool> isConnected();

  /// Observable stream broadcasting network connectivity status updates.
  Stream<bool> get statusStream;
}

/// Default fallback [ConnectivityService] assuming host device is always connected.
class AlwaysConnectedConnectivityService implements ConnectivityService {
  const AlwaysConnectedConnectivityService();

  @override
  Future<bool> isConnected() async => true;

  @override
  Stream<bool> get statusStream => Stream<bool>.value(true);
}
