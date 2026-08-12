import 'dart:convert';
import 'dart:io';

import 'offline_queue_item.dart';
import 'queue_storage.dart';

/// Cross-platform JSON file queue storage engine for persisting offline mutation requests.
class FileQueueStorage implements QueueStorage {
  final File file;

  FileQueueStorage(this.file);

  @override
  Future<void> save(List<OfflineQueueItem> items) async {
    try {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final List<Map<String, dynamic>> jsonList =
          items.map((i) => i.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (_) {}
  }

  @override
  Future<List<OfflineQueueItem>> load() async {
    try {
      if (!await file.exists()) return <OfflineQueueItem>[];
      final String content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .map((item) =>
                OfflineQueueItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return <OfflineQueueItem>[];
    } catch (_) {
      return <OfflineQueueItem>[];
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
