import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'topics_models.dart';

class TopicsApi {
  final ApiClient _client;
  TopicsApi(this._client);

  /// GET /courses/{courseId}/modules/{moduleId}/topics
  Future<TopicListResponse> listTopics({
    required int courseId,
    required int moduleId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.moduleTopics(courseId, moduleId),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return TopicListResponse.fromJson(data);
    throw const FormatException('Invalid response from GET topics');
  }

  /// POST /courses/{courseId}/modules/{moduleId}/topics
  Future<TopicItem> createTopic({
    required int courseId,
    required int moduleId,
    required TopicCreateRequest payload,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.moduleTopics(courseId, moduleId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return TopicItem.fromJson(data);
    throw const FormatException('Invalid response from POST topic');
  }
}