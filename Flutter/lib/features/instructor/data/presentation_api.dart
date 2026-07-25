import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'presentation_models.dart';

class PresentationApi {
  final ApiClient _client;

  PresentationApi(this._client);

  Future<GeneratePresentationResponse> generatePresentation({
    required int courseId,
    required int materialId,
    required GeneratePresentationRequest payload,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      Endpoints.generatePresentation(courseId, materialId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid response from presentation generation endpoint.',
      );
    }
    return GeneratePresentationResponse.fromJson(data);
  }

  Future<SseEvent> waitForPresentationGeneration({
    required int courseId,
    required int materialId,
    CancelToken? cancelToken,
  }) {
    return _client.waitForSseEvent(
      Endpoints.presentationGenerationStream(courseId, materialId),
      cancelToken: cancelToken,
      receiveTimeout: const Duration(minutes: 10),
    );
  }

  Future<PresentationGenerationResult> getPresentationResult({
    required int courseId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.presentationGenerationResult(courseId, materialId),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid response from presentation result endpoint.',
      );
    }
    return PresentationGenerationResult.fromJson(data);
  }
}
