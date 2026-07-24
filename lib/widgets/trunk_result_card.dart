import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import 'markdown_style.dart';

/// Displayed when the random_trunk (Zettelkasten) job returns successfully.
/// Renders the trunk note's markdown content with title, category and
/// remaining count — the prototype's fake "#0142" id is swapped for the
/// real `remaining` count the API actually returns.
class TrunkResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const TrunkResultCard({super.key, required this.result});

  String _stripFrontmatter(String content) {
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('---')) return content;
    final end = trimmed.indexOf('---', 3);
    if (end == -1) return content;
    return trimmed.substring(end + 3).trimLeft();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = result['fileName']?.toString() ?? '—';
    final rawContent = result['content']?.toString() ?? '';
    final category = result['category']?.toString();
    final remaining = result['remaining'];
    final content = _stripFrontmatter(rawContent);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (category != null) OutlineTag(category.toUpperCase()),
              const Spacer(),
              if (remaining != null)
                Text('$remaining left', style: AppTypography.mono(11, color: AppColors.ink(0.5))),
            ],
          ),
          const SizedBox(height: 10),
          Text(fileName, style: AppTypography.heading(17, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          MarkdownBody(data: content, styleSheet: modernistMarkdownStyle()),
        ],
      ),
    );
  }
}
