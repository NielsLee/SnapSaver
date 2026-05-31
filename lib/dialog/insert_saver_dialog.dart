import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/path_selector_entity.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';

import '../file/path_picker.dart';

class InsertSaverDialog extends StatefulWidget {
  final Saver? saver;

  const InsertSaverDialog({super.key, this.saver});

  @override
  State<StatefulWidget> createState() => InsertSaverDialogState();
}

class InsertSaverDialogState extends State<InsertSaverDialog> {
  static const List<Color> _saverColors = [
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
  ];

  static const List<String> _separatorOptions = ['None', '_', '-'];

  List<PathSelectorEntity> pathSelectors = [PathSelectorEntity()];
  TextEditingController nameController = TextEditingController();
  TextEditingController prefixController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool hasManuallyInputPath = false;
  Color? saverColor;
  int selectedColorIndex = -1;

  final _scrollController = ScrollController();

  bool _isNamingExpanded = false;
  int _suffixType = 0;
  int _separatorType = 0;

  bool _nameError = false;
  bool _pathError = false;

  @override
  void initState() {
    super.initState();
    if (widget.saver != null) {
      nameController.text = widget.saver!.name;
      hasManuallyInputPath = true;
      pathSelectors = widget.saver!.paths.map((p) {
        return PathSelectorEntity()..path = p..isPathSelected = true;
      }).toList();
      if (widget.saver!.color != null) {
        saverColor = Color(widget.saver!.color!);
        selectedColorIndex =
            _saverColors.indexWhere((c) => c.toARGB32() == widget.saver!.color);
      }
      if (widget.saver!.photoName != null) {
        prefixController.text = widget.saver!.photoName!;
      }
      if (widget.saver!.suffixType != 0) {
        _suffixType = widget.saver!.suffixType % 2;
        _separatorType = widget.saver!.suffixType ~/ 2;
      }
      if (widget.saver!.photoName != null || widget.saver!.suffixType != 0) {
        _isNamingExpanded = true;
      }
    }
  }

  int get _computedSuffixType => _suffixType + _separatorType * 2;

