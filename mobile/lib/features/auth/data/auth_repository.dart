import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/user_model.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  Future<UserModel> getMe() async {
    final resp = await _dio.get(ApiEndpoints.authMe);
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe(Map<String, dynamic> updates) async {
    final resp = await _dio.patch(ApiEndpoints.usersMe, data: updates);
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteMe() async {
    await _dio.delete(ApiEndpoints.usersMe);
  }

  Future<void> clearChat() async {
    await _dio.post(ApiEndpoints.usersClearChat);
  }
}
