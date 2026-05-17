import 'dart:io';
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

class _FileBrowserDialogState extends State<FileBrowserDialog> {
  List<FileSystemEntity> _files = [];
  String _currentPath = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.directoryPath;
    _loadDirectory(widget.directoryPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        final filtered = entities.where((e) {
          final name = e.path.split('/').last;
          if (name.startsWith('.')) return false;
          if (e is Directory) return true;
          final ext = name.toLowerCase();
          return ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.png') ||
              ext.endsWith('.gif') ||
              ext.endsWith('.webp') ||
              ext.endsWith('.heic');
        }).toList();

        filtered.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        setState(() {
          _files = filtered;
          _currentPath = path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Directory does not exist';
          _isLoading = false;
        });
      }
    } catch (e) {
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
                _currentPath,
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
                                onPressed: () => _loadDirectory(_currentPath),
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
                                    'Directory is empty',
                                    style: AppTypography.body().copyWith(color: AppColors.muted),
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
                                final name = file.path.split('/').last;
                                final isDir = file is Directory;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: isDir
                                            ? Center(
                                                child: Icon(
                                                  Icons.folder,
                                                  size: 48,
                                                  color: AppColors.accent,
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(AppRadius.sm),
                                                ),
                                                child: Image.file(
                                                  File(file.path),
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