  void _scrollToExample() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String _generateExample() {
    final prefix = prefixController.text;
    final sep = _separatorType == 0 ? '' : _separatorType == 1 ? '_' : '-';
    if (_suffixType == 0) {
      return '$prefix${sep}1\n$prefix${sep}2';
    }
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final nowStr = DateFormat('yyyyMMddHHmmss').format(now);
    final yesterdayStr = DateFormat('yyyyMMddHHmmss').format(yesterday);
    return '$prefix$sep$nowStr\n$prefix$sep$yesterdayStr';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxDialogHeight =
        MediaQuery.of(context).size.height - bottomInset - AppSpacing.xl;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = DialogViewModel();
        if (widget.saver != null) {
          vm.setName(widget.saver!.name);
          for (var p in widget.saver!.paths) {
            vm.addPath(p);
          }
          if (widget.saver!.color != null) {
            vm.setColor(Color(widget.saver!.color!));
          }
          if (widget.saver!.photoName != null) {
            vm.setPhotoName(widget.saver!.photoName);
          }
          vm.setSuffixType(widget.saver!.suffixType);
        }
        return vm;
      },
      child: Consumer<DialogViewModel>(
        builder: (_, vm, __) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: bottomInset,
              ),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: maxDialogHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTitle(l10n),
                                  const SizedBox(
                                      height: AppSpacing.md),
                                  _buildColorPicker(),
                                  const SizedBox(
                                      height: AppSpacing.sm),
                                  _buildNameField(l10n),
                                  const SizedBox(
                                      height: AppSpacing.md),
                                  _buildPathSection(l10n, vm),
                                  const SizedBox(
                                      height: AppSpacing.md),
                                  _buildNamingSection(l10n),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildActionButtons(l10n, vm),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      widget.saver != null ? l10n.editSaver : l10n.createANewSaver,
      style: AppTypography.subheading(),
    );
  }

  Widget _buildColorPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _saverColors.asMap().entries.map((entry) {
          final idx = entry.key;
          final color = entry.value;
          final isSelected = selectedColorIndex == idx;
          return IconButton(
            isSelected: isSelected,
            selectedIcon: Icon(Icons.check, color: color, size: 20),
            onPressed: () => setState(() {
              selectedColorIndex = idx;
              saverColor = color;
            }),
            icon: Icon(Icons.folder, color: color, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(l10n.saverName),
            const SizedBox(width: AppSpacing.sm),
            if (_nameError)
              Text(
                l10n.pleaseEnterSaverName,
                style: AppTypography.caption().copyWith(color: Colors.red),
              ),
          ],
        ),
        TextField(
          controller: nameController,
          focusNode: _focusNode,
          onTap: () {
            hasManuallyInputPath = true;
            if (_nameError) setState(() => _nameError = false);
          },
          onChanged: (_) {
            if (_nameError) setState(() => _nameError = false);
          },
          decoration: InputDecoration(
            label: Text(l10n.saverNameDescription),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            enabledBorder: _nameError
                ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                : null,
            focusedBorder: _nameError
                ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPathSection(AppLocalizations l10n, DialogViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(l10n.saverPath),
            const SizedBox(width: AppSpacing.sm),
            if (_pathError)
              Text(
                l10n.pleaseSelectPath,
                style: AppTypography.caption().copyWith(color: Colors.red),
              ),
          ],
        ),
        ...pathSelectors.asMap().entries.map((entry) {
          return _buildPathRow(entry.key, entry.value, vm, l10n);
        }),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, DialogViewModel vm) {
    return Row(
      children: [
        if (widget.saver != null)
          TextButton(
            child: Text(l10n.delete,
                style: const TextStyle(color: Color(0xFFCF6679))),
            onPressed: () {
              Vibration.vibrate(amplitude: 255, duration: 5);
              Navigator.of(context).pop({'action': 'delete'});
            },
          ),
        const Spacer(),
        TextButton(
          child: Text(l10n.cancel),
          onPressed: () {
            Vibration.vibrate(amplitude: 255, duration: 5);
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(l10n.ok),
          style: TextButton.styleFrom(
            backgroundColor: saverColor?.withValues(alpha: 0.3),
          ),
          onPressed: () {
            Vibration.vibrate(amplitude: 255, duration: 5);
            final inputName = nameController.text.trim();
            bool hasPath = pathSelectors.any((s) => s.isPathSelected);

            setState(() {
              _nameError = inputName.isEmpty;
              _pathError = !hasPath;
            });

            if (inputName.isEmpty || !hasPath) return;

            vm.setName(inputName);
            if (selectedColorIndex >= 0) {
              vm.setColor(_saverColors[selectedColorIndex]);
            }
            if (prefixController.text.isNotEmpty) {
              vm.setPhotoName(prefixController.text);
            }
            vm.setSuffixType(_computedSuffixType);

            if (widget.saver != null) {
              Navigator.of(context)
                  .pop({'action': 'update', 'viewModel': vm});
            } else {
              Navigator.of(context).pop(vm);
            }
          },
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text,
          style: AppTypography.body().copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _buildPathRow(int index, PathSelectorEntity pathSelector,
      DialogViewModel vm, AppLocalizations l10n) {
    if (!pathSelector.isPathSelected) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: () {
            _focusNode.unfocus();
            createPathPicker().selectPath((path) {
              if (path != null) {
                if (!hasManuallyInputPath) {
                  nameController.text += p.basename(path) + " ";
                }
                setState(() {
                  pathSelector.path = path;
                  pathSelector.isPathSelected = true;
                  if (_pathError) _pathError = false;
                });
                vm.addPath(path);
              }
            });
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: _pathError ? Colors.red : AppColors.border,
                width: _pathError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.selectPath,
                    style: AppTypography.body().copyWith(color: AppColors.accent)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(pathSelector.path.toString(),
                    style: AppTypography.caption()),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                _focusNode.unfocus();
                createPathPicker().selectPath((path) {
                  if (path != null) {
                    setState(() => pathSelector.path = path);
                  }
                });
              },
              icon: const Icon(Icons.edit, size: 16, color: AppColors.muted),
            ),
            if (pathSelectors.length > 1)
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () =>
                    setState(() => pathSelectors.removeAt(index)),
                icon: const Icon(Icons.close, size: 16, color: Color(0xFFCF6679)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamingSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isNamingExpanded = !_isNamingExpanded),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(l10n.photoName,
                    style: AppTypography.body().copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    )),
                const Spacer(),
                AnimatedRotation(
                  turns: _isNamingExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      color: AppColors.muted, size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildNamingContent(l10n),
          crossFadeState: _isNamingExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildNamingContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: prefixController,
                onChanged: (_) {
                  setState(() {});
                  _scrollToExample();
                },
                decoration: InputDecoration(
                  label: Text(l10n.photoNameDescription),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.separator,
                    style: AppTypography.caption().copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.xs),
                DropdownButton<int>(
                  value: _separatorType,
                  dropdownColor: AppColors.surface,
                  iconEnabledColor: AppColors.accent,
                  underline: Container(height: 1, color: AppColors.border),
                  items: _separatorOptions.asMap().entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(_separatorOptions[e.key],
                          style: AppTypography.caption()),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _separatorType = v);
                  },
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.suffix,
                    style: AppTypography.caption().copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.xs),
                DropdownButton<int>(
                  value: _suffixType,
                  dropdownColor: AppColors.surface,
                  iconEnabledColor: AppColors.accent,
                  underline: Container(height: 1, color: AppColors.border),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(l10n.photoIndex, style: AppTypography.caption()),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(l10n.photoTimestamp, style: AppTypography.caption()),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _suffixType = v);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (prefixController.text.isNotEmpty) ...[
          Text(l10n.photoNameExample + ':',
              style: AppTypography.caption().copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(_generateExample(),
                style: AppTypography.caption().copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.text,
                )),
          ),
        ],
      ],
    );
  }
}
