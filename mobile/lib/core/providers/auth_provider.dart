import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/user_model.dart';

const _tokenKey = 'kundliai_jwt';

/// In-memory JWT — null means unauthenticated.
final tokenProvider = StateProvider<String?>((ref) => null);

/// Dio instance rebuilt whenever the token changes.
final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(tokenProvider);
  return createDio(token);
});

/// Manages authentication state and token lifecycle.
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _init() async {
    final stored = await _storage.read(key: _tokenKey);
    if (stored == null) {
      state = const AsyncValue.data(null);
      return;
    }
    _ref.read(tokenProvider.notifier).state = stored;
    try {
      final dio = _ref.read(dioProvider);
      final resp = await dio.get(ApiEndpoints.authMe);
      state = AsyncValue.data(UserModel.fromJson(resp.data as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: _tokenKey);
        _ref.read(tokenProvider.notifier).state = null;
        state = const AsyncValue.data(null);
      } else {
        // Network error — keep stored token, let user retry
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String firebaseToken) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final resp = await dio.post(
        ApiEndpoints.authVerify,
        data: {'firebase_token': firebaseToken},
      );
      final body = resp.data as Map<String, dynamic>;
      final token = body['access_token'] as String;
      final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      await _storage.write(key: _tokenKey, value: token);
      _ref.read(tokenProvider.notifier).state = token;
      state = AsyncValue.data(user);
    } on DioException catch (e, st) {
      state = AsyncValue.error(
        e.response?.data?['detail'] ?? 'Authentication failed',
        st,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
    _ref.read(tokenProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref),
);
