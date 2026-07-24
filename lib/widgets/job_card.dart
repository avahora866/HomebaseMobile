import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// The home-screen job row: `.card` with `flex-direction:row`, a status
/// dot, name/description/method/endpoint, and a trailing chevron — 16px
/// radius, exactly as the prototype overrides it (despite the system's
/// otherwise-square default).
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const JobCard({super.key, required this.job, required this.onTap});

  Color get _dotColor {
    switch (job.status) {
      case JobStatus.loading:
        return AppColors.accent;
      case JobStatus.error:
        return AppColors.neutral900;
      case JobStatus.success:
        return AppColors.accent;
      case JobStatus.idle:
        return job.hasRun ? AppColors.accent : AppColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            job.status == JobStatus.loading
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                  )
                : StatusDot(color: _dotColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.name, style: AppTypography.heading(15, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    job.description,
                    style: AppTypography.body(12.5, color: AppColors.ink(0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OutlineTag(job.method, minWidth: 46),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          job.endpoint,
                          style: AppTypography.mono(10.5, color: AppColors.ink(0.55)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink(0.4)),
          ],
        ),
      ),
    );
  }
}
