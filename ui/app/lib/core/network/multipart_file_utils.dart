import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

/// Builds [MultipartFile] from [XFile] — works on mobile and web (no dart:io).
Future<MultipartFile> multipartFileFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  final rawName = file.name.trim();
  final mime = (file.mimeType?.trim().isNotEmpty == true)
      ? file.mimeType!.trim()
      : lookupMimeType(rawName.isNotEmpty ? rawName : 'upload.jpg', headerBytes: bytes) ??
          'application/octet-stream';

  var name = rawName.isNotEmpty ? rawName : _defaultFileName(mime);
  // image_picker / web often yields "blob" or names without an extension.
  if (!name.contains('.') || name == 'blob' || name == 'image') {
    name = _defaultFileName(mime);
  }

  return MultipartFile.fromBytes(
    bytes,
    filename: name,
    contentType: MediaType.parse(mime),
  );
}

String _defaultFileName(String mime) {
  final subtype = mime.contains('/') ? mime.split('/').last : 'bin';
  return switch (subtype) {
    'jpeg' || 'jpg' => 'upload.jpg',
    'png' => 'upload.png',
    'gif' => 'upload.gif',
    'webp' => 'upload.webp',
    'mp4' => 'upload.mp4',
    'webm' => 'upload.webm',
    'quicktime' => 'upload.mov',
    'mpeg' => 'upload.mpeg',
    _ => 'upload.$subtype',
  };
}
