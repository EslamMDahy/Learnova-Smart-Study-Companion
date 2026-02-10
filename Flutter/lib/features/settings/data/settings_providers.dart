import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_providers.dart'; // 👈 غالباً هنا عندكم apiClientProvider
import 'settings_api.dart';
import 'settings_repository.dart';

final settingsApiProvider = Provider<SettingsApi>(
  (ref) => SettingsApi(ref.read(apiClientProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.read(settingsApiProvider)),
);
