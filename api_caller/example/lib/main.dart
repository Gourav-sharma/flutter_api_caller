import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_api_caller/flutter_api_caller.dart';

void main() {
  runApp(const MyApp());
}

class DemoTokenProvider implements TokenProvider {
  String? _accessToken = 'token_v1';
  int refreshCount = 0;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> refreshToken() async {
    refreshCount++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _accessToken = 'token_v${refreshCount + 1}';
    return _accessToken;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_api_caller Advanced Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ApiCallerDemoPage(),
    );
  }
}

class ApiCallerDemoPage extends StatefulWidget {
  const ApiCallerDemoPage({super.key});

  @override
  State<ApiCallerDemoPage> createState() => _ApiCallerDemoPageState();
}

class _ApiCallerDemoPageState extends State<ApiCallerDemoPage> {
  late final NetworkClient _client;
  late final DemoTokenProvider _tokenProvider;
  CancelToken? _activeCancelToken;

  String _status = 'Idle';
  String _responseContent =
      'Tap a feature button below to test advanced networking capabilities.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tokenProvider = DemoTokenProvider();

    _client = NetworkClient(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      headers: <String, String>{
        'Accept': 'application/json',
        'X-App-Client': 'FlutterEcosystemDemo',
      },
      auth: AuthConfig(tokenProvider: _tokenProvider),
      retryPolicy: const RetryPolicy(
        maxRetries: 2,
        strategy: RetryStrategy.exponentialBackoffJitter,
      ),
      cacheConfig: const CacheConfig(
        policy: CachePolicy.cacheFirst,
        ttl: Duration(minutes: 2),
      ),
      logger: NetworkLogger(level: LogLevel.debug),
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _fetchWithCache() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching GET /posts with CacheFirst...';
      _responseContent = '';
    });

    try {
      final response = await _client.get<List<dynamic>>(
        '/posts',
        queryParameters: <String, dynamic>{'_limit': 3},
        cachePolicy: CachePolicy.cacheFirst,
      );

      final bool isCacheHit = response.extra['is_cache_hit'] == true;

      setState(() {
        _status = 'Success (${response.statusCode}) | Cache Hit: $isCacheHit';
        _responseContent = 'Cache Hit: $isCacheHit\n'
            'Duration: ${response.extra['duration_ms']}ms\n'
            'Data (${response.data?.length} items):\n${response.data}';
      });
    } on NetworkException catch (e) {
      setState(() {
        _status = 'Error (${e.runtimeType})';
        _responseContent = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDeduplication() async {
    setState(() {
      _isLoading = true;
      _status = 'Executing 10 simultaneous GET requests (Deduplication)...';
      _responseContent = '';
    });

    try {
      final Stopwatch sw = Stopwatch()..start();
      final futures = List.generate(
        10,
        (_) => _client
            .get<List<dynamic>>('/comments', queryParameters: {'_limit': 2}),
      );

      final results = await Future.wait(futures);
      sw.stop();

      final bool deduplicated = results.first.extra['is_deduplicated'] == true;

      setState(() {
        _status =
            'Deduplication Success! Total Time: ${sw.elapsedMilliseconds}ms';
        _responseContent = 'Fired 10 identical GET requests simultaneously.\n'
            'Deduplicated Flag: $deduplicated\n'
            'Result: Executed 1 single network roundtrip for 10 callers!';
      });
    } on NetworkException catch (e) {
      setState(() {
        _status = 'Error (${e.runtimeType})';
        _responseContent = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCancellation() async {
    _activeCancelToken = CancelToken();
    setState(() {
      _isLoading = true;
      _status = 'Started long request... Cancelling in 300ms';
      _responseContent = '';
    });

    Timer(const Duration(milliseconds: 300), () {
      _activeCancelToken?.cancel('User tapped Cancel button');
    });

    try {
      await _client.get<dynamic>(
        '/photos',
        cancelToken: _activeCancelToken,
      );
    } on CancellationException catch (e) {
      setState(() {
        _status = 'Cancellation Caught!';
        _responseContent = 'Typed Exception: ${e.runtimeType}\n'
            'Reason: ${e.reason}\n'
            'Message: ${e.message}';
      });
    } on NetworkException catch (e) {
      setState(() {
        _status = 'Error (${e.runtimeType})';
        _responseContent = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOfflineQueue() async {
    setState(() {
      _isLoading = true;
      _status = 'Queuing POST /posts via Offline Queue...';
      _responseContent = '';
    });

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/posts',
        data: <String, dynamic>{
          'title': 'Offline Order',
          'body': 'Saved to persistent disk queue',
        },
        offlinePolicy: OfflinePolicy.queue,
      );

      setState(() {
        _status = 'Offline Queue Success (${response.statusCode})';
        _responseContent = 'Status: ${response.statusMessage}\n'
            'Is Queued Offline: ${response.extra['is_offline_queued']}\n'
            'Pending Queue Count: ${_client.offlineQueueManager.pendingCount}';
      });
    } on NetworkException catch (e) {
      setState(() {
        _status = 'Error (${e.runtimeType})';
        _responseContent = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_api_caller v0.2.0 Ecosystem'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.flash_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: $_status',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchWithCache,
                  icon: const Icon(Icons.storage),
                  label: const Text('GET + Cache'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testDeduplication,
                  icon: const Icon(Icons.merge_type),
                  label: const Text('10x Deduplicate'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _testCancellation,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Test Cancellation'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testOfflineQueue,
                  icon: const Icon(Icons.queue),
                  label: const Text('Test Offline Queue'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _responseContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
