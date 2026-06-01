import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/today_model.dart';

class TodayRepository {
  const TodayRepository(this._dio);
  final Dio _dio;

  Future<TodayModel> getToday() async {
    final resp = await _dio.get(ApiEndpoints.today);
    return TodayModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
