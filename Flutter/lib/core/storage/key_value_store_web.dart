import 'package:web/web.dart' as web;

import 'key_value_store.dart';

class _WebStorageStore implements KeyValueStore {
  _WebStorageStore(this._storage);

  final web.Storage _storage;

  @override
  bool containsKey(String key) => _storage.getItem(key) != null;

  @override
  String? getString(String key) => _storage.getItem(key);

  @override
  void remove(String key) => _storage.removeItem(key);

  @override
  void setString(String key, String value) => _storage.setItem(key, value);
}

KeyValueStore createSessionStoreImpl() =>
    _WebStorageStore(web.window.sessionStorage);

KeyValueStore createLocalStoreImpl() =>
    _WebStorageStore(web.window.localStorage);
