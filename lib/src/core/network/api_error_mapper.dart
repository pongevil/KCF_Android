import 'dart:convert';

import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:dio/dio.dart';

class ApiErrorMapper {
  const ApiErrorMapper();

  Future<String> fromDioException(DioException error) async {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.connectionError:
        final hasNetwork = await AppStorage.getNetwork();
        return hasNetwork
            ? 'Failed to connect to server'
            : 'No internet connection';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badResponse:
        return fromStatusCode(error.response?.statusCode, error.response?.data);
      case DioExceptionType.unknown:
        final hasNetwork = await AppStorage.getNetwork();
        return hasNetwork ? 'Something went wrong' : 'No internet connection';
      default:
        return 'Something went wrong';
    }
  }

  String fromStatusCode(int? statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return extractMessage(data);
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return extractMessage(data);
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      default:
        return 'Oops something went wrong';
    }
  }

  String extractMessage(dynamic error) {
    if (error == null) return 'Bad request';
    try {
      if (error is String) {
        try {
          return extractMessage(jsonDecode(error));
        } catch (_) {
          return error;
        }
      }
      if (error is Map) {
        final map = Map<String, dynamic>.from(error);
        for (final key in [
          'message_text',
          'messageText',
          'message',
          'Message',
          'error',
          'msg',
          'detail',
        ]) {
          final value = map[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
        final errs = map['errors'];
        if (errs is List) return errs.map((e) => e.toString()).join(', ');
        if (errs is Map) {
          final parts = <String>[];
          errs.forEach((_, v) {
            if (v is List) {
              parts.addAll(v.map((e) => e.toString()));
            } else if (v != null) {
              parts.add(v.toString());
            }
          });
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
      if (error is List) return error.map((e) => e.toString()).join(', ');
    } catch (_) {}
    return error.toString();
  }
}
