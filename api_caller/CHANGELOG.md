# Changelog

All notable changes to `flutter_api_caller` will be documented in this file.

## 0.3.0

### Changed
- Streamlined documentation in `README.md`.
- Removed legacy migration guide and testing section snippets.

## 0.2.0

### Added
- **Authentication & Single-Flight Token Refresh**: Added `TokenProvider`, `AuthConfig`, and `AuthManager` with concurrency locking preventing thundering-herd refresh requests on 401 Unauthorized.
- **Configurable Retry Policy**: Added `RetryPolicy`, `RetryStrategy` with fixed delay, exponential backoff, jitter, custom predicates, and POST protection.
- **Request Cancellation**: Added `CancelToken` and `CancellationException` for aborting active HTTP calls cleanly.
- **Connectivity Handling**: Added `ConnectivityService` abstraction, `ConnectivityManager`, and connectivity policies (`failFast`, `waitForConnection`, `useCache`, `queueRequest`).
- **Memory & Disk Caching**: Added `MemoryCache`, `FileCacheStorage`, and 8 cache policies including `staleWhileRevalidate`.
- **Request Deduplication**: Added `DeduplicationManager` coalescing simultaneous inflight GET requests into a single network roundtrip.
- **Offline Mutation Queue**: Added `OfflineQueueManager` for persisting POST/PUT/PATCH/DELETE requests across app restarts with auto-drain on reconnect.

### Security
- **Security-First Redaction Logging**: `NetworkLogger` automatically masks sensitive headers (`Authorization`, `Cookie`) and payload fields (`password`, `token`, `secret`).

## 0.1.0

- Initial release with core HTTP operations, layered transport abstraction, typed exceptions taxonomy, pipeline interceptors, and mock network transport.
