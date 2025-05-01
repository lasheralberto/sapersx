import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class FirebaseStorageCacheManager extends CacheManager {
  static const key = 'firebaseStorageCache';

  static final FirebaseStorageCacheManager _instance =
      FirebaseStorageCacheManager._();
  factory FirebaseStorageCacheManager() => _instance;

  FirebaseStorageCacheManager._()
      : super(Config(
          key,
          maxNrOfCacheObjects: 100,
          stalePeriod: const Duration(days: 7),
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: _CustomHttpClient()),
        ));
}

class _CustomHttpClient extends http.BaseClient {
  final _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    });
    return _client.send(request);
  }
}
