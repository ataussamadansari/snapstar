import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:snapstar/app/core/constants/constants.dart';
import 'package:snapstar/app/data/models/api_response_model.dart';
import 'package:snapstar/app/data/models/auth/create_profile.dart';
import 'package:snapstar/app/data/models/auth/profile_setup.dart';
import 'package:snapstar/app/data/services/api_services.dart';

class AuthRepository {
  final ApiServices _apiServices = Get.find<ApiServices>();
  CancelToken? _cancelToken;

  // Firebase token ko backend se sync karne ke liye
  Future<ApiResponse<CreateProfile>> createProfile({
    required String name,
    required String email,
  }) async {
    try {
      _cancelToken = CancelToken();
      final response = await _apiServices.post(
        ApiConstants.createProfile,
        (json) => CreateProfile.fromJson(json),
        data: {'name': name, 'email': email},
        cancelToken: _cancelToken,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          response.data!,
          message: response.data!.message,
        );
      } else {
        return ApiResponse.error(
          response.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? "Something went wrong",
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResponse<ProfileSetup>> setupProfile({
    required String username,
    required String bio,
    required String imagePath,
  }) async {
    try {
      // File ko Multipart format mein convert karein
      FormData formData = FormData.fromMap({
        "username": username,
        "bio": bio,
        "avatar": await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final response = await _apiServices.post(
        ApiConstants.setupProfile,
        (json) => ProfileSetup.fromJson(json),
        data: formData,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  void cancelRequests() {
    _cancelToken?.cancel();
  }
}
