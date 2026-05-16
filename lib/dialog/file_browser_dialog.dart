import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snap_saver/l10n/app_localizations.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.openAlbumDirectory,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[100],
              child: Text(
                _currentPath,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
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
                                  Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Directory is empty',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                final name = file.path.split('/').last;
                                final isDir = file is Directory;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: isDir
                                            ? Center(
                                                child: Icon(
                                                  Icons.folder,
                                                  size: 48,
                                                  color: Colors.amber[700],
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(8),
                                                ),
                                                child: Image.file(
                                                  File(file.path),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: const BorderRadius.vertical(
                                            bottom: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 12),
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