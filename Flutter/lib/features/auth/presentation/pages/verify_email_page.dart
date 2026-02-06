import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../controllers/verify_email_controller.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String? token;
  const VerifyEmailPage({super.key, required this.token});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final blue = const Color(0xFF137FEC);

  Timer? _goLoginTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = widget.token?.trim() ?? '';

      if (token.isEmpty) {
        ref
            .read(verifyEmailControllerProvider.notifier)
            .setError('Invalid verification link (missing token).');
        return;
      }

      await ref.read(verifyEmailControllerProvider.notifier).verify(token);

      if (!mounted) return;

      final state = ref.read(verifyEmailControllerProvider);
      if (state.success) {
        // ✅ كريتيف: استنى ثانية وبعدين وديه لوجين مع باراميتر نجاح
        _goLoginTimer?.cancel();
        _goLoginTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          context.go('${Routes.login}?verified=1');
        });
      }
    });
  }

  @override
  void dispose() {
    _goLoginTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);

    final title = state.loading
        ? 'Verifying your email...'
        : state.success
            ? 'Email verified!'
            : 'Verification failed';

    final subtitle = state.loading
        ? 'Please wait a moment.'
        : state.success
            ? 'Redirecting you to login...'
            : (state.error ?? 'This link may be expired or invalid.');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Email Verification',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We’re confirming your email address.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 22),

                  // Creative Card
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        color: const Color(0xFFF9FAFB),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusIcon(
                            loading: state.loading,
                            success: state.success,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          // ✅ زرار Login يظهر بس لو error (لأن success بيحوّل لوحده)
                          if (!state.loading && !state.success) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => context.go(Routes.login),
                                child: const Text(
                                  'Go to Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ✅ رجوع بسيط تحت (دايمًا موجود)
                  Center(
                    child: InkWell(
                      onTap: () => context.go(Routes.login),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new,
                              size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            "Back to Login",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool loading;
  final bool success;
  const _StatusIcon({required this.loading, required this.success});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 42,
        height: 42,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }
    if (success) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBEE6C7)),
        ),
        child: const Icon(Icons.check_circle,
            size: 34, color: Color(0xFF16A34A)),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC7C7)),
      ),
      child: const Icon(Icons.error_outline,
          size: 34, color: Color(0xFFB00020)),
    );
  }
}
