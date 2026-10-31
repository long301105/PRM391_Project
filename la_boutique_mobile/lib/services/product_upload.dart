import 'dart:convert';

import 'package:dio/dio.dart';

/// Web provides bytes; native may use the selected file's local path.
class ProductUploadImage {
  const ProductUploadImage({
    required this.filePath,
    required this.fileName,
    this.bytes,
  });
  final String filePath;
  final String fileName;
  final List<int>? bytes;
}

/// A fresh multipart body is needed for every HTTP attempt, including a 401 retry.
Future<FormData> buildProductUploadForm(
  Map<String, dynamic> metadata,
  List<ProductUploadImage> images,
) async {
  final form = FormData();
  form.files.add(
    MapEntry(
      'metadata',
      MultipartFile.fromString(
        jsonEncode(metadata),
        contentType: DioMediaType('application', 'json'),
      ),
    ),
  );
  for (final image in images) {
    final file = image.bytes != null
        ? MultipartFile.fromBytes(
            image.bytes!,
            filename: image.fileName,
            contentType: DioMediaType('application', 'octet-stream'),
          )
        : await MultipartFile.fromFile(
            image.filePath,
            filename: image.fileName,
            contentType: DioMediaType('application', 'octet-stream'),
          );
    form.files.add(MapEntry('images', file));
  }
  return form;
}
