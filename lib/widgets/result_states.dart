import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown after /facts/resetInterestingFact (204 No Content) — matches the
/// prototype's reset-confirmation card exactly (accent-tinted, centered
/// check circle).
class ResetSuccessCard extends StatelessWidget {
  const ResetSuccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(color: AppColors.accent100, border: Border.all(color: AppColors.accent)),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
          ),
          const SizedBox(height: 12),
          Text('Facts reset', style: AppTypography.heading(15, weight: FontWeight.w600, color: AppColors.accent800)),
          const SizedBox(height: 4),
          Text(
            'Previously used facts can now be picked again.',
            style: AppTypography.body(12.5, color: AppColors.ink(0.65)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A 200 with no matching data (e.g. a media filter with zero hits) — kept
/// entirely in-system (no colour outside the neutral/accent ramps, since
/// the design has no semantic error/warning tokens).
class EmptyResultCard extends StatelessWidget {
  const EmptyResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 30, color: AppColors.ink(0.4)),
          const SizedBox(height: 12),
          Text('No results found', style: AppTypography.heading(15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'The server returned no matching entries for your selection.',
            style: AppTypography.body(13, color: AppColors.ink(0.55)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ErrorResultCard extends StatelessWidget {
  final String message;
  const ErrorResultCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.neutral900, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ERROR', style: AppTypography.heading(11, weight: FontWeight.w700).copyWith(letterSpacing: 1)),
          const SizedBox(height: 8),
          SelectableText(message, style: AppTypography.mono(13, color: AppColors.ink(0.8))),
        ],
      ),
    );
  }
}
