import 'dart:async';

import '../auth/auth_config.dart';
import '../auth/auth_manager.dart';
import '../cache/cache_config.dart';
import '../cache/cache_manager.dart';
import '../cache/cache_policy.dart';
import '../cancellation/cancel_token.dart';
import '../connectivity/connectivity_manager.dart';
import '../connectivity/connectivity_policy.dart';
import '../connectivity/connectivity_service.dart';
import '../deduplication/deduplication_manager.dart';
import '../exceptions/connection_exception.dart';
import '../exceptions/http_exceptions.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/serialization_exception.dart';
import '../interceptors/interceptor_handler.dart';
import '../interceptors/network_interceptor.dart';
import '../logging/network_logger.dart';
import '../multipart/multipart_request.dart';
import '../offline_queue/offline_queue_config.dart';
import '../offline_queue/offline_queue_manager.dart';
import '../request/network_request.dart';
import '../request/request_options.dart';
import '../response/network_response.dart';
import '../retry/retry_manager.dart';
import '../retry/retry_policy.dart';
import '../transport/http_network_transport.dart';
import '../transport/network_transport.dart';
import '../utils/header_utils.dart';
import '../utils/url_builder.dart';
import 'network_options.dart';

/// Primary HTTP client interface for executing requests in `flutter_api_caller`.
class NetworkClient {
  /// Configuration options governing this client instance.
  final NetworkOptions options;

  /// Underlying transport engine.
  final NetworkTransport _transport;

  /// Complete list of active interceptors.
  final List<NetworkInterceptor> _interceptors;

  /// Composed managers for specialized networking features
  final AuthManager? _authManager;
  final RetryManager _retryManager;
  final ConnectivityManager _connectivityManager;
  final CacheManager _cacheManager;
  final DeduplicationManager _deduplicationManager;
  final OfflineQueueManager _offlineQueueManager;

  /// Constructs a [NetworkClient] with configurable settings.
  NetworkClient({
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    List<NetworkInterceptor>? interceptors,
    NetworkLogger? logger,
    NetworkTransport? transport,
    AuthConfig? auth,
    RetryPolicy? retryPolicy,
    CacheConfig? cacheConfig,
    ConnectivityPolicy? connectivityPolicy,
    ConnectivityService? connectivityService,
    OfflineQueueConfig? offlineQueueConfig,
    NetworkOptions? options,
  })  : options = options ??
            NetworkOptions(
              baseUrl: baseUrl,
              headers: headers,
              queryParameters: queryParameters,
              connectTimeout: connectTimeout,
              sendTimeout: sendTimeout,
              receiveTimeout: receiveTimeout,
              interceptors: interceptors ?? const <NetworkInterceptor>[],
              logger: logger,
              transport: transport,
              auth: auth,
              retryPolicy: retryPolicy,
              cacheConfig: cacheConfig,
              connectivityPolicy: connectivityPolicy,
              connectivityService: connectivityService,
              offlineQueueConfig: offlineQueueConfig,
            ),
        _transport = transport ?? options?.transport ?? HttpNetworkTransport(),
        _interceptors = <NetworkInterceptor>[
          if (logger != null) logger,
          if ((options?.logger ?? logger) != null) (options?.logger ?? logger)!,
          ...?interceptors,
          ...?options?.interceptors,
        ],
        _authManager = (auth ?? options?.auth) != null
            ? AuthManager((auth ?? options?.auth)!)
            : null,
        _retryManager = RetryManager(
            retryPolicy ?? options?.retryPolicy ?? const RetryPolicy()),
        _connectivityManager = ConnectivityManager(
            service: connectivityService ?? options?.connectivityService),
        _cacheManager =
            CacheManager(config: cacheConfig ?? options?.cacheConfig),
        _deduplicationManager = DeduplicationManager(),
        _offlineQueueManager = OfflineQueueManager(
            config: offlineQueueConfig ?? options?.offlineQueueConfig) {
    if (this.options.offlineQueueConfig?.autoProcessOnReconnect ?? true) {
      _connectivityManager.statusStream.listen((bool connected) {
        if (connected) {
          unawaited(_offlineQueueManager.processQueue((req) => request<dynamic>(
                req.path,
                method: req.method,
                body: req.body,
                headers: req.headers,
                queryParameters: req.queryParameters,
              )));
        }
      });
    }
  }

