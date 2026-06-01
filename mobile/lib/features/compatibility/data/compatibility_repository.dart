import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/compatibility_model.dart';

class CompatibilityRepository {
  const CompatibilityRepository(this._dio);
  final Dio _dio;

  Future<CompatibilityModel> check({
    required String partnerDob,
    required String partnerTob,
    required String partnerBirthPlace,
  }) async {
    final resp = await _dio.post(
      ApiEndpoints.compatibility,
      data: {
        'partner_dob': partnerDob,
        'partner_tob': partnerTob,
        'partner_birth_place': partnerBirthPlace,
      },
    );
    return CompatibilityModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
