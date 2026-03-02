import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class UserStorage {
  static const _key = 'learnova_me';
  static Map<String, dynamic>? _cache;

  static final ValueNotifier<int> _rev = ValueNotifier<int>(0);
  static Listenable get listenable => _rev;

  static Map<String, dynamic>? get meJson {
    if (_cache != null) return _cache;

    final raw =
        html.window.sessionStorage[_key] ?? html.window.localStorage[_key];
    if (raw == null || raw.isEmpty) return null;

    try {
      _cache = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return _cache;
    } catch (_) {
      return null;
    }
  }

  static bool get hasMe => meJson != null;

  /// Backend-aligned: we store { user: {...}, organizations: [...] }
  static Map<String, dynamic>? get userMap {
    final m = meJson;
    if (m == null) return null;

    final u = m['user'];
    if (u is Map) return u.cast<String, dynamic>();

    return null; // don't guess shape
  }

  // ---------------- Basic getters ----------------

  static String get role =>
      (userMap?['system_role'] ?? '').toString().toLowerCase();

  static bool get isOwner => role == 'owner';
  static bool get isInstructor => role == 'instructor';

  static String? get userId => userMap?['id']?.toString();
  static String? get email => userMap?['email']?.toString();
  static String? get fullName => userMap?['full_name']?.toString();

  static String? get avatarUrl => userMap?['avatar_url']?.toString();
  static String? get phoneNumber => userMap?['phone_number']?.toString();
  static String? get bio => userMap?['bio']?.toString();

  static String? get studentId => userMap?['student_id']?.toString();
  static String? get universityEmail => userMap?['university_email']?.toString();

  static String? get languagePreference =>
      userMap?['language_preference']?.toString();

  static String? get createdAt => userMap?['created_at']?.toString();
  static String? get lastLoginAt => userMap?['last_login_at']?.toString();

  static String? get subscriptionPlanName =>
      userMap?['subscription_plan_name']?.toString();

  // ---------------- Organizations ----------------

  /// Backend-aligned organizations list (from login for owner)
  static List<Map<String, dynamic>> get organizations {
    final root = meJson;
    if (root == null) return const [];

    final raw = root['organizations'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    if (raw is Map) {
      return [raw.cast<String, dynamic>()];
    }

    return const [];
  }

  /// Front-only: selected organization id (optional convenience)
  static String? get selectedOrganizationId {
    final root = meJson;
    if (root == null) return null;

    final v = root['selected_organization_id']?.toString();
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  /// Effective org id for admin flows:
  /// 1) selected_organization_id (front-only)
  /// 2) first org in organizations list (backend)
  static String? get organizationId {
    final selected = selectedOrganizationId;
    if (selected != null && selected.isNotEmpty) return selected;

    final orgs = organizations;
    if (orgs.isNotEmpty) {
      final id = orgs.first['id']?.toString();
      if (id != null && id.trim().isNotEmpty) return id.trim();
    }

    return null;
  }

  static bool get hasOrganization =>
      organizationId != null && organizationId!.trim().isNotEmpty;

  /// Set selected org id (front-only)
  static void setSelectedOrganizationId(String? orgId, {required bool persist}) {
    final current = meJson ?? <String, dynamic>{};
    final merged = <String, dynamic>{...current};

    if (orgId == null || orgId.trim().isEmpty) {
      merged.remove('selected_organization_id');
    } else {
      merged['selected_organization_id'] = orgId.trim();
    }

    saveMe(merged, persist: persist);
  }

  static void saveMe(Map<String, dynamic> json, {required bool persist}) {
    _cache = json;
    final raw = jsonEncode(json);

    if (persist) {
      html.window.sessionStorage.remove(_key);
      html.window.localStorage[_key] = raw;
    } else {
      html.window.localStorage.remove(_key);
      html.window.sessionStorage[_key] = raw;
    }

    _rev.value++;

    if (kDebugMode) {
      // ignore: avoid_print
      print('ME JSON: ${UserStorage.meJson}');
      // ignore: avoid_print
      print('ROLE: ${UserStorage.role} | isOwner=${UserStorage.isOwner}');
      // ignore: avoid_print
      print(
        'ORG_ID: ${UserStorage.organizationId} | hasOrg=${UserStorage.hasOrganization}',
      );
      // ignore: avoid_print
      print('ORGS_COUNT: ${UserStorage.organizations.length}');
    }
  }

  static void clear() {
    _cache = null;
    html.window.localStorage.remove(_key);
    html.window.sessionStorage.remove(_key);
    _rev.value++;
  }
}
