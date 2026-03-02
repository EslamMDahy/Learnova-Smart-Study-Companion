import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/toast.dart';
import '../controllers/course_details_controller.dart';
import '../controllers/course_details_state.dart';
import '../../data/materials_models.dart';
import '../../data/modules_models.dart';

/// Course-level multi-select "Generate Questions" UI.
/// Backend generation endpoints are not available in the current backend zip,
/// so the Generate action is disabled with a clear explanation.
///
/// If you later add a client method for generation (without changing backend here),
/// you can wire it in from the controller and optionally run sequential requests
/// per selected topic/material id with progress.
class GenerateQuestionsDialog extends ConsumerStatefulWidget {
  final int courseId;

  /// If provided, materials list is pre-filtered to this module.
  final int? initialModuleId;

  const GenerateQuestionsDialog({
    super.key,
    required this.courseId,
    this.initialModuleId,
  });

  @override
  ConsumerState<GenerateQuestionsDialog> createState() =>
      _GenerateQuestionsDialogState();
}

class _GenerateQuestionsDialogState extends ConsumerState<GenerateQuestionsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Selections
  final Set<int> _selectedMaterialIds = {};
  final Set<int> _selectedTopicIds = {}; // Topics API not available yet.

  // Filters/search
  String _materialsQuery = '';
  String _topicsQuery = '';
  String _materialTypeFilter = 'all'; // all | pdf | video | document | ...

  // Settings (UI-only until backend supports it)
  final Set<String> _types = {'MCQ'};
  String _difficulty = 'mixed'; // easy|medium|hard|mixed
  int _count = 10;

  final bool _submitting = false;
  final double _progress = 0.0;
  String? _progressLabel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseDetailsControllerProvider(widget.courseId));
    final modules = state.modules;
    final allMaterials = _flattenMaterials(state);

    final materials = widget.initialModuleId == null
        ? allMaterials
        : allMaterials.where((m) => m.moduleId == widget.initialModuleId).toList();

    final filteredMaterials = materials.where((m) {
      final q = _materialsQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          m.displayTitle.toLowerCase().contains(q) ||
          (m.fileName ?? '').toLowerCase().contains(q);
      final matchesType = _materialTypeFilter == 'all' ||
          m.type.toLowerCase() == _materialTypeFilter;
      return matchesQuery && matchesType;
    }).toList();

    const canGenerate = false; // No backend API in current zip.

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 760,
        height: 640,
        child: Column(
          children: [
            _Header(
              title: 'Generate Questions',
              subtitle: widget.initialModuleId == null
                  ? 'Select topics and/or materials across the whole course.'
                  : 'Select topics and/or materials for this module.',
              onClose: () => Navigator.of(context).pop(),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  const _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    title: 'Not available in current backend',
                    message:
                        'The current backend API bundle does not expose question generation endpoints. '
                        'This UI is ready; once the endpoint exists, we can run generation sequentially per selected item with progress—without changing the backend here.',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Topics'),
                        Tab(text: 'Materials'),
                        Tab(text: 'Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TopicsTab(
                    enabled: false,
                    query: _topicsQuery,
                    onQueryChanged: (v) => setState(() => _topicsQuery = v),
                    selectedCount: _selectedTopicIds.length,
                    onSelectAll: () => AppToast.info(
                      context,
                      title: 'Coming soon',
                      message: 'Topics selection requires topics API support.',
                    ),
                    onClear: () => setState(_selectedTopicIds.clear),
                  ),
                  _MaterialsTab(
                    modules: modules,
                    materials: filteredMaterials,
                    typeFilter: _materialTypeFilter,
                    query: _materialsQuery,
                    selectedIds: _selectedMaterialIds,
                    onQueryChanged: (v) => setState(() => _materialsQuery = v),
                    onTypeChanged: (t) => setState(() => _materialTypeFilter = t),
                    onToggle: (id, sel) => setState(() {
                      if (sel) {
                        _selectedMaterialIds.add(id);
                      } else {
                        _selectedMaterialIds.remove(id);
                      }
                    }),
                    onSelectAll: () => setState(() {
                      for (final m in filteredMaterials) {
                        _selectedMaterialIds.add(m.id);
                      }
                    }),
                    onClear: () => setState(_selectedMaterialIds.clear),
                    resolveModuleTitle: (mid) {
                      final m = modules.where((x) => x.id == mid).toList();
                      return m.isEmpty ? 'Module' : m.first.title;
                    },
                  ),
                  _SettingsTab(
                    types: _types,
                    difficulty: _difficulty,
                    count: _count,
                    onToggleType: (t) => setState(() {
                      if (_types.contains(t)) {
                        _types.remove(t);
                      } else {
                        _types.add(t);
                      }
                    }),
                    onDifficultyChanged: (d) => setState(() => _difficulty = d),
                    onCountChanged: (c) => setState(() => _count = c),
                  ),
                ],
              ),
            ),
            _Footer(
              submitting: _submitting,
              progress: _progress,
              progressLabel: _progressLabel,
              summary:
                  'Selected: ${_selectedTopicIds.length} topic(s), ${_selectedMaterialIds.length} material(s)',
              canSubmit: canGenerate,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: () async {
                // Currently disabled due to missing backend API.
                AppToast.info(
                  context,
                  title: 'Coming soon',
                  message:
                      'Question generation endpoints are not available in the current backend.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<MaterialItem> _flattenMaterials(CourseDetailsState state) {
    final out = <MaterialItem>[];
    for (final entry in state.materials.entries) {
      out.addAll(entry.value);
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTitle)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTitle)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsTab extends StatelessWidget {
  final bool enabled;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  const _TopicsTab({
    required this.enabled,
    required this.query,
    required this.onQueryChanged,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _SearchField(
            hint: 'Search topics…',
            value: query,
            onChanged: onQueryChanged,
            enabled: enabled,
          ),
          const SizedBox(height: 10),
          _SelectBar(
            selectedCount: selectedCount,
            onSelectAll: enabled ? onSelectAll : null,
            onClear: enabled ? onClear : null,
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: _EmptyPanel(
              icon: Icons.topic_outlined,
              title: 'Topics selection is coming soon',
              subtitle:
                  'The current backend bundle does not expose topics endpoints yet, so we can’t reliably load topics for selection.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final List<ModuleItem> modules;
  final List<MaterialItem> materials;
  final String typeFilter;
  final String query;
  final Set<int> selectedIds;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onTypeChanged;
  final void Function(int id, bool selected) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final String Function(int moduleId) resolveModuleTitle;

  const _MaterialsTab({
    required this.modules,
    required this.materials,
    required this.typeFilter,
    required this.query,
    required this.selectedIds,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClear,
    required this.resolveModuleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  hint: 'Search materials…',
                  value: query,
                  onChanged: onQueryChanged,
                ),
              ),
              const SizedBox(width: 10),
              _TypeFilter(
                value: typeFilter,
                onChanged: onTypeChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SelectBar(
            selectedCount: selectedIds.length,
            onSelectAll: materials.isEmpty ? null : onSelectAll,
            onClear: selectedIds.isEmpty ? null : onClear,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: materials.isEmpty
                ? const _EmptyPanel(
                    icon: Icons.folder_open_outlined,
                    title: 'No materials found',
                    subtitle:
                        'Upload course materials first, then select them here.',
                  )
                : ListView.separated(
                    itemCount: materials.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final m = materials[i];
                      final selected = selectedIds.contains(m.id);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) => onToggle(m.id, v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: Text(
                          m.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTitle),
                        ),
                        subtitle: Text(
                          '${resolveModuleTitle(m.moduleId)} • ${m.type.toUpperCase()} • ${_fmtSize(m.fileSize)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _fmtSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    final b = bytes.toDouble();
    if (b >= gb) return '${(b / gb).toStringAsFixed(2)} GB';
    if (b >= mb) return '${(b / mb).toStringAsFixed(2)} MB';
    if (b >= kb) return '${(b / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _TypeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
        DropdownMenuItem(value: 'video', child: Text('Video')),
        DropdownMenuItem(value: 'document', child: Text('Document')),
        DropdownMenuItem(value: 'presentation', child: Text('Slides')),
        DropdownMenuItem(value: 'link', child: Text('Link')),
      ],
      onChanged: (v) => onChanged(v ?? 'all'),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final Set<String> types;
  final String difficulty;
  final int count;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<String> onToggleType;

  const _SettingsTab({
    required this.types,
    required this.difficulty,
    required this.count,
    required this.onToggleType,
    required this.onDifficultyChanged,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ListView(
        children: [
          const Text('Question types',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipToggle(
                label: 'MCQ',
                selected: types.contains('MCQ'),
                onTap: () => onToggleType('MCQ'),
              ),
              _ChipToggle(
                label: 'True/False',
                selected: types.contains('TF'),
                onTap: () => onToggleType('TF'),
              ),
              _ChipToggle(
                label: 'Short Answer',
                selected: types.contains('SA'),
                onTap: () => onToggleType('SA'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Difficulty',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _ChipToggle(
                label: 'Mixed',
                selected: difficulty == 'mixed',
                onTap: () => onDifficultyChanged('mixed'),
              ),
              _ChipToggle(
                label: 'Easy',
                selected: difficulty == 'easy',
                onTap: () => onDifficultyChanged('easy'),
              ),
              _ChipToggle(
                label: 'Medium',
                selected: difficulty == 'medium',
                onTap: () => onDifficultyChanged('medium'),
              ),
              _ChipToggle(
                label: 'Hard',
                selected: difficulty == 'hard',
                onTap: () => onDifficultyChanged('hard'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Count',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: count <= 1 ? null : () => onCountChanged(count - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTitle)),
              IconButton(
                onPressed: () => onCountChanged(count + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'These settings will become active once the backend generation endpoint is available.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textTitle,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _SearchField({
    required this.hint,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      onChanged: onChanged,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _SelectBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;

  const _SelectBar({
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Selected: $selectedCount',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textTitle)),
        const Spacer(),
        TextButton(
          onPressed: onSelectAll,
          child: const Text('Select all'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onClear,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textMuted, height: 1.35)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool submitting;
  final double progress;
  final String? progressLabel;
  final String summary;
  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _Footer({
    required this.submitting,
    required this.progress,
    required this.progressLabel,
    required this.summary,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (submitting) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress == 0 ? null : progress,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(progressLabel ?? 'Generating…',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(summary,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ),
              TextButton(onPressed: submitting ? null : onCancel, child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: canSubmit ? onSubmit : null,
                child: const Text('Generate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
