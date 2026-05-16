import 'package:flutter/material.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:snap_saver/l10n/app_localizations.dart';

class SaverLongPressDialog extends StatelessWidget {
  final Saver saver;

  const SaverLongPressDialog({super.key, required this.saver});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            saver.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(
                context,
                icon: Icons.edit,
                label: l10n.editSaverButton,
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              _buildOptionButton(
                context,
                icon: Icons.folder_open,
                label: l10n.openAlbumDirectory,
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}