import '../request/network_request.dart';
import '../response/network_response.dart';

/// Abstract transport contract decoupling `flutter_api_caller` from specific HTTP engines.
abstract class NetworkTransport {
  /// Sends a [NetworkRequest] and returns a raw [NetworkResponse].
  Future<NetworkResponse<dynamic>> send(NetworkRequest request);

  /// Closes persistent HTTP connections and disposes resources.
  void close();
}
