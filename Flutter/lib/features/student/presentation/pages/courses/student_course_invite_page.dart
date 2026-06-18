import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/error_mapper.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/session/session_snapshot.dart';
import '../../../../../core/session/session_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_courses_models.dart';
import '../../../data/student_courses_providers.dart';

class StudentCourseInvitePage extends ConsumerStatefulWidget {
  final String? token;

  const StudentCourseInvitePage({super.key, required this.token});

  @override
  ConsumerState<StudentCourseInvitePage> createState() =>
      _StudentCourseInvitePageState();
}

enum _InviteAcceptStatus { idle, loading, success, error }

class _StudentCourseInvitePageState extends ConsumerState<StudentCourseInvitePage> {
  _InviteAcceptStatus _status = _InviteAcceptStatus.idle;
  StudentCourseInviteAcceptResult? _result;
  String? _error;
  bool _started = false;
  CancelToken? _cancelToken;

  String get _token => (widget.token ?? '').trim();

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _maybeAccept(SessionSnapshot session) {
    if (_started || _token.isEmpty) return;
    if (!session.isAuthed || !session.hasMe || session.isOwner || session.isInstructor) {
      return;
    }

    _started = true;
    _acceptInvitation();
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _status = _InviteAcceptStatus.loading;
      _error = null;
      _result = null;
    });

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final result = await ref.read(studentCoursesApiProvider).acceptCourseInvitation(
            token: _token,
            cancelToken: _cancelToken,
          );

      await ref
          .read(studentCoursesControllerProvider.notifier)
          .loadEnrolled(force: true);

      if (!mounted) return;
      setState(() {
        _status = _InviteAcceptStatus.success;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      final failure = mapApiFailure(e);
      setState(() {
        _status = _InviteAcceptStatus.error;
        _error = failure.message;
        // Keep _started true so rebuilds/router refreshes do not auto-submit
        // the same invitation again. The user can manually retry from the
        // button below.
      });
    }
  }

  void _goLogin() {
    final next = Uri.encodeQueryComponent(Routes.courseInviteFor(_token));
    context.go('${Routes.login}?next=$next');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionSnapshotProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAccept(session);
    });

    final content = _buildContent(session);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SessionSnapshot session) {
    if (_token.isEmpty) {
      return _InviteCard(
        icon: Icons.link_off_rounded,
        iconBackground: AppColors.dangerBg,
        iconColor: AppColors.dangerText,
        title: 'Invalid invitation link',
        message: 'This course invitation link is missing its token.',
        actions: [
          _SecondaryAction(
            label: 'Go to Dashboard',
            onPressed: () => context.go(Routes.studentDashboard),
          ),
        ],
      );
    }

    if (!session.isAuthed) {
      return _InviteCard(
        icon: Icons.lock_outline_rounded,
        iconBackground: AppColors.badgeBlueBg,
        iconColor: AppColors.primary,
        title: 'Login required',
        message: 'Please login with the invited student account to accept this course invitation.',
        actions: [
          _PrimaryAction(label: 'Login to Accept', onPressed: _goLogin),
        ],
      );
    }

    if (!session.hasMe) {
      return const _InviteCard.loading(
        title: 'Preparing your account',
        message: 'Please wait while we check your session before accepting the invitation.',
      );
    }

    if (session.isOwner || session.isInstructor) {
      return _InviteCard(
        icon: Icons.person_off_outlined,
        iconBackground: AppColors.dangerBg,
        iconColor: AppColors.dangerText,
        title: 'Student account required',
        message: 'Course invitations can only be accepted from the invited student account.',
        actions: [
          _SecondaryAction(
            label: 'Go to Home',
            onPressed: () => context.go(Routes.home),
          ),
        ],
      );
    }

    switch (_status) {
      case _InviteAcceptStatus.idle:
      case _InviteAcceptStatus.loading:
        return const _InviteCard.loading(
          title: 'Accepting invitation',
          message: 'We are enrolling you in the course now.',
        );
      case _InviteAcceptStatus.success:
        final message = (_result?.message.trim().isNotEmpty ?? false)
            ? _result!.message
            : 'Invitation accepted. You are now enrolled in the course.';
        return _InviteCard(
          icon: Icons.check_circle_outline_rounded,
          iconBackground: AppColors.successBg,
          iconColor: AppColors.successText,
          title: 'Invitation accepted',
          message: message,
          actions: [
            _PrimaryAction(
              label: 'Go to My Courses',
              onPressed: () => context.go(Routes.studentCourses),
            ),
            _SecondaryAction(
              label: 'Dashboard',
              onPressed: () => context.go(Routes.studentDashboard),
            ),
          ],
        );
      case _InviteAcceptStatus.error:
        return _InviteCard(
          icon: Icons.error_outline_rounded,
          iconBackground: AppColors.dangerBg,
          iconColor: AppColors.dangerText,
          title: 'Could not accept invitation',
          message: _error ?? 'Something went wrong while accepting this invitation.',
          actions: [
            _PrimaryAction(label: 'Try Again', onPressed: _acceptInvitation),
            _SecondaryAction(
              label: 'Dashboard',
              onPressed: () => context.go(Routes.studentDashboard),
            ),
          ],
        );
    }
  }
}

class _InviteCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconBackground;
  final Color? iconColor;
  final String title;
  final String message;
  final List<Widget> actions;
  final bool loading;

  const _InviteCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  }) : loading = false;

  const _InviteCard.loading({
    required this.title,
    required this.message,
  })  : icon = null,
        iconBackground = null,
        iconColor = null,
        actions = const [],
        loading = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoHeader(),
          const SizedBox(height: 28),
          if (loading)
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.school_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learnova',
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Course Invitation',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textGray,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
