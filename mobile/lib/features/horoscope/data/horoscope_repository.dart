import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/horoscope_model.dart';

class HoroscopeRepository {
  const HoroscopeRepository(this._dio);
  final Dio _dio;

  Future<HoroscopeModel> getDaily() async {
    final resp = await _dio.get(ApiEndpoints.horoscopeDaily);
    return HoroscopeModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<HoroscopeModel> getWeekly() async {
    final resp = await _dio.get(ApiEndpoints.horoscopeWeekly);
    return HoroscopeModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<HoroscopeModel> getMonthly() async {
    final resp = await _dio.get(ApiEndpoints.horoscopeMonthly);
    return HoroscopeModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> updateWhatsApp({
    required bool enabled,
    String? deliveryTime,
  }) async {
    await _dio.patch(
      ApiEndpoints.horoscopeWhatsApp,
      data: {
        'enabled': enabled,
        if (deliveryTime != null) 'delivery_time': deliveryTime,
      },
    );
  }
}
