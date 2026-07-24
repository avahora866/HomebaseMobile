import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';

/// Shared markdown styling for server-returned content (interesting facts,
/// trunk notes) — Archivo throughout, accent-toned code/quotes, rounded
/// corners, matching the modernist system.
MarkdownStyleSheet modernistMarkdownStyle({Color accent = AppColors.accent}) {
  return MarkdownStyleSheet(
    p: AppTypography.body(14, color: AppColors.ink(0.8), height: 1.55),
    h1: AppTypography.heading(20, weight: FontWeight.w600),
    h2: AppTypography.heading(18, weight: FontWeight.w600),
    h3: AppTypography.heading(16, weight: FontWeight.w600),
    strong: AppTypography.body(14, weight: FontWeight.w700, color: AppColors.text),
    em: AppTypography.body(14, color: AppColors.ink(0.8)).copyWith(fontStyle: FontStyle.italic),
    code: AppTypography.mono(13, color: AppColors.accent800),
    codeblockDecoration: BoxDecoration(
      color: AppColors.accent100,
      borderRadius: BorderRadius.circular(AppRadius.tag),
      border: Border.all(color: accent.withValues(alpha: 0.3)),
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: accent, width: 3)),
    ),
    blockquote: AppTypography.body(14, color: AppColors.ink(0.6)).copyWith(fontStyle: FontStyle.italic),
    listBullet: AppTypography.body(14, color: AppColors.ink(0.8)),
    tableHead: AppTypography.body(13, weight: FontWeight.w700),
    tableBody: AppTypography.body(13, color: AppColors.ink(0.75)),
    tableBorder: TableBorder.all(color: AppColors.divider, width: 1),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
