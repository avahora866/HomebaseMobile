import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';
import '../widgets/project_card.dart';
import '../widgets/project_form_sheet.dart';
import '../widgets/result_states.dart';
import '../widgets/slide_route.dart';
import 'project_detail_screen.dart';

class ProjectTrackerScreen extends StatefulWidget {
  const ProjectTrackerScreen({super.key});

  @override
  State<ProjectTrackerScreen> createState() => _ProjectTrackerScreenState();
}

class _ProjectTrackerScreenState extends State<ProjectTrackerScreen> {
  String _query = '';
  int? _categoryFilter; // null = "All"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().load();
    });
  }

  void _openDetail(Project project) {
    Navigator.of(context).push(slideRoute(ProjectDetailScreen(projectId: project.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Project Tracker', style: AppTypography.heading(17))),
                  GestureDetector(
                    onTap: () => showProjectFormSheet(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Text('+',
                          style: AppTypography.heading(17, weight: FontWeight.w700, color: AppColors.bg)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  if (provider.status == ProjectTrackerStatus.loading ||
                      provider.status == ProjectTrackerStatus.idle) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    );
                  }
                  if (provider.status == ProjectTrackerStatus.error) {
                    return Padding(
                      padding: const EdgeInsets.all(18),
                      child: ErrorResultCard(message: provider.errorMessage ?? 'Unknown error'),
                    );
                  }

                  final q = _query.trim().toLowerCase();
                  final filtered = provider.projects.where((p) {
                    if (_categoryFilter != null && p.categoryId != _categoryFilter) return false;
                    if (q.isEmpty) return true;
                    return p.name.toLowerCase().contains(q) ||
                        (p.description?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  final byStatus = <ProjectStatus, List<Project>>{};
                  for (final p in filtered) {
                    byStatus.putIfAbsent(p.status, () => []).add(p);
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    children: [
                      _SearchBar(onChanged: (v) => setState(() => _query = v)),
                      if (provider.categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CategoryFilterBar(
                          categories: provider.categories,
                          selected: _categoryFilter,
                          onSelect: (id) => setState(() => _categoryFilter = id),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              provider.projects.isEmpty ? 'No projects yet.' : 'No projects match your filters.',
                              style: AppTypography.body(14, color: AppColors.ink(0.55)),
                            ),
                          ),
                        )
                      else
                        for (final status in ProjectStatus.values)
                          if (byStatus[status] != null) ...[
                            SectionKicker(status.label, margin: const EdgeInsets.only(bottom: 8, top: 6)),
                            for (final p in byStatus[status]!)
                              ProjectCard(project: p, onTap: () => _openDetail(p)),
                          ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<ProjectCategory> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;
  const _CategoryFilterBar({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: 'All', selected: selected == null, onTap: () => onSelect(null)),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            _FilterChip(label: c.name, selected: selected == c.id, onTap: () => onSelect(c.id)),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accent : AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTypography.heading(
            11,
            weight: FontWeight.w600,
            color: selected ? AppColors.bg : AppColors.text,
          ).copyWith(letterSpacing: 0.3),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: AppColors.ink(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTypography.body(13, color: AppColors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search projects…',
                hintStyle: AppTypography.body(13, color: AppColors.ink(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
