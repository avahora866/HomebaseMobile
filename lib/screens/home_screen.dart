import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/job_card.dart';
import '../widgets/slide_route.dart';
import 'budget_screen.dart';
import 'job_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _drawerOpen = false;
  String _query = '';
  JobCategory? _selectedCategory; // null = "All"

  void _openDetail(String jobId) {
    Navigator.of(context).push(slideRoute(JobDetailScreen(jobId: jobId)));
  }

  void _openBudget() {
    setState(() => _drawerOpen = false);
    Navigator.of(context).push(slideRoute(const BudgetScreen()));
  }

  void _openSettings() {
    setState(() => _drawerOpen = false);
    Navigator.of(context).push(slideRoute(const SettingsScreen()));
  }

  /// Flattens the filtered job list into a sequence of section headers
  /// (JobCategory) and jobs, grouped by category, preserving declaration
  /// order.
  List<Object> _sectionedItems(List<Job> jobs) {
    final q = _query.trim().toLowerCase();
    final filtered = jobs.where((j) {
      if (_selectedCategory != null && j.category != _selectedCategory) return false;
      if (q.isEmpty) return true;
      return j.name.toLowerCase().contains(q) || j.description.toLowerCase().contains(q);
    }).toList();

    final byCategory = <JobCategory, List<Job>>{};
    for (final job in filtered) {
      byCategory.putIfAbsent(job.category, () => []).add(job);
    }

    final items = <Object>[];
    for (final category in JobCategory.values) {
      final jobsInCategory = byCategory[category];
      if (jobsInCategory == null || jobsInCategory.isEmpty) continue;
      items.add(category);
      items.addAll(jobsInCategory);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  onMenu: () => setState(() => _drawerOpen = true),
                  onSettings: _openSettings,
                ),
                Expanded(
                  child: Consumer<JobProvider>(
                    builder: (context, jobProvider, _) {
                      final items = _sectionedItems(jobProvider.jobs);
                      return ListView(
                        key: const Key('jobListView'),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                        children: [
                          _SearchBar(
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 12),
                          _CategoryChips(
                            selected: _selectedCategory,
                            onSelect: (c) => setState(() => _selectedCategory = c),
                          ),
                          const SizedBox(height: 4),
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  'No jobs match your search.',
                                  style: AppTypography.body(14, color: AppColors.ink(0.55)),
                                ),
                              ),
                            )
                          else
                            for (final item in items)
                              if (item is JobCategory)
                                Padding(
                                  padding: const EdgeInsets.only(top: 22, bottom: 10),
                                  child: Text(
                                    item.label.toUpperCase(),
                                    style: AppTypography.heading(11, weight: FontWeight.w700, color: AppColors.accent)
                                        .copyWith(letterSpacing: 1),
                                  ),
                                )
                              else
                                JobCard(job: item as Job, onTap: () => _openDetail(item.id)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            AppDrawerOverlay(
              open: _drawerOpen,
              active: DrawerDestination.home,
              onClose: () => setState(() => _drawerOpen = false),
              onHome: () => setState(() => _drawerOpen = false),
              onBudget: _openBudget,
              onSettings: _openSettings,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onSettings;
  const _Header({required this.onMenu, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenu,
            child: const Icon(Icons.menu_rounded, size: 22, color: AppColors.text),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text('Homebase', style: AppTypography.heading(18))),
          GestureDetector(
            onTap: onSettings,
            child: const Icon(Icons.settings_outlined, size: 21, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────

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
                hintText: 'Search jobs…',
                hintStyle: AppTypography.body(13, color: AppColors.ink(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chips ───────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final JobCategory? selected;
  final ValueChanged<JobCategory?> onSelect;
  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(label: 'All', selected: selected == null, onTap: () => onSelect(null)),
          for (final c in JobCategory.values) ...[
            const SizedBox(width: 8),
            _Chip(label: c.label, selected: selected == c, onTap: () => onSelect(c)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

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
