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
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/file_browser_dialog.dart';
import 'package:snap_saver/dialog/insert_saver_dialog.dart';
import 'package:snap_saver/dialog/saver_long_press_dialog.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:snap_saver/service/ios_file_save_service.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:snap_saver/widgets/camera_control_bar.dart';
import 'package:snap_saver/widgets/darkroom_toast.dart';
import 'package:snap_saver/widgets/saver_button.dart';
import 'package:vibration/vibration.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
    // iOS: We save to App Documents directory which doesn't require storage permission
    // Photos permission is handled separately in moveXFileToFile
  }

  @override
  Widget build(BuildContext context) {
    final newResolution = context.select<HomeViewModel, int>((vm) => vm.resolution);
    final savedLensDirection = context.select<HomeViewModel, int>((vm) => vm.cameraLensDirection);

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
        final saversRowPadding = MediaQuery.of(context).size.width * 0.04;

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
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
                            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                          }

                          final previewAspectRatio = previewSize.height / previewSize.width;
                          final targetWidth = constraints.maxWidth;
                          const baseWidth = 100.0;
                          final scale = targetWidth / baseWidth;

                          return Stack(
                            alignment: AlignmentDirectional.bottomCenter,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth * 4 / 3,
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Center(
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Vignette overlay
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.2,
                                        colors: [
                                          Colors.transparent,
                                          Colors.transparent,
                                          AppColors.background.withValues(alpha: 0.4),
                                        ],
                                        stops: const [0.0, 0.7, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                ),
                              ),
                              // Focus tap area
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
                              // Focus indicator
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(painter: FocusBoxPainter(focusOffset)),
                                ),
                              ),
                              // Camera control bar
                              CameraControlBar(
                                sliderValue: _sliderValue,
                                minSlider: _zoom2Slider(_minZoomLevel),
                                maxSlider: _zoom2Slider(_maxZoomLevel),
                                onSliderChanged: _minZoomLevel != _maxZoomLevel
                                    ? (newValue) {
                                        setState(() {
                                          _controller?.setZoomLevel(_slider2Zoom(newValue));
                                          _sliderValue = newValue;
                                        });
                                      }
                                    : null,
                                flashMode: currentFlashMode,
                                onFlashToggle: () async {
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
                                onCameraSwitch: () async {
                                  Vibration.vibrate(amplitude: 255, duration: 5);
                                  await _toggleCamera(viewModel);
                                },
                                onResolutionSelected: (newResolution) {
                                  viewModel.updateResolution(newResolution);
                                },
                                currentResolutionIndex: currentResolutionIndex,
                              ),
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
                              Text(AppLocalizations.of(context)!.cameraInitFailed,
                                  style: AppTypography.body().copyWith(color: AppColors.muted)),
                              const SizedBox(height: AppSpacing.md),
                              ElevatedButton(
                                onPressed: () {
                                  _initCamera(selectedLensIndex, currentResolution);
                                },
                                child: Text(AppLocalizations.of(context)!.retry),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: MasonryGridView.builder(
                padding: EdgeInsets.fromLTRB(saversRowPadding, 0, saversRowPadding, AppSpacing.md),
                itemCount: itemList.length,
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) {
                  final saver = itemList[index];
                  final saverColor = saver.color != null ? Color(saver.color!) : null;

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
                      debugPrint("take photo result: path: ${image.path} name: ${image.name}");

                      setState(() => isCapturing = false);

                      await _requestStoragePermission();

                      final paths = saver.paths;
                      final prefixedFileName = getPrefixedFileName(saver);
                      await handleFileAspectRatio(image);
                      final bool isSaved = await moveXFileToFile(image, paths, prefixedFileName);
                      if (isSaved) {
                        DarkroomToast.show(AppLocalizations.of(context)!.photoSavedTo(basename(paths.first)));
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
                      barrierColor: AppColors.background.withValues(alpha: 0.7),
                      transitionBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                          child: ScaleTransition(
                            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                            child: child,
                          ),
                        );
                      },
                      pageBuilder: (BuildContext context, anim1, anim2) {
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
                          title: Text(AppLocalizations.of(context)!.selectDirectory),
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

                  return SaverButton(
                    name: saver.name,
                    count: saver.count,
                    showBadge: saver.suffixType % 2 == 0,
                    saverColor: saverColor,
                    onPressed: _takePhotos,
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
                              color: dialogViewModel.getColor()?.toARGB32(),
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
    double zoom;
    if (sliderValue >= 0) {
      zoom = sliderValue;
    } else {
      zoom = (1 / sliderValue) + 1;
    }
    // Clamp to actual camera zoom range to prevent extreme jumps
    if (zoom < _minZoomLevel) return _minZoomLevel;
    if (zoom > _maxZoomLevel) return _maxZoomLevel;
    return zoom;
  }

  Future<void> _resetZoomLevel() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      double min = await _controller!.getMinZoomLevel();
      double max = await _controller!.getMaxZoomLevel();
      debugPrint('Zoom level range: min=$min, max=$max');

      if (mounted) {
        setState(() {
          if (min == max) {
            _minZoomLevel = 1.0;
            _maxZoomLevel = 1.0;
          } else {
            // Clamp to reasonable bounds (0.5x to 5.0x) to prevent extreme slider range
            _minZoomLevel = min.clamp(0.5, 1.0);
            _maxZoomLevel = max.clamp(1.0, 5.0);
          }
          _sliderValue = _zoom2Slider(1.0);
        });
      }
    } catch (e) {
      debugPrint('Error resetting zoom level: $e');
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
      debugPrint('Unable to decode image');
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
      debugPrint('Image height insufficient for 3:4 crop');
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
    if (Platform.isIOS) {
      // iOS: try user-selected directory first via native channel, fallback to documents directory
      String? userSelectedPath;
      String? savedFileName;
      if (destinationPaths.isNotEmpty) {
        final sourceFileName = basename(sourceFile.path);
        String extension = path.extension(sourceFileName);
        savedFileName = newName != null ? '$newName$extension' : sourceFileName;

        final nativeResult = await IosFileSaveService.saveFile(
          sourcePath: xFile.path,
          destinationDirectory: destinationPaths.first,
          fileName: savedFileName,
        );

        if (nativeResult != null) {
          userSelectedPath = destinationPaths.first;
          log('File saved to user-selected iOS path via native: $nativeResult');
        }
      }

      if (userSelectedPath == null) {
        // Fallback to app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final sourceFileName = basename(sourceFile.path);
        String extension = path.extension(sourceFileName);
        savedFileName = newName != null ? '$newName$extension' : sourceFileName;
        final savedPath = '${directory.path}/$savedFileName';
        await sourceFile.copy(savedPath);
        userSelectedPath = directory.path;
        log('File saved to iOS documents fallback: $savedPath');
      }

      // Also save to photo gallery - only if permission is already granted
      try {
        final photosStatus = await Permission.photosAddOnly.status;
        if (photosStatus.isGranted) {
          log('Saving to photo gallery...');
          // ignore: unused_local_variable
          final galleryResult = await ImageGallerySaver.saveFile(
            '$userSelectedPath/$savedFileName',
          );
          log('Photo saved to gallery');
        } else if (photosStatus == PermissionStatus.denied) {
          // Only request if previously denied (not permanently denied)
          final newStatus = await Permission.photosAddOnly.request();
          if (newStatus.isGranted) {
            log('Saving to photo gallery after permission granted...');
            await ImageGallerySaver.saveFile(
              '$userSelectedPath/$savedFileName',
            );
            log('Photo saved to gallery');
          } else {
            log('Photo saved to documents only (permission still denied)');
          }
        } else {
          // Permission is permanently denied or restricted, don't prompt
          log('Photo saved to documents only (photos permission: ${photosStatus.toString()})');
        }
      } catch (e) {
        log('Error saving to gallery: $e');
      }
    } else {
      // Android: direct file system access
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
  final double cornerLength = 12;

  FocusBoxPainter(this.boxOffset);

  @override
  void paint(Canvas canvas, Size size) {
    if (boxOffset == null) return;
    final Paint paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double left = boxOffset!.dx - boxSize / 2;
    final double top = boxOffset!.dy - boxSize / 2;
    final double right = boxOffset!.dx + boxSize / 2;
    final double bottom = boxOffset!.dy + boxSize / 2;

    // Draw only corners for a film-camera focus aesthetic
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    // Top-right
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
