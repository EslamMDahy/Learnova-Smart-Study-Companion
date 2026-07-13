import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'presentation_api.dart';

final presentationApiProvider = Provider<PresentationApi>((ref) {
  return PresentationApi(ref.read(apiClientProvider));
});
