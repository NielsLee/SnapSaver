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
import 'package:snap_saver/dialog/remove_saver_dialog.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:vibration/vibration.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

import 'entity/saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late int selectedLensIndex = 0;
  late CameraController _controller;
  double _minZoomLevel = 1 / 2;
  double _maxZoomLevel = 3;
  Future<void>? _initializeControllerFuture;
  bool isCapturing = false;
  Offset? focusOffset = null;
  double _sliderValue = 1;
  ResolutionPreset currentResolution = ResolutionPreset.max; // default max
  int currentResolutionIndex = 0;
  var currentLensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();

    _initCamera(currentResolution);
  }

  Future<void> _initCamera(ResolutionPreset resolution) async {
    WidgetsFlutterBinding.ensureInitialized();

    cameras = await availableCameras();
    await Permission.camera.request();
    _controller = CameraController(cameras[selectedLensIndex], resolution,
        enableAudio: false);

    _initializeControllerFuture = _controller.initialize();

    if (mounted) {
      setState(() {});
    }
    await _resetZoomLevel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    int newResolution = context.watch<HomeViewModel>().resolution;
    if (newResolution != currentResolutionIndex) {
      switch (context.watch<HomeViewModel>().resolution) {
        case 0:
          _initCamera(ResolutionPreset.low);
        case 1:
          _initCamera(ResolutionPreset.medium);
        case 2:
          _initCamera(ResolutionPreset.high);
        case 3:
          _initCamera(ResolutionPreset.veryHigh);
        case 4:
          _initCamera(ResolutionPreset.ultraHigh);
        case 5:
          _initCamera(ResolutionPreset.max);
      }
      currentResolutionIndex = newResolution;
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
                        !isCapturing) {
                      return LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return Stack(
                            alignment: AlignmentDirectional.bottomCenter,
                            children: <Widget>[
                              // 使用裁剪方式：保持宽度不变，高度对称裁剪
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
                                          // 获取相机预览的实际尺寸
                                          final previewSize =
                                              _controller.value.previewSize;
                                          if (previewSize == null ||
                                              previewSize.height == 0) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          // 计算相机预览的实际宽高比
                                          final previewAspectRatio =
                                              previewSize.height /
                                                  previewSize.width;

                                          // 目标宽度
                                          final targetWidth =
                                              constraints.maxWidth;

                                          // 使用 AspectRatio 让 CameraPreview 按原始比例显示
                                          // 然后用 Transform.scale 等比例放大，使宽度等于目标宽度
                                          // 使用较小的基准宽度，让 AspectRatio 有约束可计算
                                          final baseWidth = 100.0;

                                          // 计算缩放比例，使放大后的宽度等于目标宽度
                                          final scale = targetWidth / baseWidth;

                                          return Center(
                                            child: Transform.scale(
                                              scale: scale,
                                              alignment: Alignment.center,
                                              child: SizedBox(
                                                width: baseWidth,
                                                child: AspectRatio(
                                                  aspectRatio:
                                                      previewAspectRatio,
                                                  child: CameraPreview(
                                                      _controller),
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
                              // 添加触摸监听层
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
                                    // delay 1 second and remove focus box
                                    Timer(Duration(seconds: 1), () {
                                      setState(() {
                                        focusOffset = null;
                                      });
                                    });
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                              // 对焦框绘制层（放在最上层，确保显示）
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: FocusBoxPainter(focusOffset),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Otherwise, display a loading indicator.
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            FutureBuilder(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Container(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                          ),
                          Slider(
                            value: _sliderValue,
                            min: _zoom2Slider(_minZoomLevel),
                            max: _zoom2Slider(_maxZoomLevel),
                            onChanged: (newValue) {
                              setState(() {
                                _controller
                                    .setZoomLevel(_slider2Zoom(newValue));
                                _sliderValue = newValue;
                              });
                            },
                          ),
                          Spacer(),
                          IconButton(
                              onPressed: () {
                                if (currentLensDirection ==
                                    CameraLensDirection.back) {
                                  currentLensDirection =
                                      CameraLensDirection.front;
                                } else {
                                  currentLensDirection =
                                      CameraLensDirection.back;
                                }

                                for (var (lensIndex, cameraLens)
                                    in cameras.indexed) {
                                  if (cameraLens.lensDirection ==
                                      currentLensDirection) {
                                    setState(() {
                                      Vibration.vibrate(
                                          amplitude: 255, duration: 5);
                                      selectedLensIndex = lensIndex;
                                      _initCamera(currentResolution);
                                    });
                                  }
                                }
                              },
                              icon: Icon(Icons.cameraswitch)),
                          Container(
                            width: 12,
                          )
                        ],
                      ),
                    );
                  } else {
                    return Container(height: 40);
                  }
                }),
            Expanded(
              child: MasonryGridView.builder(
                  padding: EdgeInsets.fromLTRB(
                      saversRowPadding, 0, saversRowPadding, 12),
                  itemCount: itemList.length,
                  scrollDirection: Axis.horizontal,
                  gridDelegate:
                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2),
                  itemBuilder: (context, index) {
                    ColorScheme saverColorScheme =
                        ColorScheme.fromSeed(seedColor: viewModel.seedColor);

                    // generate Saver color scheme
                    if (itemList[index].color != null) {
                      saverColorScheme = ColorScheme.fromSeed(
                          seedColor: Color(itemList[index].color!));
                    }

                    // Function for taking photos
                    Future<void> _takePhotos() async {
                      if (isCapturing) {
                        // if is capturing, skip
                        return;
                      }
                      try {
                        await _initializeControllerFuture;

                        setState(() {
                          isCapturing = true;
                        });

                        await Vibration.vibrate(amplitude: 255, duration: 5);
                        await AudioPlayer()
                            .play(AssetSource('sounds/camera_shutter.mp3'));
                        final image = await _controller.takePicture();
                        debugPrint(
                            "take photo result: path: ${image.path} name: ${image.name}");

                        setState(() {
                          isCapturing = false;
                        });

                        _requestStoragePermission();

                        // TODO add a progress animate in Saver button
                        final saver = itemList[index];
                        final paths = saver.paths;

                        final prefixedFileName = getPrefixedFileName(saver);
                        await handleFileAspectRatio(image);
                        await moveXFileToFile(image, paths, prefixedFileName);

                        saver.count++;
                        viewModel.updateSaver(saver);

                        if (!context.mounted) return;
                      } catch (e) {
                        log(e.toString());
                      }
                    }

                    Future<bool?> _showRemoveDialog() async {
                      return showGeneralDialog<bool?>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "Remove Saver Dialog",
                        pageBuilder: (BuildContext context, anim1, anmi2) {
                          return RemoveSaverDialog(saver: itemList[index]);
                        },
                      );
                    }

                    // Saver button
                    return Container(
                      margin: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        onLongPress: () async {
                          final remove = await _showRemoveDialog();
                          if (remove == true) {
                            viewModel.removeSaver(itemList[index]);
                          }
                        },
                        onPressed: _takePhotos,
                        child: Badge(
                            isLabelVisible:
                                (itemList[index].suffixType % 2 == 0),
                            backgroundColor: Colors.deepOrange,
                            offset: Offset(16, -16),
                            label: Text(itemList[index].count.toString()),
                            child: Text(itemList[index].name)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saverColorScheme.primaryContainer,
                          foregroundColor: saverColorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }),
            ),
          ],
        );
      },
    );
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
    await _controller.initialize();
    double min = await _controller.getMinZoomLevel();
    double max = await _controller.getMaxZoomLevel();

    setState(() {
      _minZoomLevel = min;
      _maxZoomLevel = max;
      _sliderValue = 1;
    });
  }

  void _onCameraPreviewTap(PointerDownEvent event, BoxConstraints constraints) {
    final x = event.localPosition.dx / constraints.maxWidth;
    final y = event.localPosition.dy / constraints.maxHeight;
    debugPrint("onCameraPreviewTap: x: ${x}, y: ${y}");

    _controller.setFocusPoint(Offset(x, y));
  }
}

