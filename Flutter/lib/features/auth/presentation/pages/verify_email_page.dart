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
  bool _called = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_called) return;
    _called = true;

    final token = widget.token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (token == null || token.trim().isEmpty) {
        ref.read(verifyEmailControllerProvider.notifier).setError('Missing verification token.');
        return;
      }
      ref.read(verifyEmailControllerProvider.notifier).verify(token.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);

    Widget content;

    if (state.loading) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: 14),
          Text('Verifying your email...', style: TextStyle(color: Colors.black54)),
        ],
      );
    } else if (state.success) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 44, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          const Text(
            'Email verified successfully',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can now log in to your account.',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.go(Routes.login),
              child: const Text('Go to Login', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      );
    } else {
      final msg = state.error ?? 'Verification failed.';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Color(0xFFB00020)),
          const SizedBox(height: 12),
          const Text(
            'Verification failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.go(Routes.login),
              child: const Text('Go to Login', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Verification',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We are verifying your email address.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: content,
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
