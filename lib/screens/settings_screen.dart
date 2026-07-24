import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/env_provider.dart';
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
                  const SectionKicker('Environment', margin: EdgeInsets.only(bottom: 10)),
                  Consumer<EnvProvider>(
                    builder: (context, env, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(env.label, style: AppTypography.heading(15, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(env.target, style: AppTypography.mono(12, color: AppColors.ink(0.6))),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: env.toggle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                alignment: env.isDev ? Alignment.centerLeft : Alignment.centerRight,
                                color: env.isDev ? AppColors.divider : AppColors.accent,
                                child: Container(width: 20, height: 20, color: AppColors.bg),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionKicker('About', margin: EdgeInsets.only(bottom: 10)),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'Homebase — a personal dev tool for triggering server endpoint jobs.',
                      style: AppTypography.body(13, color: AppColors.ink(0.75)),
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
