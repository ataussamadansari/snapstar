import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio = Dio();

  // Firebase token ko backend se sync karne ke liye
  Future<Response> syncUserWithBackend(String token) async {
    return await _dio.post(
      '/api/sync-user',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
      }),
    );
  }
}