import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'modules_models.dart';

class ModulesApi {
  final ApiClient _client;
  ModulesApi(this._client);

  Future<ModuleListResponse> listModules({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.courseModules(courseId),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return ModuleListResponse.fromJson(data);
    throw const FormatException('Invalid response from GET modules');
  }

  Future<ModuleItem> createModule({
    required int courseId,
    required ModuleCreateRequest payload,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.createModule(courseId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return ModuleItem.fromJson(data);
    throw const FormatException('Invalid response from POST module');
  }
}
