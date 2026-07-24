import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: Text('Settings', style: AppTypography.heading(17))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                children: [
                  const SectionKicker('About', margin: EdgeInsets.only(bottom: 10)),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Homebase — a personal dev tool for triggering server endpoint jobs.',
                          style: AppTypography.body(13, color: AppColors.ink(0.75)),
                        ),
                        const SizedBox(height: 12),
                        const ThickDivider(),
                        const SizedBox(height: 12),
                        Text('Server', style: AppTypography.body(12, color: AppColors.ink(0.55))),
                        const SizedBox(height: 3),
                        Text(AppConfig.baseUrl, style: AppTypography.mono(12, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
