import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The `.tag.tag-outline` component: an accent-outlined label used for HTTP
/// methods and category pills throughout the design.
class OutlineTag extends StatelessWidget {
  final String label;
  final double? minWidth;
  const OutlineTag(this.label, {super.key, this.minWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
      alignment: minWidth != null ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Text(
        label,
        textAlign: minWidth != null ? TextAlign.center : null,
        style: AppTypography.body(11, weight: FontWeight.w600, color: AppColors.accent),
      ),
    );
  }
}

/// A strong 2px rule between major sections — `.hr` / the divider that
/// separates every card's metadata rows.
class ThickDivider extends StatelessWidget {
  final double height;
  const ThickDivider({super.key, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: AppColors.divider);
  }
}

/// Uppercase, tracked-out section kicker in the accent colour — used for
/// category headers on the home screen and card group labels ("RESULT",
/// "ENVIRONMENT", "ABOUT").
class SectionKicker extends StatelessWidget {
  final String label;
  final EdgeInsets margin;
  const SectionKicker(this.label, {super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.heading(11, weight: FontWeight.w700, color: AppColors.accent)
            .copyWith(letterSpacing: 1.1),
      ),
    );
  }
}

/// A small solid status dot — accent when a job has run, divider-toned
/// otherwise, matching `job.dotColor` in the prototype.
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const StatusDot({super.key, required this.color, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
