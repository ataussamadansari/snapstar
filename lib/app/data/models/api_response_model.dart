class ApiResponse<T>
{
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.errors
  });

  factory ApiResponse.success(T data, {String? message})
  {
    return ApiResponse<T>(
        success: true,
        message: message ?? "Success",
        data: data,
        statusCode: 200
    );
  }

  factory ApiResponse.error(String message,
      {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse<T>(
        success: false,
        message: message,
        statusCode: statusCode,
        errors: errors
    );
  }
}