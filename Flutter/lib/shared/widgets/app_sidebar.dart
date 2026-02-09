import 'package:flutter/material.dart';
import 'app_ui_components.dart' as ui; // ✅ عدّل المسار حسب مكان الملف عندك

/// ✅ Re-export model type (so old code still compiles)
typedef AppSidebarItem = ui.AppSidebarItem;

/// ✅ Thin wrapper around the shared component in app_ui_components.dart
class AppSidebar extends ui.AppSidebar {
  const AppSidebar({
    super.key,
    required super.selectedIndex,
    required super.onItemSelected,
    required super.portalSubtitle,
    required super.mainItems,
    required super.bottomItems,
    super.brandTitle = "Learnova",
    super.logoAssetPath = "assets/logo.png",
    super.onBrandTap,
  });
}
