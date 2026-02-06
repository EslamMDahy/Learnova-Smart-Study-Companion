import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../presentation/controllers/forgot_password_controller.dart';

class ForgetPasswordForm extends ConsumerStatefulWidget {
  final bool isMobile;
  const ForgetPasswordForm({super.key, this.isMobile = false});

  @override
  ConsumerState<ForgetPasswordForm> createState() => _ForgetPasswordFormState();
}

class _ForgetPasswordFormState extends ConsumerState<ForgetPasswordForm> {
  final blue = const Color(0xFF137FEC);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ ضمان إن الصفحة تبقى فاضية كل مرة تدخلها (حتى مع go_router reuse)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(forgotPasswordControllerProvider.notifier).reset();
      _emailCtrl.clear();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(_emailCtrl.text.trim());
  }

  void _goToLogin() {
    // ✅ نظّف قبل الخروج
    ref.read(forgotPasswordControllerProvider.notifier).reset();
    _emailCtrl.clear();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.refresh,
                          color: Color(0xFF137FEC), size: 26),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Forgot password?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "No worries, we'll send you reset instructions.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  if (state.sent && state.message != null) ...[
                    _InfoCard(
                      type: _InfoType.success,
                      title: "Check your inbox",
                      message: state.message!,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (state.error != null) ...[
                    _InfoCard(
                      type: _InfoType.error,
                      title: "Something went wrong",
                      message: state.error!,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ✅ قبل الإرسال: الفورم كامل
                  if (!state.sent) ...[
                    const Text('Email',
                        style: TextStyle(color: Colors.black, fontSize: 15)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !state.loading,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: Colors.black45,
                          size: 20,
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
                        onPressed: state.loading ? null : _onSend,
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
                                "Send Reset Link",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // ✅ بعد الإرسال: زر resend فقط (يعتمد على lastEmail)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: state.loading
                            ? null
                            : () => ref
                                .read(forgotPasswordControllerProvider.notifier)
                                .resend(),
                        child: state.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Resend email"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ لو lastEmail مش موجود لأي سبب (rare) رجّع الفورم
                    if ((state.lastEmail ?? '').trim().isEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: state.loading
                              ? null
                              : () {
                                  ref
                                      .read(
                                          forgotPasswordControllerProvider
                                              .notifier)
                                      .reset();
                                  _emailCtrl.clear();
                                },
                          child: const Text("Enter a different email"),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],

                  Center(
                    child: InkWell(
                      onTap: state.loading ? null : _goToLogin,
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