  /// Returns active AuthManager instance if configured.
  AuthManager? get authManager => _authManager;

  /// Returns active CacheManager instance.
  CacheManager get cacheManager => _cacheManager;

  /// Returns active ConnectivityManager instance.
  ConnectivityManager get connectivityManager => _connectivityManager;

  /// Returns active OfflineQueueManager instance.
  OfflineQueueManager get offlineQueueManager => _offlineQueueManager;

  /// Executes an HTTP GET request.
  Future<NetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    CachePolicy? cachePolicy,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      options: options?.copyWith(
            cancelToken: cancelToken ?? options.cancelToken,
            cachePolicy: cachePolicy ?? options.cachePolicy,
          ) ??
          RequestOptions(
            cancelToken: cancelToken,
            cachePolicy: cachePolicy,
          ),
    );
  }

  /// Executes an HTTP POST request.
  Future<NetworkResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    MultipartRequest? multipart,
    CancelToken? cancelToken,
    OfflinePolicy? offlinePolicy,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'POST',
      body: data,
      queryParameters: queryParameters,
      headers: headers,
      multipart: multipart,
      options: options?.copyWith(
            cancelToken: cancelToken ?? options.cancelToken,
            offlinePolicy: offlinePolicy ?? options.offlinePolicy,
          ) ??
          RequestOptions(
            cancelToken: cancelToken,
            offlinePolicy: offlinePolicy,
          ),
    );
  }

  /// Executes an HTTP PUT request.
  Future<NetworkResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    MultipartRequest? multipart,
    CancelToken? cancelToken,
    OfflinePolicy? offlinePolicy,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'PUT',
      body: data,
      queryParameters: queryParameters,
      headers: headers,
      multipart: multipart,
      options: options?.copyWith(
            cancelToken: cancelToken ?? options.cancelToken,
            offlinePolicy: offlinePolicy ?? options.offlinePolicy,
          ) ??
          RequestOptions(
            cancelToken: cancelToken,
            offlinePolicy: offlinePolicy,
          ),
    );
  }

  /// Executes an HTTP PATCH request.
  Future<NetworkResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    MultipartRequest? multipart,
    CancelToken? cancelToken,
    OfflinePolicy? offlinePolicy,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'PATCH',
      body: data,
      queryParameters: queryParameters,
      headers: headers,
      multipart: multipart,
      options: options?.copyWith(
            cancelToken: cancelToken ?? options.cancelToken,
            offlinePolicy: offlinePolicy ?? options.offlinePolicy,
          ) ??
          RequestOptions(
            cancelToken: cancelToken,
            offlinePolicy: offlinePolicy,
          ),
    );
  }

  /// Executes an HTTP DELETE request.
  Future<NetworkResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    OfflinePolicy? offlinePolicy,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'DELETE',
      body: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options?.copyWith(
            cancelToken: cancelToken ?? options.cancelToken,
            offlinePolicy: offlinePolicy ?? options.offlinePolicy,
          ) ??
          RequestOptions(
            cancelToken: cancelToken,
            offlinePolicy: offlinePolicy,
          ),
    );
  }

  /// Executes an HTTP HEAD request.
  Future<NetworkResponse<T>> head<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    RequestOptions? options,
  }) {
    return request<T>(
      path,
      method: 'HEAD',
      queryParameters: queryParameters,
      headers: headers,
      options:
          options?.copyWith(cancelToken: cancelToken ?? options.cancelToken) ??
              RequestOptions(cancelToken: cancelToken),
    );
  }

  /// Core request dispatcher pipeline handling URL building, header merging,
  /// interceptor chains, auth injection, single-flight refresh, retry, caching,
  /// cancellation, deduplication, offline queueing, and typing.
  Future<NetworkResponse<T>> request<T>(
    String path, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    MultipartRequest? multipart,
    RequestOptions? options,
  }) async {
    final Map<String, dynamic> mergedQueryParams = <String, dynamic>{
      if (this.options.queryParameters != null)
        ...this.options.queryParameters!,
      if (options?.queryParameters != null) ...options!.queryParameters!,
      if (queryParameters != null) ...queryParameters,
    };

    final Uri resolvedUri = UrlBuilder.buildUri(
      baseUrl: this.options.baseUrl,
      path: path,
      queryParameters: mergedQueryParams,
    );

    final Map<String, String> mergedHeaders = HeaderUtils.mergeHeaders(
      this.options.headers,
      HeaderUtils.mergeHeaders(options?.headers, headers),
    );

    if (multipart != null) {
      if (HeaderUtils.getHeaderValue(mergedHeaders, 'content-type') == null) {
        mergedHeaders['Content-Type'] = 'multipart/form-data';
      }
    } else if (body != null &&
        HeaderUtils.getHeaderValue(mergedHeaders, 'content-type') == null) {
      mergedHeaders['Content-Type'] = 'application/json; charset=utf-8';
    }

    final Duration effectiveConnectTimeout =
        options?.connectTimeout ?? this.options.connectTimeout;
    final Duration effectiveSendTimeout =
        options?.sendTimeout ?? this.options.sendTimeout;
    final Duration effectiveReceiveTimeout =
        options?.receiveTimeout ?? this.options.receiveTimeout;

    final CancelToken? cancelToken = options?.cancelToken;
    final CachePolicy? cachePolicy =
        options?.cachePolicy ?? this.options.cacheConfig?.policy;
    final RetryPolicy retryPolicy = options?.retryPolicy ??
        this.options.retryPolicy ??
        _retryManager.policy;
    final ConnectivityPolicy connectivityPolicy = options?.connectivityPolicy ??
        this.options.connectivityPolicy ??
        ConnectivityPolicy.failFast;
    final OfflinePolicy? offlinePolicy = options?.offlinePolicy;
    final bool enableDeduplicate =
        options?.deduplicate ?? this.options.enableDeduplication;

    final String requestId = 'req_${DateTime.now().microsecondsSinceEpoch}';
    final DateTime startTime = DateTime.now();

    final Map<String, dynamic> requestExtra = <String, dynamic>{
      if (options?.extra != null) ...options!.extra!,
      'request_id': requestId,
      'start_time': startTime.toIso8601String(),
    };

    NetworkRequest currentRequest = NetworkRequest(
      method: method.toUpperCase(),
      path: path,
      uri: resolvedUri,
      headers: mergedHeaders,
      queryParameters: mergedQueryParams,
      body: body,
      multipart: multipart,
      connectTimeout: effectiveConnectTimeout,
      sendTimeout: effectiveSendTimeout,
      receiveTimeout: effectiveReceiveTimeout,
      extra: requestExtra,
      cancelToken: cancelToken,
      cachePolicy: cachePolicy,
      cacheTtl: options?.cacheTtl,
      retryPolicy: retryPolicy,
      connectivityPolicy: connectivityPolicy,
      offlinePolicy: offlinePolicy,
      deduplicate: enableDeduplicate,
    );

    cancelToken?.throwIfCancelled(currentRequest);

    // 1. Memory / Disk Cache Lookup Step
    if (cachePolicy != null && cachePolicy != CachePolicy.networkOnly) {
      final NetworkResponse<dynamic>? cachedResponse =
          await _cacheManager.getResponse(currentRequest, policy: cachePolicy);

      if (cachedResponse != null) {
        if (cachePolicy == CachePolicy.staleWhileRevalidate) {
          unawaited(_executeNetworkAndCache<T>(
              currentRequest, retryPolicy, cancelToken));
          return _castResponse<T>(cachedResponse);
        } else {
          return _castResponse<T>(cachedResponse);
        }
      } else if (cachePolicy == CachePolicy.cacheOnly) {
        throw ConnectionException(
          message:
              'Cache miss for request configured with CachePolicy.cacheOnly.',
          request: currentRequest,
        );
      }
    }

    // 2. Connectivity Inspection & Offline Queue Step
    final bool isOnline = await _connectivityManager.isConnected();
    if (!isOnline) {
      if (offlinePolicy == OfflinePolicy.queue ||
          connectivityPolicy == ConnectivityPolicy.queueRequest) {
        final queuedItem = await _offlineQueueManager.enqueue(currentRequest);
        final Map<String, dynamic> extraMap =
            Map<String, dynamic>.from(currentRequest.extra);
        extraMap['is_offline_queued'] = true;
        extraMap['queue_id'] = queuedItem?.id;

        return NetworkResponse<T>(
          statusCode: 202,
          statusMessage: 'Request queued offline',
          headers: const <String, String>{},
          request: currentRequest,
          extra: extraMap,
        );
      } else if (connectivityPolicy == ConnectivityPolicy.useCache) {
        final NetworkResponse<dynamic>? cachedResponse = await _cacheManager
            .getResponse(currentRequest, policy: CachePolicy.cacheFirst);
        if (cachedResponse != null) {
          return _castResponse<T>(cachedResponse);
        }
      }

      await _connectivityManager.handleConnectivity(
          currentRequest, connectivityPolicy);
    }

    // 3. Request Deduplication Step
    return _deduplicationManager.deduplicate<T>(
      request: currentRequest,
      cancelToken: cancelToken,
      enabled: enableDeduplicate &&
          (currentRequest.method == 'GET' || currentRequest.method == 'HEAD'),
      requestFetcher: (effectiveCancelToken) async {
        if (effectiveCancelToken != null) {
          currentRequest =
              currentRequest.copyWith(cancelToken: effectiveCancelToken);
        }
        return await _executePipelineWithRetry<dynamic>(
            currentRequest, retryPolicy);
      },
    );
  }

  /// Executes transport request with interceptors, Auth single-flight refresh, and Retry policy loop.
  Future<NetworkResponse<dynamic>> _executePipelineWithRetry<R>(
    NetworkRequest request,
    RetryPolicy retryPolicy,
  ) async {
    NetworkRequest currentRequest = request;
    final RetryManager retryManager = RetryManager(retryPolicy);
    int attempt = 1;
    bool refreshAttempted = false;

    final AuthManager? authMgr = _authManager;

    while (true) {
      currentRequest.cancelToken?.throwIfCancelled(currentRequest);

      try {
        // 1. Attach Auth credentials
        if (authMgr != null) {
          currentRequest = await authMgr.attachCredentials(currentRequest);
        }

        // 2. Execute Request Interceptor Pipeline
        NetworkResponse<dynamic>? earlyResponse;
        for (final interceptor in _interceptors) {
          final RequestInterceptorHandler handler = RequestInterceptorHandler();
          await interceptor.onRequest(currentRequest, handler);

          if (handler.state == InterceptorState.next) {
            currentRequest = handler.resultData as NetworkRequest;
          } else if (handler.state == InterceptorState.resolve) {
            earlyResponse = handler.resultData as NetworkResponse<dynamic>;
            break;
          } else if (handler.state == InterceptorState.reject) {
            throw handler.resultData as NetworkException;
          }
        }

        // 3. Execute Transport
        NetworkResponse<dynamic> rawResponse;
        if (earlyResponse != null) {
          rawResponse = earlyResponse;
        } else {
          rawResponse = await _transport.send(currentRequest);
        }

        // 4. Handle HTTP 401 Unauthorized single-flight Token Refresh
        if (rawResponse.statusCode == 401 &&
            authMgr != null &&
            !refreshAttempted &&
            authMgr.shouldAuthenticate(currentRequest)) {
          refreshAttempted = true;
          try {
            await authMgr.refreshTokens(currentRequest);
            currentRequest = await authMgr.attachCredentials(currentRequest);
            attempt++;
            continue;
          } on NetworkException {
            rethrow;
          }
        }

        // 5. Handle HTTP Status Code errors
        if (!rawResponse.isSuccess) {
          final String message =
              'HTTP ${rawResponse.statusCode} (${rawResponse.statusMessage ?? "Request Failed"})';
          throw HttpException.fromStatusCode(
            statusCode: rawResponse.statusCode,
            message: message,
            request: currentRequest,
            responseData: rawResponse.data,
          );
        }

        // 6. Execute Response Interceptor Pipeline
        NetworkResponse<dynamic> currentResponse = rawResponse;
        for (final interceptor in _interceptors) {
          final ResponseInterceptorHandler handler =
              ResponseInterceptorHandler();
          await interceptor.onResponse(currentResponse, handler);

          if (handler.state == InterceptorState.next ||
              handler.state == InterceptorState.resolve) {
            currentResponse = handler.resultData as NetworkResponse<dynamic>;
          } else if (handler.state == InterceptorState.reject) {
            throw handler.resultData as NetworkException;
          }
        }

        // 7. Enrich response metadata & Cache successful response
        final Map<String, dynamic> extraMap =
            Map<String, dynamic>.from(currentResponse.extra);
        extraMap['retry_count'] = attempt - 1;
        extraMap['duration_ms'] = DateTime.now()
            .difference(
                DateTime.parse(currentRequest.extra['start_time'] as String))
            .inMilliseconds;
        final NetworkResponse<dynamic> finalResponse =
            currentResponse.copyWith<dynamic>(extra: extraMap);

        if (currentRequest.cachePolicy != null) {
          await _cacheManager.saveResponse(
            currentRequest,
            finalResponse,
            policy: currentRequest.cachePolicy,
            ttl: currentRequest.cacheTtl,
          );
        }

        return finalResponse;
      } catch (e, st) {
        NetworkException networkError;
        if (e is NetworkException) {
          networkError = e;
        } else {
          networkError = UnknownNetworkException(
            message: 'Unexpected network error: $e',
            request: currentRequest,
            underlyingError: e,
            stackTrace: st,
          );
        }

        // 8. Execute Error Interceptor Pipeline
        for (final interceptor in _interceptors) {
          final ErrorInterceptorHandler handler = ErrorInterceptorHandler();
          await interceptor.onError(networkError, handler);

          if (handler.state == InterceptorState.resolve) {
            final NetworkResponse<dynamic> resolvedResp =
                handler.resultData as NetworkResponse<dynamic>;
            return resolvedResp;
          } else if (handler.state == InterceptorState.next ||
              handler.state == InterceptorState.reject) {
            networkError = handler.resultData as NetworkException;
          }
        }

        // 9. Retry Manager Evaluation Loop
        if (retryManager.shouldRetry(currentRequest, networkError, attempt)) {
          final Duration delay = retryManager.calculateDelay(attempt);
          await Future<void>.delayed(delay);
          attempt++;
          continue;
        }

        throw networkError;
      }
    }
  }

  /// Helper for background stale-while-revalidate network refresh.
  Future<void> _executeNetworkAndCache<T>(
    NetworkRequest request,
    RetryPolicy retryPolicy,
    CancelToken? cancelToken,
  ) async {
    try {
      final res =
          await _executePipelineWithRetry<dynamic>(request, retryPolicy);
      await _cacheManager.saveResponse(request, res);
    } catch (_) {}
  }

  /// Safely casts or parses response data into expected type [T].
  NetworkResponse<T> _castResponse<T>(NetworkResponse<dynamic> response) {
    if (response.data == null) {
      return response.copyWith<T>(data: null);
    }

    final dynamic rawData = response.data;

    if (rawData is T) {
      return NetworkResponse<T>(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        data: rawData,
        request: response.request,
        extra: response.extra,
      );
    }

    if (T == String) {
      final String strData = rawData.toString();
      return NetworkResponse<T>(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        data: (strData as Object) as T,
        request: response.request,
        extra: response.extra,
      );
    }

    try {
      return NetworkResponse<T>(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        data: rawData as T,
        request: response.request,
        extra: response.extra,
      );
    } catch (e, st) {
      throw SerializationException(
        message:
            'Failed to cast response data from ${rawData.runtimeType} to $T',
        statusCode: response.statusCode,
        responseData: rawData,
        request: response.request,
        underlyingError: e,
        stackTrace: st,
      );
    }
  }

  /// Closes underlying transport connection resources and managers.
  void close() {
    _transport.close();
    _offlineQueueManager.dispose();
  }
}
