import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final productImportsRepositoryProvider =
    Provider<ProductImportsRepository>((ref) {
  return ProductImportsRepository(ref.watch(apiClientProvider));
});

class ProductImportsRepository {
  final ApiClient _apiClient;

  ProductImportsRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getJobs() async {
    final response = await _apiClient.get(ApiEndpoints.productImportJobs);
    final raw = response.data is Map ? response.data['data'] : null;
    final items = raw is List ? raw : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getJob(String id) async {
    final response = await _apiClient.get(ApiEndpoints.productImportJob(id));
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getRows(String id) async {
    final response = await _apiClient.get(ApiEndpoints.productImportRows(id));
    final raw = response.data is Map ? response.data['data'] : null;
    final items = raw is List ? raw : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> upload({
    String? organizationId,
    required String branchId,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    final path = file.path;
    MultipartFile multipart;
    if (bytes != null) {
      multipart = MultipartFile.fromBytes(Uint8List.fromList(bytes),
          filename: file.name);
    } else if (path != null) {
      multipart = await MultipartFile.fromFile(path, filename: file.name);
    } else {
      throw Exception('تعذر قراءة ملف Excel');
    }

    final form = FormData.fromMap({
      'branchId': branchId,
      'file': multipart,
    });

    final response = await _apiClient
        .uploadMultipart(ApiEndpoints.productImportUpload, data: form);
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> confirm(String jobId) async {
    final response =
        await _apiClient.post(ApiEndpoints.productImportConfirm(jobId));
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}
