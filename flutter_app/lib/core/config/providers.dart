import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/api_client.dart';

part 'providers.g.dart';

/// Dio HTTP 클라이언트 (Cloud Run API)
@riverpod
Dio apiClient(Ref ref) => createApiClient();
