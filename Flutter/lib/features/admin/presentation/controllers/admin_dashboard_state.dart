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

  AdminDashboardState copyWith({
    bool? loading,
    String? error,
    String? organizationId,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
