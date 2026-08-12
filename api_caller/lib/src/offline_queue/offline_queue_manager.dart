import 'dart:async';

import '../exceptions/connection_exception.dart';
import '../exceptions/http_exceptions.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';

import 'offline_queue_config.dart';
import 'offline_queue_item.dart';
import 'queue_storage.dart';

typedef RawRequestExecutor = Future<NetworkResponse<dynamic>> Function(
    NetworkRequest request);

/// Concurrency-safe manager handling persistent offline mutation queueing,
/// automatic background drain on connectivity restoration, and priority ordering.
class OfflineQueueManager {
  final OfflineQueueConfig config;
  final QueueStorage storage;
  final List<OfflineQueueItem> _items = <OfflineQueueItem>[];

  bool _isProcessing = false;
  bool _isInitialized = false;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  OfflineQueueManager({
    OfflineQueueConfig? config,
  })  : config = config ?? const OfflineQueueConfig(),
        storage = config?.storage ?? MemoryQueueStorage();

  /// Stream emitting pending queue count changes.
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  /// Returns current pending queue count.
  int get pendingCount => _items.length;

  /// Returns read-only snapshot list of queued items.
  List<OfflineQueueItem> get items =>
      List<OfflineQueueItem>.unmodifiable(_items);

  /// Initializes manager loading persisted items from disk.
  Future<void> initialize() async {
    if (_isInitialized) return;
    final List<OfflineQueueItem> loaded = await storage.load();
    _items.clear();
    _items.addAll(loaded);
    _isInitialized = true;
    _notifyCountChanged();
  }

  /// Enqueues [request] to offline mutation queue if method is mutating (POST, PUT, PATCH, DELETE).
  Future<OfflineQueueItem?> enqueue(
    NetworkRequest request, {
    int priority = 0,
    int? maxAttempts,
    Duration? ttl,
  }) async {
    final String method = request.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') {
      return null;
    }

    await initialize();

    final String id =
        'q_${DateTime.now().microsecondsSinceEpoch}_${_items.length}';
    final DateTime createdAt = DateTime.now();
    final DateTime? expiresAt = ttl != null ? createdAt.add(ttl) : null;

    final OfflineQueueItem item = OfflineQueueItem(
      id: id,
      method: method,
      path: request.path,
      uri: request.uri,
      headers: request.headers,
      queryParameters: request.queryParameters,
      body: request.body,
      createdAt: createdAt,
      priority: priority,
      maxAttempts: maxAttempts ?? config.defaultMaxAttempts,
      expiresAt: expiresAt,
      metadata: request.extra,
    );

    _items.add(item);
    _sortItems();
    await storage.save(_items);
    _notifyCountChanged();
    return item;
  }

  /// Removes queue item by [id].
  Future<bool> removeItem(String id) async {
    await initialize();
    final int index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items.removeAt(index);
      await storage.save(_items);
      _notifyCountChanged();
      return true;
    }
    return false;
  }

  /// Clears queue completely.
  Future<void> clear() async {
    await initialize();
    _items.clear();
    await storage.clear();
    _notifyCountChanged();
  }

  /// Processes all eligible queue items sequentially using provided [executor].
  Future<List<NetworkResponse<dynamic>>> processQueue(
      RawRequestExecutor executor) async {
    if (_isProcessing) return <NetworkResponse<dynamic>>[];
    _isProcessing = true;

    await initialize();

    final List<NetworkResponse<dynamic>> results = <NetworkResponse<dynamic>>[];
    final List<OfflineQueueItem> currentQueue =
        List<OfflineQueueItem>.from(_items);

    for (final item in currentQueue) {
      if (item.isExpired) {
        _items.removeWhere((i) => i.id == item.id);
        await storage.save(_items);
        _notifyCountChanged();
        continue;
      }

      final NetworkRequest request = item.toNetworkRequest();

      try {
        final NetworkResponse<dynamic> response = await executor(request);
        results.add(response);
        _items.removeWhere((i) => i.id == item.id);
        await storage.save(_items);
        _notifyCountChanged();
      } catch (e) {
        if (e is ConnectionException) {
          break;
        }

        final int updatedRetries = item.retryCount + 1;
        if (updatedRetries >= item.maxAttempts || _isPermanentError(e)) {
          _items.removeWhere((i) => i.id == item.id);
        } else {
          final int idx = _items.indexWhere((i) => i.id == item.id);
          if (idx != -1) {
            _items[idx] = item.copyWith(
              retryCount: updatedRetries,
              lastError: e.toString(),
            );
          }
        }
        await storage.save(_items);
        _notifyCountChanged();
      }
    }

    _isProcessing = false;
    return results;
  }

  bool _isPermanentError(Object error) {
    if (error is HttpException) {
      final int? code = error.statusCode;
      if (code == 400 || code == 403 || code == 404 || code == 422) {
        return true;
      }
    }
    return false;
  }

  void _sortItems() {
    if (config.order == QueueOrder.priority) {
      _items.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  void _notifyCountChanged() {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(_items.length);
    }
  }

  void dispose() {
    _pendingCountController.close();
  }
}
