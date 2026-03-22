import 'package:flutter/material.dart';
import '../theme/smithmk_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _pill('HA', SmithMkColors.error),
          const SizedBox(width: 8),
          _pill('SUPABASE', SmithMkColors.success),
          const SizedBox(width: 8),
          _pill('SOLAR', SmithMkColors.error),
        ],
      ),
    );
  }

  Widget _pill(String label, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SmithMkColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SmithMkColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: statusColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SmithMkColors.textSecondary, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
