import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../presentation/controllers/reset_password_controller.dart';

class SetNewPasswordForm extends ConsumerStatefulWidget {
  final String? token;
  final bool isMobile;

  const SetNewPasswordForm({
    super.key,
    required this.token,
    this.isMobile = false,
  });

  @override
  ConsumerState<SetNewPasswordForm> createState() => _SetNewPasswordFormState();
}

class _SetNewPasswordFormState extends ConsumerState<SetNewPasswordForm> {
  final blue = const Color(0xFF137FEC);

  bool showNewPass = false;
  bool showConfirmPass = false;

  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _localError;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);

    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      setState(() =>
          _localError = "Invalid reset link. Please request a new one.");
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final newPass = _newPassCtrl.text.trim();

    final success = await ref
        .read(resetPasswordControllerProvider.notifier)
        .resetPassword(
          token: token,
          newPassword: newPass,
        );

    if (!mounted) return;

    if (success) {
      // ✅ Redirect مباشر للوجين + رسالة نجاح تظهر هناك
      context.go('${Routes.login}?reset=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 24 : 56),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ICON
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.security,
                          color: Color(0xFF137FEC), size: 26),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Set new password",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Please choose a strong password. It must be different from\npreviously used passwords.",
                    style: TextStyle(color: Color(0xFF617589), height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  if (_localError != null) ...[
                    _InfoCard(
                      type: _InfoType.error,
                      title: "Invalid link",
                      message: _localError!,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (state.error != null) ...[
                    _InfoCard(
                      type: _InfoType.error,
                      title: "Reset failed",
                      message: state.error!,
                    ),
                    const SizedBox(height: 18),
                  ],

                  const Text(
                    "New Password",
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 6),

                    // NEW PASSWORD
                    TextFormField(
                      controller: _newPassCtrl,
                      enabled: !state.loading,
                      obscureText: !showNewPass,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Password is required";
                        if (s.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Enter new password",
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),

                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.black45,
                          size: 20,
                        ),

                        suffixIcon: IconButton(
                          splashRadius: 18,
                          icon: Icon(
                            showNewPass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.black45,
                            size: 20,
                          ),
                          onPressed: state.loading
                              ? null
                              : () => setState(() => showNewPass = !showNewPass),
                        ),

                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.5,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CONFIRM PASSWORD
                    TextFormField(
                      controller: _confirmCtrl,
                      enabled: !state.loading,
                      obscureText: !showConfirmPass,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Confirm password is required";
                        if (s != _newPassCtrl.text) return "Passwords do not match";
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Confirm password",
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),

                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.black45,
                          size: 20,
                        ),

                        suffixIcon: IconButton(
                          splashRadius: 18,
                          icon: Icon(
                            showConfirmPass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.black45,
                            size: 20,
                          ),
                          onPressed: state.loading
                              ? null
                              : () =>
                                  setState(() => showConfirmPass = !showConfirmPass),
                        ),

                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.5,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),


                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: state.loading ? null : _submit,
                      child: state.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Reset Password",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: InkWell(
                      onTap: state.loading ? null : () => context.go(Routes.login),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back_ios_new,
                              size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            "Return to Log In",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _InfoType { success, error }

class _InfoCard extends StatelessWidget {
  final _InfoType type;
  final String title;
  final String message;

  const _InfoCard({
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == _InfoType.success;

    final bg = isSuccess ? const Color(0xFFEAF7EE) : const Color(0xFFFFF3F3);
    final border =
        isSuccess ? const Color(0xFFBEE6C7) : const Color(0xFFFFC7C7);
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final iconColor =
        isSuccess ? const Color(0xFF1E7A36) : const Color(0xFFB00020);
    final textColor =
        isSuccess ? const Color(0xFF1E7A36) : const Color(0xFFB00020);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
