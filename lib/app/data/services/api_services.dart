import 'package:dio/dio.dart';

import '../models/api_response_model.dart';
import '../providers/api_provider.dart';

class ApiServices {
    final ApiProvider _apiProvider = ApiProvider();

    // generic method to handle API calls
    Future<ApiResponse<T>> handleApiCall<T>(
        Future<Response> Function() apiCall,
        T Function(dynamic) fromJson
        ) async
    {
        try
        {
            final response = await apiCall();

            if (response.statusCode == 200 || response.statusCode == 201)
            {
                final data = fromJson(response.data);
                return ApiResponse.success(data);
            }
            else
            {
                return ApiResponse.error(
                    "Request failed with status: ${response.statusCode}",
                );
            }
        }
        on DioException catch (e)
        {
            return ApiResponse.error(
                e.message ?? "Network error occurred",
                statusCode: e.response?.statusCode
            );
        }
        catch (e)
        {
            return ApiResponse.error(e.toString());
        }
    }

    // generic method to handle List API calls
    Future<ApiResponse<List<T>>> handleListApiCall<T>(
        Future<Response> Function() apiCall,
        T Function(dynamic) fromJson
        ) async
    {
        try
        {
            final response = await apiCall();

            if (response.statusCode == 200 || response.statusCode == 201)
            {
                final List<dynamic> jsonList = response.data;
                final List<T> dataList = jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
                return ApiResponse.success(dataList);
            }
            else
            {
                return ApiResponse.error(
                    "Request failed with status: ${response.statusCode}",
                );
            }
        }
        on DioException catch (e)
        {
            return ApiResponse.error(
                e.message ?? "Network error occurred",
                statusCode: e.response?.statusCode
            );
        }
        catch (e)
        {
            return ApiResponse.error("$e");
        }
    }

    // specific GET method for API calls
    Future<ApiResponse<T>> get<T>(
        String endPint,
        T Function(dynamic) fromJson, {
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken
        }) async
    {
        return handleApiCall<T>(
                () => _apiProvider.get(
                endPint,
                queryParameters: queryParameters,
                cancelToken: cancelToken
            ),
            fromJson
        );
    }

    // specific Post method for List
    Future<ApiResponse<List<T>>> getList<T>(
        String endPint,
        T Function(dynamic) fromJson, {
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken
        }) async
    {
        return handleListApiCall<T>(
                () => _apiProvider.get(
                endPint,
                queryParameters: queryParameters,
                cancelToken: cancelToken
            ),
            fromJson
        );
    }

    // specific POST method
    Future<ApiResponse<T>> post<T>(
        String endPint,
        T Function(dynamic) fromJson, {
            dynamic data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken
        }) async
    {
        return handleApiCall<T>(
                () => _apiProvider.post(
                endPint,
                data: data,
                queryParameters: queryParameters,
                cancelToken: cancelToken
            ),
            fromJson
        );
    }

    // specific PUT method
    Future<ApiResponse<T>> put<T>(
        String endPint,
        T Function(dynamic) fromJson, {
            dynamic data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken
        }) async
    {
        return handleApiCall<T>(
                () => _apiProvider.put(
                endPint,
                data: data,
                queryParameters: queryParameters,
                cancelToken: cancelToken
            ),
            fromJson
        );
    }

    // specific DELETE method
    Future<ApiResponse<T>> delete<T>(
        String endPint,
        T Function(dynamic) fromJson, {
            dynamic data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken
        }) async
    {
        return handleApiCall<T>(
                () => _apiProvider.delete(
                endPint,
                data: data,
                queryParameters: queryParameters,
                cancelToken: cancelToken
            ),
            fromJson
        );
    }
}