import '../storage/token_storage.dart';
import '../storage/user_storage.dart';

/// A read-only view of the current authentication/session state.
///
/// This is derived from storage and used by routing/guards.
class SessionSnapshot {
  const SessionSnapshot({
    required this.hasAccessToken,
    required this.isPersisted,
    required this.hasMe,
    required this.isOwner,
    required this.isInstructor,
    required this.pendingVerificationEmail,
  });

  final bool hasAccessToken;
  final bool isPersisted;
  final bool hasMe;
  final bool isOwner;
  final bool isInstructor;
  final String? pendingVerificationEmail;

  bool get isAuthed => hasAccessToken || isPersisted;

  static SessionSnapshot fromStorage() {
    return SessionSnapshot(
      hasAccessToken: TokenStorage.hasToken,
      isPersisted: TokenStorage.isPersisted,
      hasMe: UserStorage.hasMe,
      isOwner: UserStorage.isOwner,
      isInstructor: UserStorage.isInstructor,
      pendingVerificationEmail: TokenStorage.pendingVerificationEmail,
    );
  }
}
