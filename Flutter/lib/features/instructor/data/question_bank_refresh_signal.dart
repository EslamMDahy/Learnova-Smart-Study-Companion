import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment this value after saved question mutations so any mounted
/// Question Bank tab refreshes its backend-backed table.
final questionBankRefreshSignalProvider = StateProvider.family<int, int>(
  (ref, courseId) => 0,
);
