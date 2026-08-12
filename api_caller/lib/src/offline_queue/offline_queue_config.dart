import 'queue_storage.dart';

/// Processing order for offline queue items.
enum QueueOrder {
  /// First In First Out.
  fifo,

  /// Priority based ordering (higher priority executed first).
  priority,
}

/// Configuration options for the offline mutation queue.
class OfflineQueueConfig {
  /// Whether automatic background queue processing on connectivity restoration is enabled.
  final bool autoProcessOnReconnect;

  /// Ordering strategy for queue processing.
  final QueueOrder order;

  /// Maximum retry attempts for queued items before marking failed.
  final int defaultMaxAttempts;

  /// Storage engine for persisting queue across app restarts.
  final QueueStorage? storage;

  const OfflineQueueConfig({
    this.autoProcessOnReconnect = true,
    this.order = QueueOrder.fifo,
    this.defaultMaxAttempts = 5,
    this.storage,
  });
}
