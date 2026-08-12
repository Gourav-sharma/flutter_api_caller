import 'dart:typed_data';

/// Represents a file for multipart/form-data requests.
class MultipartFile {
  /// The form field name associated with this file.
  final String field;

  /// File path on disk (if available).
  final String? path;

  /// Raw file byte content (if available).
  final Uint8List? bytes;

  /// Custom filename sent with the request header.
  final String? filename;

  /// Content-Type header value for the file (e.g. `image/jpeg`).
  final String? contentType;

  const MultipartFile({
    required this.field,
    this.path,
    this.bytes,
    this.filename,
    this.contentType,
  }) : assert(
          path != null || bytes != null,
          'Either path or bytes must be provided to create a MultipartFile.',
        );

  /// Factory constructor for creating a [MultipartFile] from a file path.
  factory MultipartFile.fromPath(
    String path, {
    required String field,
    String? filename,
    String? contentType,
  }) {
    return MultipartFile(
      field: field,
      path: path,
      filename: filename,
      contentType: contentType,
    );
  }

  /// Factory constructor for creating a [MultipartFile] from raw bytes.
  factory MultipartFile.fromBytes(
    List<int> bytes, {
    required String field,
    required String filename,
    String? contentType,
  }) {
    return MultipartFile(
      field: field,
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      contentType: contentType,
    );
  }
}
