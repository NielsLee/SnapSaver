import 'package:flutter/material.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';

class SaverLongPressDialog extends StatelessWidget {
  final Saver saver;

  const SaverLongPressDialog({super.key, required this.saver});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            saver.name,
            style: AppTypography.subheading(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(
                context,
                icon: Icons.edit,
                label: l10n.editSaverButton,
                color: AppColors.accent,
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              _buildOptionButton(
                context,
                icon: Icons.folder_open,
                label: l10n.openAlbumDirectory,
                color: AppColors.accent2,
                onTap: () => Navigator.of(context).pop('browse'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      splashColor: color.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.body().copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
