class Env {
  Env._();

  static const bool isProd = bool.fromEnvironment('dart.vm.product');

  static String get baseUrl {
    if (isProd) return 'https://api.learnova.app';
    return 'http://127.0.0.1:8000';
  }
}
