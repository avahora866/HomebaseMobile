import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// Displayed when /media/randomPicker returns successfully. [result] is a
/// MediaPickResult: {media: {name, summary, notionUrl, url?}, count: n}
/// where count is how many items still match the filter used to pick this
/// one. [category] is the media type the job was run with, shown in the tag
/// slot the prototype hardcodes to "FANFICTION" in its static example.
class MediaResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? category;
  const MediaResultCard({super.key, required this.result, this.category});

  @override
  Widget build(BuildContext context) {
    final media = result['media'] as Map<String, dynamic>? ?? {};
    final name = media['name']?.toString() ?? '—';
    final summary = media['summary']?.toString() ?? '';
    final notionUrl = media['notionUrl']?.toString() ?? '';
    final url = media['url']?.toString();
    final count = (result['count'] as num?)?.toInt();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover placeholder — the prototype's diagonal-stripe fill ──
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.neutral200,
              alignment: Alignment.center,
              child: CustomPaint(
                painter: _StripePainter(),
                child: Center(
                  child: Text('cover art',
                      style: AppTypography.mono(11, color: AppColors.ink(0.5))),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null) ...[
                  OutlineTag(category!.toUpperCase()),
                  const SizedBox(height: 10),
                ],
                Text(name, style: AppTypography.heading(18, weight: FontWeight.w600)),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(summary, style: AppTypography.body(13, color: AppColors.ink(0.75))),
                ],
                if (count != null) ...[
                  const SizedBox(height: 10),
                  Text(count == 1 ? '1 matching entry left' : '$count matching entries left',
                      style: AppTypography.body(13, color: AppColors.ink(0.65))),
                ],
                const SizedBox(height: 10),
                const ThickDivider(),
                const SizedBox(height: 10),
                if (notionUrl.isNotEmpty) _LinkRow(label: 'Notion', url: notionUrl),
                if (url != null && url.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _LinkRow(label: 'Link', url: url),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  const _LinkRow({required this.label, required this.url});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open link — copied to clipboard")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: AppTypography.body(12, color: AppColors.ink(0.6))),
          ),
          Expanded(
            child: Text(
              url,
              style: AppTypography.mono(12, color: AppColors.accent)
                  .copyWith(decoration: TextDecoration.underline),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal 45° hatch, matching the prototype's repeating-linear-gradient
/// placeholder for missing cover art.
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral100
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    const gap = 20.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
