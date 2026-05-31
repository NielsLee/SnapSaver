import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';

class FileBrowserDialog extends StatefulWidget {
  final String directoryPath;
  final VoidCallback onClose;

  const FileBrowserDialog({
    super.key,
    required this.directoryPath,
    required this.onClose,
  });

  @override
  State<FileBrowserDialog> createState() => _FileBrowserDialogState();
}

class _FileBrowserDialogState extends State<FileBrowserDialog> with WidgetsBindingObserver {
  List<PlatformFile> _files = [];
  bool _isLoading = true;
  String? _error;
  bool _wasSystemPreviewOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pickFiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes and there's no modal covering us, close the dialog
    if (state == AppLifecycleState.resumed) {
      // Check if system preview might have closed
      _checkAndCloseIfNeeded();
    }
  }

  void _checkAndCloseIfNeeded() {
    // If we were loading but now the app has resumed,
    // it likely means the system picker/preview closed
    if (mounted && _wasSystemPreviewOpen) {
      _wasSystemPreviewOpen = false;
    }
  }

  Future<void> _pickFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _wasSystemPreviewOpen = true;

      final result = await FilePicker.pickFiles(
        initialDirectory: widget.directoryPath,
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'],
        withReadStream: false,
      );

      _wasSystemPreviewOpen = false;

      if (result != null && result.files.isNotEmpty) {
        final filtered = result.files.where((f) {
          if (f.path == null) return false;
          final name = f.name.toLowerCase();
          return name.endsWith('.jpg') ||
              name.endsWith('.jpeg') ||
              name.endsWith('.png') ||
              name.endsWith('.gif') ||
              name.endsWith('.webp') ||
              name.endsWith('.heic');
        }).toList();

        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        setState(() {
          _files = filtered;
          _isLoading = false;
        });
      } else {
        setState(() {
          _files = [];
          _isLoading = false;
        });
        // If user cancelled and we have no files, close the dialog
        if (mounted) {
          widget.onClose();
        }
      }
    } catch (e) {
      _wasSystemPreviewOpen = false;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.openAlbumDirectory,
                      style: AppTypography.subheading(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.text),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              color: AppColors.surfaceVariant,
              child: Text(
                _getBasename(widget.directoryPath),
                style: AppTypography.caption().copyWith(color: AppColors.muted),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: AppSpacing.md),
                              Text(_error!, textAlign: TextAlign.center, style: AppTypography.body()),
                              const SizedBox(height: AppSpacing.md),
                              ElevatedButton(
                                onPressed: _pickFiles,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.folder_open, size: 48, color: AppColors.muted),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No images found in this directory',
                                    style: AppTypography.body().copyWith(color: AppColors.muted),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton(
                                    onPressed: _pickFiles,
                                    child: Text(l10n.selectPath),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                              ),
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                final name = file.name;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(AppRadius.sm),
                                          ),
                                          child: file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 48,
                                                        color: AppColors.muted,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 48,
                                                    color: AppColors.muted,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(AppRadius.sm),
                                          ),
                                        ),
                                        child: Text(
                                          name,
                                          style: AppTypography.caption(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

String _getBasename(String path) {
  return path.split('/').last;
}