import 'multipart_file.dart';

/// Container for multipart/form-data payload containing fields and files.
class MultipartRequest {
  /// Text form fields.
  final Map<String, String> fields;

  /// Attached files.
  final List<MultipartFile> files;

  const MultipartRequest({
    this.fields = const <String, String>{},
    this.files = const <MultipartFile>[],
  });
}
