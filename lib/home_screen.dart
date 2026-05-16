import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/insert_saver_dialog.dart';
import 'package:snap_saver/dialog/saver_long_press_dialog.dart';
import 'package:snap_saver/dialog/file_browser_dialog.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

import 'entity/saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  int selectedLensIndex = 0;
  CameraController? _controller;
  double _minZoomLevel = 1 / 2;
  double _maxZoomLevel = 3;
  Future<void>? _initializeControllerFuture;
  bool isCapturing = false;
  Offset? focusOffset = null;
  double _sliderValue = 1;
  ResolutionPreset currentResolution = ResolutionPreset.max;
  int currentResolutionIndex = 0;
  var currentLensDirection = CameraLensDirection.back;
  FlashMode currentFlashMode = FlashMode.auto;
  bool _isInitializingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initCameraFromViewModel(int lensDirection, int resolution) {
    if (_isInitializingCamera || !mounted) return;
    setState(() {
      currentResolutionIndex = resolution;
    });
    // lensDirection: 0 = back, 1 = front
    final direction = lensDirection == 0 ? CameraLensDirection.back : CameraLensDirection.front;
    _initCameraByDirection(direction, _getResolutionPreset(resolution));
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  ResolutionPreset _getResolutionPreset(int index) {
    switch (index) {
      case 0:
        return ResolutionPreset.low;
      case 1:
        return ResolutionPreset.medium;
      case 2:
        return ResolutionPreset.high;
      case 3:
        return ResolutionPreset.veryHigh;
      case 4:
        return ResolutionPreset.ultraHigh;
      case 5:
        return ResolutionPreset.max;
      default:
        return ResolutionPreset.max;
    }
  }

  Future<void> _initCameraByDirection(CameraLensDirection direction, ResolutionPreset resolution) async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;

    try {
      WidgetsFlutterBinding.ensureInitialized();

      cameras = await availableCameras();
      await Permission.camera.request();

      // Find camera index by direction
      int actualIndex = 0;
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == direction) {
          actualIndex = i;
          break;
        }
      }

      selectedLensIndex = actualIndex;
      currentLensDirection = direction;

      if (mounted) {
        setState(() {
          _initializeControllerFuture = null;
        });
      }

      final newController = CameraController(
        cameras[actualIndex],
        resolution,
        enableAudio: false,
      );

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _initializeControllerFuture = _controller!.initialize();
      });

      await _initializeControllerFuture;
      await _resetZoomLevel();
      try {
        await _controller!.setFlashMode(currentFlashMode);
      } catch (e) {
        log('Could not set flash mode: $e');
      }
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _initCamera(int lensIndex, ResolutionPreset resolution) async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;

    try {
      WidgetsFlutterBinding.ensureInitialized();

      cameras = await availableCameras();
      await Permission.camera.request();

      final actualLensIndex = lensIndex < cameras.length ? lensIndex : 0;

      selectedLensIndex = actualLensIndex;
      currentLensDirection = cameras[actualLensIndex].lensDirection;

      if (mounted) {
        setState(() {
          _initializeControllerFuture = null;
        });
      }

      final newController = CameraController(
        cameras[actualLensIndex],
        resolution,
        enableAudio: false,
      );

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _initializeControllerFuture = _controller!.initialize();
      });

      await _initializeControllerFuture;
      await _resetZoomLevel();
      try {
        await _controller!.setFlashMode(currentFlashMode);
      } catch (e) {
        log('Could not set flash mode: $e');
      }
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _requestStoragePermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      // permission granted
    } else if (status.isDenied) {
      // permission denied
    } else if (status.isPermanentlyDenied) {
      // need go to settings
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newResolution = context.select<HomeViewModel, int>((vm) => vm.resolution);
    final savedLensDirection = context.select<HomeViewModel, int>((vm) => vm.cameraLensDirection);

    // Initialize camera with saved values on first build
    if (_controller == null && !_isInitializingCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initCameraFromViewModel(savedLensDirection, newResolution);
      });
    }

    if (newResolution != currentResolutionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            currentResolutionIndex = newResolution;
          });
          _initCamera(selectedLensIndex, _getResolutionPreset(newResolution));
        }
      });
    }

    return Consumer<HomeViewModel>(
      builder: (BuildContext context, HomeViewModel viewModel, Widget? child) {
        final itemList = viewModel.savers;
        final saversRowPadding = MediaQuery.of(context).size.width * 0.1;

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        !isCapturing &&
                        snapshot.error == null &&
                        _controller != null &&
                        _controller!.value.isInitialized) {
                      return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final previewSize = _controller!.value.previewSize;
                          if (previewSize == null || previewSize.height == 0) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final previewAspectRatio = previewSize.height / previewSize.width;
                          final targetWidth = constraints.maxWidth;
                          const baseWidth = 100.0;
                          final scale = targetWidth / baseWidth;

                          return Stack(
                            alignment: AlignmentDirectional.bottomCenter,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth * 4 / 3,
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Builder(
                                        builder: (context) {
                                          return Center(
                                            child: Transform.scale(
                                              scale: scale,
                                              alignment: Alignment.center,
                                              child: SizedBox(
                                                width: baseWidth,
                                                child: AspectRatio(
                                                  aspectRatio: previewAspectRatio,
                                                  child: CameraPreview(_controller!),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Listener(
                                  onPointerDown: (downEvent) {
                                    _onCameraPreviewTap(downEvent, constraints);
                                    setState(() {
                                      focusOffset = Offset(
                                        downEvent.localPosition.dx,
                                        downEvent.localPosition.dy,
                                      );
                                    });
                                    Timer(const Duration(seconds: 1), () {
                                      if (mounted) {
                                        setState(() {
                                          focusOffset = null;
                                        });
                                      }
                                    });
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(painter: FocusBoxPainter(focusOffset)),
                                ),
                              ),
                              SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _sliderValue,
                                        min: _zoom2Slider(_minZoomLevel),
                                        max: _zoom2Slider(_maxZoomLevel),
                                        onChanged: _minZoomLevel != _maxZoomLevel
                                            ? (newValue) {
                                                setState(() {
                                                  _controller?.setZoomLevel(_slider2Zoom(newValue));
                                                  _sliderValue = newValue;
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<int>(
                                      icon: const Icon(Icons.settings_overscan, color: Colors.black),
                                      onSelected: (int newResolution) {
                                        Vibration.vibrate(amplitude: 255, duration: 5);
                                        viewModel.updateResolution(newResolution);
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
                                      onPressed: () async {
                                        setState(() {
                                          if (currentFlashMode == FlashMode.auto) {
                                            currentFlashMode = FlashMode.off;
                                          } else if (currentFlashMode == FlashMode.off) {
                                            currentFlashMode = FlashMode.always;
                                          } else {
                                            currentFlashMode = FlashMode.auto;
                                          }
                                        });
                                        try {
                                          await _controller?.setFlashMode(currentFlashMode);
                                        } catch (e) {
                                          log('Could not set flash mode: $e');
                                        }
                                        Vibration.vibrate(amplitude: 255, duration: 5);
                                      },
                                      icon: Icon(
                                        currentFlashMode == FlashMode.auto
                                            ? Icons.flash_auto
                                            : currentFlashMode == FlashMode.off
                                                ? Icons.flash_off
                                                : Icons.flash_on,
                                        color: Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        Vibration.vibrate(amplitude: 255, duration: 5);
                                        await _toggleCamera(viewModel);
                                      },
                                      icon: const Icon(Icons.cameraswitch, color: Colors.black),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      );
                    } else {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('相机初始化失败'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _initCamera(selectedLensIndex, currentResolution);
                                },
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: MasonryGridView.builder(
                padding: EdgeInsets.fromLTRB(saversRowPadding, 0, saversRowPadding, 12),
                itemCount: itemList.length,
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) {
                  ColorScheme saverColorScheme = ColorScheme.fromSeed(
                    seedColor: viewModel.seedColor,
                  );

                  if (itemList[index].color != null) {
                    saverColorScheme = ColorScheme.fromSeed(
                      seedColor: Color(itemList[index].color!),
                    );
                  }

                  Future<void> _takePhotos() async {
                    if (isCapturing || _controller == null || !_controller!.value.isInitialized) {
                      return;
                    }
                    try {
                      await _initializeControllerFuture;

                      setState(() => isCapturing = true);

                      await Vibration.vibrate(amplitude: 255, duration: 5);
                      await AudioPlayer().play(AssetSource('sounds/camera_shutter.mp3'));

                      try {
                        await _controller!.setFlashMode(currentFlashMode);
                      } catch (e) {
                        log('Could not set flash mode for capture: $e');
                      }

                      final image = await _controller!.takePicture();
                      debugPrint(
                          "take photo result: path: ${image.path} name: ${image.name}");

                      setState(() => isCapturing = false);

                      await _requestStoragePermission();

                      final saver = itemList[index];
                      final paths = saver.paths;
                      final prefixedFileName = getPrefixedFileName(saver);
                      await handleFileAspectRatio(image);
                      final bool isSaved = await moveXFileToFile(image, paths, prefixedFileName);
                      if (isSaved) {
                        final l10n = AppLocalizations.of(context)!;
                        Fluttertoast.showToast(
                          msg: l10n.photoSavedTo(paths.first),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                        );
                      }

                      saver.count++;
                      viewModel.updateSaver(saver);

                      if (!context.mounted) return;
                    } catch (e) {
                      log(e.toString());
                      if (mounted) setState(() => isCapturing = false);
                    }
                  }

                  Future<dynamic> _showEditDialog() async {
                    return showGeneralDialog<dynamic>(
                      context: context,
                      barrierDismissible: false,
                      barrierLabel: "Edit Saver Dialog",
                      pageBuilder: (BuildContext context, anim1, anmi2) {
                        return InsertSaverDialog(saver: itemList[index]);
                      },
                    );
                  }

                  Future<String> _showPathSelector(List<String> paths) async {
                    String selected = paths.first;
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('选择目录'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: paths.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(paths[index]),
                                  onTap: () {
                                    selected = paths[index];
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                    return selected;
                  }

                  return Container(
                    margin: const EdgeInsets.all(4),
                    child: ElevatedButton(
                      onLongPress: () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) => SaverLongPressDialog(saver: itemList[index]),
                        );
                        if (result == 'edit') {
                          final editResult = await _showEditDialog();
                          if (editResult != null) {
                            if (editResult is Map && editResult['action'] == 'delete') {
                              viewModel.removeSaver(itemList[index]);
                            } else if (editResult is Map && editResult['action'] == 'update') {
                              final dialogViewModel = editResult['viewModel'];
                              final updatedSaver = Saver(
                                paths: dialogViewModel.getPath(),
                                name: dialogViewModel.getName(),
                                color: dialogViewModel.getColor()?.value,
                                count: itemList[index].count,
                                photoName: dialogViewModel.getPhotoName(),
                                suffixType: dialogViewModel.getSuffixType(),
                              );
                              viewModel.removeSaver(itemList[index]);
                              viewModel.addSaver(updatedSaver, context);
                            }
                          }
                        } else if (result == 'browse') {
                          String pathToOpen = itemList[index].paths.first;
                          if (itemList[index].paths.length > 1) {
                            pathToOpen = await _showPathSelector(itemList[index].paths);
                            if (pathToOpen.isEmpty) return;
                          }
                          if (!mounted) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => FileBrowserDialog(
                              directoryPath: pathToOpen,
                              onClose: () => Navigator.of(context).pop(),
                            ),
                          );
                        }
                      },
                      onPressed: _takePhotos,
                      child: Badge(
                        isLabelVisible: (itemList[index].suffixType % 2 == 0),
                        backgroundColor: Colors.deepOrange,
                        offset: const Offset(16, -16),
                        label: Text(itemList[index].count.toString()),
                        child: Text(itemList[index].name),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: saverColorScheme.primaryContainer,
                        foregroundColor: saverColorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleCamera(HomeViewModel viewModel) async {
    if (cameras.length <= 1) return;

    final newDirection = currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final newIndex = newDirection == CameraLensDirection.back ? 0 : 1;
    await viewModel.updateCameraLensDirection(newIndex);
    await _initCameraByDirection(newDirection, currentResolution);
  }

  double _zoom2Slider(double zoomValue) {
    if (zoomValue >= 1) {
      return zoomValue;
    } else {
      return 0 - (1 / zoomValue);
    }
  }

  double _slider2Zoom(double sliderValue) {
    if (sliderValue >= 0) {
      return sliderValue;
    } else {
      return (1 / sliderValue) + 1;
    }
  }

  Future<void> _resetZoomLevel() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      double min = await _controller!.getMinZoomLevel();
      double max = await _controller!.getMaxZoomLevel();
      debugPrint('Zoom level range: min=$min, max=$max');

      if (mounted) {
        setState(() {
          // If min equals max, camera doesn't support zoom - use default range
          if (min == max) {
            _minZoomLevel = 1.0;
            _maxZoomLevel = 1.0;
          } else {
            _minZoomLevel = min;
            _maxZoomLevel = max;
          }
          _sliderValue = _zoom2Slider(1.0);
        });
      }
    } catch (e) {
      debugPrint('Error resetting zoom level: $e');
      // Use safe defaults on error
      if (mounted) {
        setState(() {
          _minZoomLevel = 1.0;
          _maxZoomLevel = 1.0;
          _sliderValue = 1.0;
        });
      }
    }
  }

  void _onCameraPreviewTap(PointerDownEvent event, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final x = event.localPosition.dx / constraints.maxWidth;
    final y = event.localPosition.dy / constraints.maxHeight;
    debugPrint("onCameraPreviewTap: x: ${x}, y: ${y}");
    _controller!.setFocusPoint(Offset(x, y));
  }
}

String? getPrefixedFileName(Saver saver) {
  var newName = saver.photoName;
  if (newName != null) {
    switch (saver.suffixType) {
      case 0:
        newName = newName + saver.count.toString();
      case 1:
        DateTime now = DateTime.now();
        String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
        newName += nowStr;
      case 2:
        newName = newName + '_' + saver.count.toString();
      case 3:
        DateTime now = DateTime.now();
        String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
        newName += '_' + nowStr;
      case 4:
        newName = newName + '-' + saver.count.toString();
      case 5:
        DateTime now = DateTime.now();
        String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
        newName += '-' + nowStr;
    }
  }
  return newName;
}

Future<bool> handleFileAspectRatio(XFile imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('无法解析图片内容');
      return false;
    }
    final int width = image.width;
    final int height = image.height;

    if ((width * 4).toDouble() == (height * 3).toDouble() ||
        (width / height - 0.75).abs() < 0.01) {
      return true;
    }

    int targetHeight = (width * 4 / 3).round();
    if (height < targetHeight) {
      debugPrint('图片高度不足以裁剪为3:4, 跳过');
      return false;
    }

    int offsetY = ((height - targetHeight) / 2).round();
    final cropped = img.copyCrop(
      image,
      x: 0,
      y: offsetY,
      width: width,
      height: targetHeight,
    );

    final extension = path.extension(imageFile.path).toLowerCase();
    List<int> encodedBytes;
    if (extension == ".png") {
      encodedBytes = img.encodePng(cropped);
    } else {
      encodedBytes = img.encodeJpg(cropped);
    }
    final file = File(imageFile.path);
    await file.writeAsBytes(encodedBytes, flush: true);

    debugPrint('handleFileAspectRatio success: ${imageFile.path}');
    return true;
  } catch (e) {
    debugPrint('handleFileAspectRatio error: $e');
    return false;
  }
}

Future<bool> moveXFileToFile(
  XFile xFile,
  List<String> destinationPaths,
  String? newName,
) async {
  File sourceFile = File(xFile.path);
  bool isSucceed = true;

  try {
    for (String destinationPath in destinationPaths) {
      final sourceFileName = basename(sourceFile.path);
      String extension = path.extension(sourceFileName);
      File destinationFile = File('$destinationPath/$sourceFileName');

      if (newName != null) {
        await sourceFile.copy(destinationFile.parent.path + '/$newName$extension');
      } else {
        await sourceFile.copy(destinationFile.path);
      }

      log('File moved to: ${destinationFile.parent.path + '/$newName$extension'}');
    }
  } catch (e) {
    isSucceed = false;
    debugPrint('Error moving file: $e');
  } finally {
    await sourceFile.delete();
  }
  return isSucceed;
}

class FocusBoxPainter extends CustomPainter {
  final Offset? boxOffset;
  final double boxSize = 50;

  FocusBoxPainter(this.boxOffset);

  @override
  void paint(Canvas canvas, Size size) {
    if (boxOffset == null) return;
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Rect rect = Rect.fromLTWH(
      boxOffset!.dx - boxSize / 2,
      boxOffset!.dy - boxSize / 2,
      boxSize,
      boxSize,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
