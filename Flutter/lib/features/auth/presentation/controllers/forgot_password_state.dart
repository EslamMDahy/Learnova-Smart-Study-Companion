class ForgotPasswordState {
  final bool loading;
  final String? error;

  const ForgotPasswordState({this.loading = false, this.error});

  ForgotPasswordState copyWith({bool? loading, String? error}) {
    return ForgotPasswordState(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
