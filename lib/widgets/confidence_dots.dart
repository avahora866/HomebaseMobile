import 'package:flutter/material.dart';
import '../models/learning.dart';
import '../theme/app_theme.dart';

/// Five dots showing a 1–5 confidence rating: filled accent for each whole
/// step, a pale accent dot for a part step (derived ratings are averages),
/// neutral for the rest. With [onSet] the dots become tap targets that set
/// the rating — only ever offered on leaf topics.
class ConfidenceDots extends StatelessWidget {
  final double? value;
  final double size;
  final double gap;
  final ValueChanged<int>? onSet;

  const ConfidenceDots({super.key, required this.value, this.size = 8, this.gap = 3, this.onSet});

  static Color _color(DotFill fill) {
    switch (fill) {
      case DotFill.full:
        return AppColors.accent600;
      case DotFill.partial:
        return AppColors.accent300;
      case DotFill.empty:
        return AppColors.neutral300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fills = dotFills(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fills.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          if (onSet == null)
            _dot(fills[i])
          else
            // Pad the hit area out to a comfortable tap size without
            // changing how big the dot looks.
            GestureDetector(
              key: Key('confidence-dot-${i + 1}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSet!(i + 1),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _dot(fills[i])),
            ),
        ],
      ],
    );
  }

  Widget _dot(DotFill fill) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: _color(fill), shape: BoxShape.circle),
      );
}
