import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import 'media_result_card.dart';

/// Displayed when /media/search returns successfully. Each entry in
/// [results] is a MediaSearchResult: {name, summary?, status?, notionUrl,
/// url?}. [mediaType] is the type the search was run with — used for the
/// TMDB link on movie/show/anime results.
class MediaSearchResults extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String? mediaType;
  const MediaSearchResults({super.key, required this.results, this.mediaType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(results.length == 1 ? '1 match' : '${results.length} matches',
            style: AppTypography.body(13, color: AppColors.ink(0.65))),
        const SizedBox(height: 10),
        for (final result in results) ...[
          _SearchResultCard(result: result, mediaType: mediaType),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? mediaType;
  const _SearchResultCard({required this.result, this.mediaType});

  @override
  Widget build(BuildContext context) {
    final name = result['name']?.toString() ?? '—';
    final summary = result['summary']?.toString() ?? '';
    final status = result['status']?.toString();
    final notionUrl = result['notionUrl']?.toString() ?? '';
    final url = result['url']?.toString();
    final tmdbUrl = name != '—' ? tmdbSearchUrl(mediaType, name) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null && status.isNotEmpty) ...[
            OutlineTag(status.toUpperCase()),
            const SizedBox(height: 10),
          ],
          Text(name, style: AppTypography.heading(16, weight: FontWeight.w600)),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(13, color: AppColors.ink(0.75))),
          ],
          if (notionUrl.isNotEmpty || (url?.isNotEmpty ?? false) || tmdbUrl != null) ...[
            const SizedBox(height: 10),
            const ThickDivider(),
            const SizedBox(height: 10),
          ],
          if (notionUrl.isNotEmpty) MediaLinkRow(label: 'Notion', url: notionUrl),
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(height: 8),
            MediaLinkRow(label: 'Link', url: url),
          ],
          if (tmdbUrl != null) ...[
            const SizedBox(height: 8),
            MediaLinkRow(label: 'TMDB', url: tmdbUrl),
          ],
        ],
      ),
    );
  }
}
