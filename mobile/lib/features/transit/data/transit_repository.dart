import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/transit_model.dart';

class TransitRepository {
  const TransitRepository(this._dio);
  final Dio _dio;

  Future<List<TransitModel>> getTransits() async {
    final resp = await _dio.get(ApiEndpoints.transits);
    return (resp.data as List<dynamic>)
        .map((t) => TransitModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }
}
