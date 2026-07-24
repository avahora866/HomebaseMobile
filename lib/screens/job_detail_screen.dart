import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../widgets/atoms.dart';
import '../widgets/param_form.dart';
import '../widgets/interesting_fact_card.dart';
import '../widgets/media_result_card.dart';
import '../widgets/trunk_result_card.dart';
import '../widgets/result_states.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JobProvider>().initJobOptions(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobId = widget.jobId;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<JobProvider>(
          builder: (context, jobProvider, _) {
            final job = jobProvider.jobs.firstWhere((j) => j.id == jobId);

            return Column(
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
                      Expanded(child: Text(job.name, style: AppTypography.heading(17))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    children: [
                      _MetaCard(job: job),
                      if (job.hasParams) ...[
                        const SizedBox(height: 24),
                        ParamForm(jobId: jobId),
                      ],
                      const SizedBox(height: 24),
                      _RunButton(job: job, jobId: jobId),
                      if (job.status != JobStatus.idle) ...[
                        const SizedBox(height: 10),
                        _ResetButton(jobId: jobId),
                      ],
                      const SizedBox(height: 28),
                      if (job.status == JobStatus.success) ...[
                        Row(
                          children: [
                            const StatusDot(color: AppColors.accent),
                            const SizedBox(width: 9),
                            Text(
                              'RESULT',
                              style: AppTypography.heading(11, weight: FontWeight.w700, color: AppColors.accent)
                                  .copyWith(letterSpacing: 0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSuccessResult(job),
                      ],
                      if (job.status == JobStatus.error)
                        ErrorResultCard(message: job.errorMessage ?? 'Unknown error'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessResult(Job job) {
    if (job.id == 'reset_interesting_fact') return const ResetSuccessCard();

    if (job.result == null) return const EmptyResultCard();

    if (job.id == 'random_media' && job.result is Map) {
      final result = job.result as Map<String, dynamic>;
      if (result['media'] == null) return const EmptyResultCard();
      final mediaType = job.paramValues?['media'];
      return MediaResultCard(result: result, category: mediaType ?? job.category.label);
    }

    if (job.id == 'interesting_fact') {
      return InterestingFactCard(markdown: job.result as String);
    }

    if (job.id == 'random_trunk' && job.result is Map) {
      return TrunkResultCard(result: job.result as Map<String, dynamic>);
    }

    return _JsonResultCard(content: const JsonEncoder.withIndent('  ').convert(job.result));
  }
}

// ── Meta card ─────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final Job job;
  const _MetaCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.description, style: AppTypography.body(14, height: 1.4)),
          const SizedBox(height: 14),
          const ThickDivider(),
          const SizedBox(height: 14),
          _MetaRow(label: 'Method', valueWidget: OutlineTag(job.method)),
          const SizedBox(height: 8),
          _MetaRow(label: 'Endpoint', value: job.endpoint, mono: true),
          const SizedBox(height: 8),
          _MetaRow(label: 'Target', value: AppConfig.baseUrl, mono: true, accent: true),
          if (job.hasParams) ...[
            const SizedBox(height: 8),
            _MetaRow(
              label: 'Full URL',
              value: '${AppConfig.baseUrl}${job.resolvedEndpoint}',
              mono: true,
              accent: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool mono;
  final bool accent;
  final Widget? valueWidget;

  const _MetaRow({
    required this.label,
    this.value,
    this.mono = false,
    this.accent = false,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppTypography.body(12, color: AppColors.ink(0.55))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '',
                style: mono
                    ? AppTypography.mono(12, color: accent ? AppColors.accent : AppColors.ink(0.75))
                    : AppTypography.body(13),
              ),
        ),
      ],
    );
  }
}

// ── Run button ────────────────────────────────────────────────────────

class _RunButton extends StatelessWidget {
  final Job job;
  final String jobId;
  const _RunButton({required this.job, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final isLoading = job.status == JobStatus.loading;
    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final provider = context.read<JobProvider>();
              final error = await provider.runJob(jobId);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            },
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.accent.withValues(alpha: 0.5) : AppColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.bg.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 10),
                  Text('Running…', style: AppTypography.heading(15, weight: FontWeight.w600, color: AppColors.bg)),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.bg),
                  const SizedBox(width: 8),
                  Text('Run', style: AppTypography.heading(15, weight: FontWeight.w600, color: AppColors.bg)),
                ],
              ),
      ),
    );
  }
}

// ── Reset button ──────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  final String jobId;
  const _ResetButton({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<JobProvider>().resetJob(jobId),
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(16)),
        child: Text('Reset', style: AppTypography.heading(14, weight: FontWeight.w600, color: AppColors.ink(0.7))),
      ),
    );
  }
}

// ── Generic JSON viewer (fallback for jobs without a bespoke card) ────

class _JsonResultCard extends StatelessWidget {
  final String content;
  const _JsonResultCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        child: SelectableText(content, style: AppTypography.mono(13, color: AppColors.ink(0.8))),
      ),
    );
  }
}
