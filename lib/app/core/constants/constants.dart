import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String baseUrl = dotenv.env['BASE_URL']!;

  // ----- DEMO -------
  static const String demo = "/demo"; // POST

  // Headers
  static const String contentType = "application/json";
  static const String authorization = "Authorization";
  static const String acceptLanguage = "Accept-Language";

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}
