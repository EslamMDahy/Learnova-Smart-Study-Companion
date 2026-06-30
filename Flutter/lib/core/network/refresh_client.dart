import 'refresh_client_stub.dart'
    if (dart.library.js_interop) 'refresh_client_web.dart'
    if (dart.library.html) 'refresh_client_web.dart';

abstract class RefreshClient {
  Future<String> refresh({required String url});
}

RefreshClient createRefreshClient() => createRefreshClientImpl();
