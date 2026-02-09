class AdminDashboardState {
  final bool loading;
  final String? error;

  /// ✅ org id used in admin flows (from selected org / first org)
  final String? organizationId;

  const AdminDashboardState({
    this.loading = false,
    this.error,
    this.organizationId,
  });

  /// ✅ Derived (no duplication)
  bool get hasOrganization =>
      organizationId != null && organizationId!.trim().isNotEmpty;

  static const _unset = Object();

  AdminDashboardState copyWith({
    bool? loading,
    Object? error = _unset, // ✅ allows explicit null
    String? organizationId,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
