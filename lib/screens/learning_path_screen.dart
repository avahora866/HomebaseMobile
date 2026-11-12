import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning.dart';
import '../providers/learning_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_dots.dart';
import '../widgets/learning_sheets.dart';
import '../widgets/result_states.dart';
import '../widgets/slide_route.dart';
import 'specialisation_screen.dart';

/// Learning Path home: one card per field with its capability tags and each
/// specialisation's rollup alongside coverage.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LearningProvider>().loadFields();
    });
  }

  void _openSpecialisation(SpecialisationSummary spec) {
    Navigator.of(context).push(slideRoute(SpecialisationScreen(specialisationId: spec.id)));
  }

  void _newSpecialisation(LearningField field) {
    final provider = context.read<LearningProvider>();
    showNameSheet(
      context,
      title: 'New Specialisation',
      hint: 'e.g. French',
      notes: [
        'Adds to ${field.name}. It gets its own topics, independent of Basic and every other specialisation.',
      ],
      onSave: (name) => provider.createSpecialisation(field.id, name),
    );
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
                  Expanded(child: Text('Learning Path', style: AppTypography.heading(17))),
                  GestureDetector(
                    onTap: () => showFieldFormSheet(context, provider: context.read<LearningProvider>()),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Text('+', style: AppTypography.heading(17, weight: FontWeight.w700, color: AppColors.bg)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<LearningProvider>(
                builder: (context, provider, _) {
                  if (provider.status == LearningStatus.idle ||
                      (provider.status == LearningStatus.loading && provider.fields.isEmpty)) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    );
                  }
                  if (provider.status == LearningStatus.error) {
                    return ListView(
                      padding: const EdgeInsets.all(18),
                      children: [ErrorResultCard(message: provider.errorMessage ?? 'Unknown error')],
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: provider.loadFields,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                      children: [
                        Text(
                          'Every field has a Basic specialisation, plus any named ones. Confidence is rated 1–5 on '
                          'leaf topics only — everything above is derived.',
                          style: AppTypography.body(12, color: AppColors.ink(0.55)).copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        if (provider.fields.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text('No fields yet — tap + to start a learning path.',
                                  style: AppTypography.body(14, color: AppColors.ink(0.55))),
                            ),
                          )
                        else
                          for (final field in provider.fields)
                            _FieldCard(
                              field: field,
                              onOpen: _openSpecialisation,
                              onNewSpecialisation: () => _newSpecialisation(field),
                              onEdit: () => showFieldFormSheet(context, provider: provider, field: field),
                            ),
                      ],
                    ),
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

class _FieldCard extends StatelessWidget {
  final LearningField field;
  final ValueChanged<SpecialisationSummary> onOpen;
  final VoidCallback onNewSpecialisation;
  final VoidCallback onEdit;

  const _FieldCard({
    required this.field,
    required this.onOpen,
    required this.onNewSpecialisation,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final count = field.specialisations.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(field.name, style: AppTypography.heading(16))),
              Text('$count specialisation${count == 1 ? '' : 's'}',
                  style: AppTypography.body(11, color: AppColors.ink(0.55))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [for (final label in field.capabilities.labels) _CapabilityTag(label)],
          ),
          const SizedBox(height: 12),
          for (final spec in field.specialisations) _SpecialisationRow(spec: spec, onTap: () => onOpen(spec)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              GestureDetector(
                onTap: onNewSpecialisation,
                child: Text('+ Specialisation',
                    style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.accent)),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text('Edit Field',
                    style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityTag extends StatelessWidget {
  final String label;
  const _CapabilityTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.tag)),
      child: Text(label, style: AppTypography.body(10.5, color: AppColors.neutral800)),
    );
  }
}

class _SpecialisationRow extends StatelessWidget {
  final SpecialisationSummary spec;
  final VoidCallback onTap;
  const _SpecialisationRow({required this.spec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.ink(0.12)),
        ),
        // Rating sits under the name rather than beside it, so a long name
        // and the coverage label never compete for a narrow phone's width.
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(spec.name,
                            style: AppTypography.heading(13, weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (spec.basic) ...[
                        const SizedBox(width: 6),
                        Text('BASIC',
                            style: AppTypography.heading(9, weight: FontWeight.w700, color: AppColors.ink(0.5))
                                .copyWith(letterSpacing: 0.8)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      ConfidenceDots(value: spec.rollupRating, size: 7),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          rollupLabel(spec.rollupRating, spec.ratedLeafCount, spec.leafCount),
                          style: AppTypography.body(10.5, color: AppColors.ink(0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink(0.4)),
          ],
        ),
      ),
    );
  }
}
