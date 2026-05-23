import 'package:flutter/material.dart';

import '../widgets/app_ui_components.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      color: AppColors.pageBg,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: AppSpacing.notificationsPage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppText.h1),
                SizedBox(height: 8),
                Text(
                  'System and course notifications will appear here when this area is enabled.',
                  style: AppText.subtitle,
                ),
                SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Color(0x33137FEC)),
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Notifications are locked',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.title,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'There is no active notifications feed connected in the frontend yet. Static demo notifications were removed to avoid showing fake activity.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
