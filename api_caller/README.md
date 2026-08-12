# flutter_api_caller

An advanced, production-ready, highly extensible HTTP networking ecosystem for Dart and Flutter applications.

`flutter_api_caller` provides a layered architecture, single-flight token refresh, configurable retry policies, request cancellation, connectivity awareness, memory & disk caching, request deduplication, offline mutation queueing, pipeline interceptors, typed exceptions, and security-first logging.

---

## Table of Contents

- [Features Overview](#features-overview)
- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Feature Breakdown & Code Examples](#feature-breakdown--code-examples)
  - [1. Authentication & Single-Flight Token Refresh](#1-authentication--single-flight-token-refresh)
  - [2. Configurable Retry Policy](#2-configurable-retry-policy)
  - [3. Request Cancellation](#3-request-cancellation)
  - [4. Connectivity Handling & Policies](#4-connectivity-handling--policies)
  - [5. Memory & Disk Caching](#5-memory--disk-caching)
  - [6. Request Deduplication](#6-request-deduplication)
  - [7. Offline Mutation Queue](#7-offline-mutation-queue)
- [Core HTTP Operations & Multipart](#core-http-operations--multipart)
- [Typed Exceptions Hierarchy](#typed-exceptions-hierarchy)
- [Pipeline Interceptors](#pipeline-interceptors)
- [Security-First Logging](#security-first-logging)
- [Testing & Mocking](#testing--mocking)
- [Migration Guide from Version 0.1](#migration-guide-from-version-01)
- [License](#license)

---

## Features Overview

| Feature | Description |
| :--- | :--- |
| **Authentication** | Flexible `TokenProvider` abstraction with header customization. App manages storage. |
| **Single-Flight Token Refresh** | 100 concurrent HTTP 401s trigger **exactly ONE** token refresh request safely. |
| **Retry Engine** | Fixed delay, exponential backoff, jitter, custom predicates, and POST protection. |
| **Cancellation** | `CancelToken` for aborting active HTTP operations cleanly without breaking shared consumers. |
| **Connectivity** | Injectable `ConnectivityService` with `failFast`, `waitForConnection`, `useCache`, `queueRequest`. |
| **Memory & Disk Cache** | LRU eviction, TTL, non-fatal file storage, and 8 policies including `staleWhileRevalidate`. |
| **Request Deduplication** | Inflight GET request coalescing; 100 identical requests share 1 network roundtrip. |
| **Offline Mutation Queue** | Persistent queue for POST/PUT/PATCH/DELETE mutations with FIFO/priority and auto-drain. |

---

## Installation

Add `flutter_api_caller` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_api_caller: ^0.2.0
```

Then run:

```bash
dart pub get
```

---

## Architecture Overview

`NetworkClient` is composed of specialized, concurrency-safe managers rather than a single god-class:

```
NetworkClient
 ├── RequestPipeline
 ├── AuthManager (TokenProvider, Single-Flight Concurrent 401 Refresh)
 ├── RetryManager (RetryPolicy, Exponential Backoff + Jitter)
 ├── CacheManager (Memory Cache LRU, Disk Cache, Stale-While-Revalidate)
 ├── ConnectivityManager (ConnectivityService, Connectivity Policies)
 ├── DeduplicationManager (Inflight Request Coalescing)
 ├── OfflineQueueManager (Mutations Persistence, FIFO/Priority)
 └── NetworkTransport (HttpNetworkTransport, MockNetworkTransport)
```

---

## Feature Breakdown & Code Examples

### 1. Authentication & Single-Flight Token Refresh

Supply a custom `TokenProvider` to inject access tokens automatically and handle HTTP 401 token refresh concurrency-safely:

```dart
class AppTokenProvider implements TokenProvider {
  @override
  Future<String?> getAccessToken() async => 'active_access_token';

  @override
  Future<String?> refreshToken() async {
    // Perform authentication refresh request to identity server
    return 'new_access_token';
  }

  @override
  Future<void> clearTokens() async {
    // Clear tokens in app secure storage
  }
}

final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  auth: AuthConfig(
    tokenProvider: AppTokenProvider(),
    maxRefreshAttempts: 1, // Prevents infinite refresh loops
  ),
);
```

#### Critical Concurrency Safety
If 100 requests simultaneously receive HTTP 401, **exactly ONE** token refresh request executes while the other 99 callers wait for the same refresh result, preventing thundering herd refresh loops.

---

### 2. Configurable Retry Policy

Automatically retry transient network failures (connection errors, socket timeouts, HTTP 408, 429, 500, 502, 503, 504):

```dart
final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  retryPolicy: RetryPolicy(
    maxRetries: 3,
    strategy: RetryStrategy.exponentialBackoffJitter,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
    retryableMethods: ['GET', 'HEAD', 'PUT', 'DELETE'], // Protects POST/PATCH by default
  ),
);
```

---

### 3. Request Cancellation

Cancel ongoing requests using `CancelToken`:

```dart
final cancelToken = CancelToken();

// Dispatch request
final future = client.get('/large-file', cancelToken: cancelToken);

// Cancel operation when user navigates away
cancelToken.cancel('User navigated away');
```

---

### 4. Connectivity Handling & Policies

Decoupled from external plugin dependencies via `ConnectivityService`:

```dart
final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  options: NetworkOptions(
    connectivityPolicy: ConnectivityPolicy.waitForConnection,
  ),
);
```

Supported Policies:
- `ConnectivityPolicy.failFast`: Throw `ConnectionException` immediately when offline.
- `ConnectivityPolicy.waitForConnection`: Pause execution until device restores network connectivity.
- `ConnectivityPolicy.useCache`: Serve from local cache when offline.
- `ConnectivityPolicy.queueRequest`: Route mutating requests to offline mutation queue.

---

### 5. Memory & Disk Caching

Built-in memory LRU cache and persistent cross-platform file storage:

```dart
final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  cacheConfig: CacheConfig(
    policy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 5),
    maxMemoryEntries: 100,
    storage: FileCacheStorage(Directory('/path/to/cache')),
  ),
);

// Override policy per-request:
final response = await client.get(
  '/dashboard',
  cachePolicy: CachePolicy.staleWhileRevalidate,
);
```

Supported Cache Policies:
`networkOnly`, `cacheOnly`, `cacheFirst`, `networkFirst`, `staleWhileRevalidate`, `memoryOnly`, `diskOnly`, `memoryAndDisk`.

---

### 6. Request Deduplication

Simultaneous identical GET requests are automatically coalesced so only a single network roundtrip is executed:

```dart
// Executed simultaneously:
final f1 = client.get('/users');
final f2 = client.get('/users');
final f3 = client.get('/users');

final results = await Future.wait([f1, f2, f3]);
// Result: 1 actual network request executed, all 3 callers receive the exact same response!
```

---

### 7. Offline Mutation Queue

Queue mutating requests (POST, PUT, PATCH, DELETE) when offline and drain automatically upon reconnection:

```dart
final response = await client.post(
  '/orders',
  data: {'orderId': 1001},
  offlinePolicy: OfflinePolicy.queue,
);

print(response.statusCode); // 202 (Request queued offline)
print(client.offlineQueueManager.pendingCount); // 1
```

---

## Core HTTP Operations & Multipart

```dart
// GET
final users = await client.get<List<dynamic>>('/users');

// POST JSON
final newUser = await client.post<Map<String, dynamic>>('/users', data: {'name': 'Alice'});

// Multipart Upload
final upload = await client.post(
  '/upload',
  multipart: MultipartRequest(
    files: [MultipartFile.fromPath('/path/to/file.pdf', field: 'document')],
  ),
);
```

---

## Typed Exceptions Hierarchy

```
NetworkException
  ├── ConnectionException
  ├── NetworkTimeoutException
  ├── SerializationException
  ├── AuthenticationException
  ├── CancellationException
  ├── UnknownNetworkException
  └── HttpException
        ├── BadRequestException (400)
        ├── UnauthorizedException (401)
        ├── ForbiddenException (403)
        ├── NotFoundException (404)
        ├── ConflictException (409)
        ├── ValidationException (422)
        └── ServerException (5xx)
```

---

## Pipeline Interceptors

```dart
class AppHeaderInterceptor extends NetworkInterceptor {
  @override
  void onRequest(NetworkRequest request, RequestInterceptorHandler handler) {
    handler.next(request.copyWith(headers: {...request.headers, 'X-App-Id': '123'}));
  }
}
```

---

## Security-First Logging

`NetworkLogger` automatically redacts sensitive headers (`Authorization`, `Cookie`) and payload fields (`password`, `token`, `secret`, `access_token`).

---

## License

MIT License. See [LICENSE](LICENSE) for details.
