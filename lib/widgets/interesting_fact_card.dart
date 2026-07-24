import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import 'markdown_style.dart';

/// Displayed when /facts/interestingFact returns successfully. Reuses the
/// prototype's left-accent-border card chrome; the fact itself is markdown
/// from the server, so it's rendered through flutter_markdown rather than
/// forced into the mock's static headline + paragraph shape.
class InterestingFactCard extends StatelessWidget {
  final String markdown;
  const InterestingFactCard({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      padding: const EdgeInsets.all(20),
      child: MarkdownBody(
        data: markdown,
        styleSheet: modernistMarkdownStyle(),
      ),
    );
  }
}
