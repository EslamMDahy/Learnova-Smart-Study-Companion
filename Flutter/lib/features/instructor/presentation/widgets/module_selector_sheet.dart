// ─────────────────────────────────────────────────────────────────────────────
//  Module Selector — allows instructors to create new modules or reuse
//  existing ones from their module library (shareable modules).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/modules_models.dart';
import '../../data/mock_services.dart';

// Provider: global module library (all instructor modules)
final _allModulesProvider =
    FutureProvider<List<ModuleItem>>((ref) async {
  return ref.read(moduleSharingMockServiceProvider).listAllInstructorModules();
});

// ─────────────────────────────────────────────────────────────────────────────
//  ModuleSelectorSheet — bottom sheet to pick or create modules
// ─────────────────────────────────────────────────────────────────────────────

/// Result returned by [showModuleSelectorSheet]
class ModuleSelectorResult {
  final bool isNew;
  final ModuleItem? existing; // non-null when isNew == false
  final String? newTitle; // non-null when isNew == true
  final String? newDescription;

  const ModuleSelectorResult.existing(this.existing)
      : isNew = false,
        newTitle = null,
        newDescription = null;

  const ModuleSelectorResult.newModule(this.newTitle, this.newDescription)
      : isNew = true,
        existing = null;
}

Future<ModuleSelectorResult?> showModuleSelectorSheet(
    BuildContext context, int currentCourseId) {
  final size = MediaQuery.of(context).size;
  final width = size.width < 900 ? size.width * 0.96 : 860.0;
  final height = size.height * 0.82;
  return showDialog<ModuleSelectorResult>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: _ModuleSelectorSheet(currentCourseId: currentCourseId),
        ),
      ),
    ),
  );
}

class _ModuleSelectorSheet extends ConsumerStatefulWidget {
  final int currentCourseId;
  const _ModuleSelectorSheet({required this.currentCourseId});

  @override
  ConsumerState<_ModuleSelectorSheet> createState() =>
      _ModuleSelectorSheetState();
}

class _ModuleSelectorSheetState
    extends ConsumerState<_ModuleSelectorSheet> {
  bool _showCreate = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(_allModulesProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 32, offset: Offset(0, 18)),
        ],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            Expanded(
              child: Text(
                _showCreate ? 'Create New Module' : 'Select or Add Module',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        const Divider(),

        Expanded(
          child: _showCreate
              ? _buildCreateForm()
              : _buildExistingList(allAsync),
        ),
      ]),
    );
  }

  // ── Create form ──────────────────────────────────────────────────────────
  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back button
        GestureDetector(
          onTap: () => setState(() => _showCreate = false),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back_rounded,
                size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text('Back to module list',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 20),

        const _FieldLabel('Module Title', required: true),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
          decoration: InputDecoration(
            hintText: 'e.g. Week 1: Foundations',
            errorText: _titleError,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
            isDense: true,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                    color: Color(0xFF137FEC), width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),

        const _FieldLabel('Description'),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Brief description (optional)',
            contentPadding:
                const EdgeInsets.fromLTRB(12, 10, 12, 10),
            isDense: true,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitCreate,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                padding:
                    const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Create Module',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  void _submitCreate() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Module title is required.');
      return;
    }
    Navigator.pop(
      context,
      ModuleSelectorResult.newModule(
          title,
          _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim()),
    );
  }

  // ── Existing modules list ─────────────────────────────────────────────────
  Widget _buildExistingList(AsyncValue<List<ModuleItem>> allAsync) {
    return allAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Failed to load modules: $e')),
      data: (modules) {
        // Filter out modules already owned by this course
        final reusable = modules
            .where((m) => m.courseId != widget.currentCourseId)
            .toList();

        return Column(children: [
          // Add new button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: _CreateNewTile(
                onTap: () => setState(() => _showCreate = true)),
          ),

          if (reusable.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 6),
              child: Row(children: [
                const Text('Reuse Existing Module',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${reusable.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                ),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: reusable.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _ExistingModuleTile(
                  module: reusable[i],
                  onTap: () => Navigator.pop(
                    context,
                    ModuleSelectorResult.existing(reusable[i]),
                  ),
                ),
              ),
            ),
          ] else
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No other modules available to reuse.\nCreate a new module above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5),
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CreateNewTile extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateNewTile({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Create New Module',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8))),
                  Text('Start fresh with a brand-new module',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: Color(0xFF137FEC)),
            ]),
          ),
        ),
      );
}

class _ExistingModuleTile extends StatelessWidget {
  final ModuleItem module;
  final VoidCallback onTap;

  const _ExistingModuleTile(
      {required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: module.isPublished
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  size: 18,
                  color: module.isPublished
                      ? const Color(0xFF137FEC)
                      : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(module.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTitle)),
                  if (module.description != null) ...[
                    const SizedBox(height: 2),
                    Text(module.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted)),
                  ],
                ]),
              ),
              // Shared badge
              if (module.isShared)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Shared',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED))),
                ),
              const Icon(Icons.add_circle_outline,
                  size: 18, color: AppColors.textMuted),
            ]),
          ),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textTitle)),
        if (required)
          const Text(' *',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444))),
      ]);
}
