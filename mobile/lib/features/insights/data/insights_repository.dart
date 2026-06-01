import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/insight_model.dart';

class InsightsRepository {
  const InsightsRepository(this._dio);
  final Dio _dio;

  Future<List<InsightModel>> getAllInsights() async {
    final resp = await _dio.get(ApiEndpoints.insights);
    return (resp.data as List<dynamic>)
        .map((i) => InsightModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<InsightModel> getInsight(String category) async {
    final resp = await _dio.get(ApiEndpoints.insight(category));
    return InsightModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
