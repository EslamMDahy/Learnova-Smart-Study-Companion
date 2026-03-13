import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/design_tokens.dart';
import 'global_loading_controller.dart';

class GlobalLoadingOverlay extends ConsumerWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(globalLoadingProvider);

    if (!visible) return const SizedBox.shrink();

    return Stack(
      children: [
        // blur + dim
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
        ),

        // center logo card
        Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowThin,
                  blurRadius: 22,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ لو عندك لوجو asset استعمله هنا
                Image.asset('assets/logo.png', height: 64),

                const SizedBox(height: 12),
                Text('Learnova', style: AppText.h3),
                const SizedBox(height: 6),
                Text('Loading…', style: AppText.muted),
                const SizedBox(height: 16),
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
