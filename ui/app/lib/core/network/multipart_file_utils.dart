import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Builds [MultipartFile] from [XFile] — works on mobile and web (no dart:io).
Future<MultipartFile> multipartFileFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  final name = file.name.isNotEmpty ? file.name : 'upload.jpg';
  return MultipartFile.fromBytes(bytes, filename: name);
}
