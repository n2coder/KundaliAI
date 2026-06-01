import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/birth_chart_model.dart';

class GeocodeResult {
  const GeocodeResult({
    required this.place,
    required this.lat,
    required this.lng,
    this.timezone,
  });
  final String place;
  final double lat;
  final double lng;
  final String? timezone;

  factory GeocodeResult.fromJson(Map<String, dynamic> j) => GeocodeResult(
        place: j['place'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        timezone: j['timezone'] as String?,
      );
}

class BirthChartRepository {
  const BirthChartRepository(this._dio);
  final Dio _dio;

  Future<GeocodeResult> geocode(String place) async {
    final resp = await _dio.get(
      ApiEndpoints.birthChartGeocode,
      queryParameters: {'place': place},
    );
    return GeocodeResult.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> computeChart({
    String? name,
    required String dob,
    required String tob,
    required String birthPlace,
    double? birthLat,
    double? birthLng,
  }) async {
    await _dio.post(
      ApiEndpoints.birthChartCompute,
      data: {
        if (name != null) 'name': name,
        'dob': dob,
        'tob': tob,
        'birth_place': birthPlace,
        if (birthLat != null) 'birth_lat': birthLat,
        if (birthLng != null) 'birth_lng': birthLng,
      },
    );
  }

  Future<BirthChartModel> getChart() async {
    final resp = await _dio.get(ApiEndpoints.birthChartGet);
    return BirthChartModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
