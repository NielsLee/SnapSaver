import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';
import 'package:vibration/vibration.dart';

class CameraControlBar extends StatelessWidget {
  final double sliderValue;
  final double minSlider;
  final double maxSlider;
  final ValueChanged<double>? onSliderChanged;
  final FlashMode flashMode;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraSwitch;
  final ValueChanged<int> onResolutionSelected;
  final int currentResolutionIndex;

  const CameraControlBar({
    super.key,
    required this.sliderValue,
    required this.minSlider,
    required this.maxSlider,
    this.onSliderChanged,
    required this.flashMode,
    required this.onFlashToggle,
    required this.onCameraSwitch,
    required this.onResolutionSelected,
    required this.currentResolutionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          color: AppColors.background.withValues(alpha: 0.6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Slider(
                  value: sliderValue,
                  min: minSlider,
                  max: maxSlider,
                  onChanged: minSlider != maxSlider ? onSliderChanged : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<int>(
                icon: const Icon(Icons.settings_overscan, color: AppColors.text),
                onSelected: (int newResolution) {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  onResolutionSelected(newResolution);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 0, child: Text(AppLocalizations.of(context)!.resolution_low)),
                  PopupMenuItem(value: 1, child: Text(AppLocalizations.of(context)!.resolution_medium)),
                  PopupMenuItem(value: 2, child: Text(AppLocalizations.of(context)!.resolution_high)),
                  PopupMenuItem(value: 3, child: Text(AppLocalizations.of(context)!.resolution_vh)),
                  PopupMenuItem(value: 4, child: Text(AppLocalizations.of(context)!.resolution_uh)),
                  PopupMenuItem(value: 5, child: Text(AppLocalizations.of(context)!.resolution_max)),
                ],
              ),
              IconButton(
                onPressed: onFlashToggle,
                icon: Icon(
                  flashMode == FlashMode.auto
                      ? Icons.flash_auto
                      : flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                onPressed: onCameraSwitch,
                icon: const Icon(Icons.cameraswitch, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
