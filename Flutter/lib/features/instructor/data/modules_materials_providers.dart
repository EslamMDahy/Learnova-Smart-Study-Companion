import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import 'modules_api.dart';
import 'materials_api.dart';
import 'topics_api.dart';

final modulesApiProvider = Provider<ModulesApi>((ref) {
  return ModulesApi(ref.read(apiClientProvider));
});

final materialsApiProvider = Provider<MaterialsApi>((ref) {
  return MaterialsApi(ref.read(apiClientProvider));
});

final topicsApiProvider = Provider<TopicsApi>((ref) {
  return TopicsApi(ref.read(apiClientProvider));
});
