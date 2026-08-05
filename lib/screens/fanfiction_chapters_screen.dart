import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';

/// One chapter entry as returned by the backend inside a fanfiction
/// `media.chapters` list — each item may be a plain string (just a title)
/// or a map with optional `number`, `title` and `url` fields.
class _Chapter {
  final int number;
  final String title;
  final String? url;
  const _Chapter({required this.number, required this.title, this.url});

  factory _Chapter.fromEntry(dynamic entry, int index) {
    if (entry is Map) {
      final number = (entry['number'] as num?)?.toInt() ?? index + 1;
      final title = entry['title']?.toString();
      final url = entry['url']?.toString();
      return _Chapter(
        number: number,
        title: (title == null || title.isEmpty) ? 'Chapter $number' : title,
        url: (url == null || url.isEmpty) ? null : url,
      );
    }
    return _Chapter(number: index + 1, title: entry?.toString() ?? 'Chapter ${index + 1}');
  }
}

/// Lists the chapters of a fanfiction pulled from `/media/randomPicker`'s
/// `media.chapters` field. Tapping a chapter with a `url` opens it
/// externally; chapters without one are shown as plain, non-interactive rows.
class FanfictionChaptersScreen extends StatelessWidget {
  final String storyName;
  final List<dynamic> chapters;
  const FanfictionChaptersScreen({super.key, required this.storyName, required this.chapters});

  @override
  Widget build(BuildContext context) {
    final parsed = [
      for (var i = 0; i < chapters.length; i++) _Chapter.fromEntry(chapters[i], i),
    ];

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storyName,
                            style: AppTypography.heading(17), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          parsed.length == 1 ? '1 chapter' : '${parsed.length} chapters',
                          style: AppTypography.body(12, color: AppColors.ink(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: parsed.isEmpty
                  ? Center(
                      child: Text('No chapters available.', style: AppTypography.body(14, color: AppColors.ink(0.55))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                      itemCount: parsed.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ChapterRow(chapter: parsed[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final _Chapter chapter;
  const _ChapterRow({required this.chapter});

  Future<void> _open(BuildContext context) async {
    final url = chapter.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open link — copied to clipboard")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = chapter.url != null;
    return GestureDetector(
      onTap: hasLink ? () => _open(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            OutlineTag('${chapter.number}', minWidth: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chapter.title,
                style: AppTypography.body(14, color: hasLink ? AppColors.text : AppColors.ink(0.75)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasLink) ...[
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.ink(0.5)),
            ],
          ],
        ),
      ),
    );
  }
}
