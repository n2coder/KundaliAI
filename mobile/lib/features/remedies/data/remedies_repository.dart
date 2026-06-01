import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/remedy_model.dart';

class RemediesRepository {
  const RemediesRepository(this._dio);
  final Dio _dio;

  Future<List<RemedyModel>> getRemedies() async {
    final resp = await _dio.get(ApiEndpoints.remedies);
    return (resp.data as List<dynamic>)
        .map((r) => RemedyModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<RemedyModel> getRemedy(String title) async {
    final resp = await _dio.get(ApiEndpoints.remedy(title));
    return RemedyModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
