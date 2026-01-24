import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String baseUrl = dotenv.env['BASE_URL']!;

  // --- AUTH ---
  static const String createProfile = "/auth/create-profile"; // POST
  static const String setupProfile = "/auth/setup-profile"; // POST

  // ----- USER -------
  static const String updateProfile = "/user/update-profile"; // POST
  static const String getProfile = "/user/get-profile"; // GET

  // --- FOLLOWS ---
  static const String follow = "/follow/follow"; // POST
  static const String unFollow = "/follow/unfollow"; // POST
  static const String accept = "/follow/accept"; // POST
  static const String reject = "/follow/reject"; // POST
  static const String followers = "/follow/followers/:userId"; // GET
  static const String following = "/follow/following/:userId"; // GET
  static const String pendingRequests = "/follow/pending-requests"; // GET
  static const String status = "/follow/status/:targetUid"; // GET

  // --- POSTS ---
  static const String createPost = "/post/create-post"; // POST

  // Headers
  static const String contentType = "application/json";
  static const String authorization = "Authorization";
  static const String acceptLanguage = "Accept-Language";

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}
