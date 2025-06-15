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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late int selectedCamera = 0;
  late CameraController _controller;
  double _minZoomLevel = 1 / 2;
  double _maxZoomLevel = 3;
  Future<void>? _initializeControllerFuture;
  bool isCapturing = false;
  Offset? focusOffset = null;
  double _sliderValue = 1;

  @override
  void initState() {
    super.initState();

    _initCamera();
  }

  Future<void> _initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();

    cameras = await availableCameras();

    await Permission.camera.request();
    _controller = CameraController(
        cameras[selectedCamera], ResolutionPreset.max,
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
    return Consumer<HomeViewModel>(
      builder: (BuildContext context, HomeViewModel viewModel, Widget? child) {
        final itemList = viewModel.savers;
        final saversRowPadding = MediaQuery.of(context).size.width * 0.2;
        final ccontainerWidth = MediaQuery.of(context).size.width;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                  width: ccontainerWidth,
                  child: AspectRatio(
                      aspectRatio: context.watch<HomeViewModel>().aspectRatio,
                      child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              !isCapturing) {
                            return Stack(
                                alignment: AlignmentDirectional.bottomCenter,
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: LayoutBuilder(
                                      builder: (BuildContext context,
                                          BoxConstraints constraints) {
                                        return Listener(
                                          onPointerDown: (downEvent) {
                                            _onCameraPreviewTap(
                                                downEvent, constraints);
                                            setState(() {
                                              focusOffset = Offset(
                                                  downEvent.localPosition.dx,
                                                  downEvent.localPosition.dy);
                                            });
                                            // delay 1 second and remove focus box
                                            Timer(Duration(seconds: 1), () {
                                              setState(() {
                                                focusOffset = null;
                                              });
                                            });
                                          },
                                          child: Stack(
                                            children: [
                                              CameraPreview(_controller),
                                              CustomPaint(
                                                painter: FocusBoxPainter(
                                                    focusOffset),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Slider(
                                          value: _sliderValue,
                                          min: _zoom2Slider(_minZoomLevel),
                                          max: _zoom2Slider(_maxZoomLevel),
                                          onChanged: (newValue) {
                                            setState(() {
                                              _controller.setZoomLevel(
                                                  _slider2Zoom(newValue));
                                              _sliderValue = newValue;
                                            });
                                          },
                                        ),
                                        DropdownButton<int>(
                                          value: selectedCamera,
                                          onChanged: (int? newCamera) {
                                            if (newCamera == null ||
                                                newCamera == selectedCamera)
                                              return;
                                            selectedCamera = newCamera;
                                            setState(() {
                                              Vibration.vibrate(
                                                  amplitude: 255, duration: 5);
                                              _controller = CameraController(
                                                  cameras[selectedCamera],
                                                  ResolutionPreset.max,
                                                  enableAudio: false);

                                              _initializeControllerFuture =
                                                  _controller.initialize();
                                            });
                                            _resetZoomLevel();
                                          },
                                          underline: Divider(
                                              height: 0,
                                              color: Colors.transparent),
                                          items: List.generate(cameras.length,
                                              (cameraIndex) {
                                            return DropdownMenuItem(
                                                value: cameraIndex,
                                                child: Text(
                                                    cameras[cameraIndex].name));
                                          }),
                                          icon: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.cameraswitch),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ]);
                          } else {
                            // Otherwise, display a loading indicator.
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      ))),
            ),
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
                      // TODO: get global color scheme from one place
                      ColorScheme saverColorScheme =
                          ColorScheme.fromSeed(seedColor: Colors.green);

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

                          setState(() {
                            isCapturing = false;
                          });

                          _requestStoragePermission();

                          // TODO add a progress animate in Saver button
                          final saver = itemList[index];
                          final paths = saver.paths;
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
                                  String nowStr =
                                      DateFormat('yyyyMMddHHmmss').format(now);
                                  newName += nowStr;
                                }
                              case 2:
                                {
                                  newName =
                                      newName + '_' + saver.count.toString();
                                }
                              case 3:
                                {
                                  DateTime now = DateTime.now();
                                  String nowStr =
                                      DateFormat('yyyyMMddHHmmss').format(now);
                                  newName += '_' + nowStr;
                                }
                              case 4:
                                {
                                  newName =
                                      newName + '-' + saver.count.toString();
                                }
                              case 5:
                                {
                                  DateTime now = DateTime.now();
                                  String nowStr =
                                      DateFormat('yyyyMMddHHmmss').format(now);
                                  newName += '-' + nowStr;
                                }
                            }
                          }
                          await moveXFileToFile(image, paths, newName);

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
                            foregroundColor:
                                saverColorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    })),
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

    _controller.setFocusPoint(Offset(x, y));
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
    log('Error moving file: $e');
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
