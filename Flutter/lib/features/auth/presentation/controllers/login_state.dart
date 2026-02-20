class LoginState {
  final bool loading;
  final String? error;

  const LoginState({
    this.loading = false,
    this.error,
  });

  LoginState copyWith({
    bool? loading,
    String? error,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}