String? getPrefixedFileName(Saver saver) {
  var newName = saver.photoName;
  if (newName != null) {
    switch (saver.suffixType) {
      case 0:
        {
          newName = newName + saver.count.toString();
        }
      case 1:
        {
          DateTime now = DateTime.now();
          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          newName += nowStr;
        }
      case 2:
        {
          newName = newName + '_' + saver.count.toString();
        }
      case 3:
        {
          DateTime now = DateTime.now();
          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          newName += '_' + nowStr;
        }
      case 4:
        {
          newName = newName + '-' + saver.count.toString();
        }
      case 5:
        {
          DateTime now = DateTime.now();
          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          newName += '-' + nowStr;
        }
    }
  }
  return newName;
}

/**
 * 裁剪图片到3:4比例
 */
Future<bool> handleFileAspectRatio(XFile imageFile) async {
  try {
    // 读取图片字节
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('无法解析图片内容');
      return false;
    }
    final int width = image.width;
    final int height = image.height;

    // 若宽高比已为3:4, 不处理
    if ((width * 4).toDouble() == (height * 3).toDouble() ||
        (width / height - 0.75).abs() < 0.01) {
      // 3:4 比例
      return true;
    }

    // 计算目标高度
    int targetHeight = (width * 4 / 3).round();

    // 如果实际高度小于目标高度, 则不能裁剪
    if (height < targetHeight) {
      debugPrint('图片高度不足以裁剪为3:4, 跳过');
      return false;
    }

    // 取中间部分
    int offsetY = ((height - targetHeight) / 2).round();

    // 裁剪图片
    final cropped = img.copyCrop(
      image,
      x: 0,
      y: offsetY,
      width: width,
      height: targetHeight,
    );

    // 重新保存图片（覆盖原文件）
    final extension = path.extension(imageFile.path).toLowerCase();
    List<int> encodedBytes;
    if (extension == ".png") {
      encodedBytes = img.encodePng(cropped);
    } else {
      // 默认jpg
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
    XFile xFile, List<String> destinationPaths, String? newName) async {
  File sourceFile = File(xFile.path);
  bool isSucceed = true;

  try {
    for (String destinationPath in destinationPaths) {
      final sourceFileName = basename(sourceFile.path);
      String extension = path.extension(sourceFileName);
      File destinationFile = File('$destinationPath/$sourceFileName');

      if (newName != null) {
        await sourceFile
            .copy(destinationFile.parent.path + '/$newName$extension');
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
    if (boxOffset == null) {
      return;
    }
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 每次都需要重绘
  }
}
