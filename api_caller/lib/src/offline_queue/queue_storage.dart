import 'offline_queue_item.dart';

/// Abstract storage contract for persisting offline request queue items across app restarts.
abstract class QueueStorage {
  /// Saves list of queue items to persistent storage.
  Future<void> save(List<OfflineQueueItem> items);

  /// Loads list of queue items from persistent storage.
  Future<List<OfflineQueueItem>> load();

  /// Clears stored queue items.
  Future<void> clear();
}

/// Memory-backed queue storage for testing or temporary queueing.
class MemoryQueueStorage implements QueueStorage {
  List<OfflineQueueItem> _items = <OfflineQueueItem>[];

  @override
  Future<void> save(List<OfflineQueueItem> items) async {
    _items = List<OfflineQueueItem>.from(items);
  }

  @override
  Future<List<OfflineQueueItem>> load() async {
    return List<OfflineQueueItem>.from(_items);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}
