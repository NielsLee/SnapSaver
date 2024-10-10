import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late int selectedCamera = 0;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  bool isCapturing = false;

  @override
  void initState() {
    super.initState();

    _initCamera();
  }

  Future<void> _initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();

    cameras = await availableCameras();
    _controller = CameraController(
        cameras[selectedCamera], ResolutionPreset.max,
        enableAudio: false);

    _initializeControllerFuture = _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (BuildContext context, HomeViewModel viewModel, Widget? child) {
        final itemList = viewModel.savers;
        final saversRowPadding = MediaQuery.of(context).size.width * 0.2;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                  width: 400,
                  child: AspectRatio(
                      aspectRatio: 3 / 4,
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
                                    child: CameraPreview(_controller),
                                  ),
                                  DropdownButton<int>(
                                    value: selectedCamera,
                                    onChanged: (int? newCamera) {
                                      if (newCamera == null ||
                                          newCamera == selectedCamera) return;
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
                                    },
                                    underline: Divider(
                                        height: 0, color: Colors.transparent),
                                    items: List.generate(cameras.length,
                                        (cameraIndex) {
                                      return DropdownMenuItem(
                                          value: cameraIndex,
                                          child:
                                              Text(cameras[cameraIndex].name));
                                    }),
                                    icon: Container(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.cameraswitch),
                                    ),
                                  ),
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

                          // TODO add a progress animate in Saver button
                          final paths = itemList[index].paths;
                          await moveXFileToFile(image, paths);

                          if (!context.mounted) return;
                        } catch (e) {
                          log(e.toString());
                        }
                      }

                      Future<void> _showRemoveDialog() async {}

                      return Container(
                        margin: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          onLongPress: _showRemoveDialog,
                          onPressed: _takePhotos,
                          child: Text(itemList[index].name),
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
}

Future<bool> moveXFileToFile(XFile xFile, List<String> destinationPaths) async {
  File sourceFile = File(xFile.path);
  bool isSucceed = true;

  try {
    for (String destinationPath in destinationPaths) {
      final sourceFileName = basename(sourceFile.path);
      File destinationFile = File('$destinationPath/$sourceFileName');

      await sourceFile.copy(destinationFile.path);

      log('File moved to: ${destinationFile.path}');
    }
  } catch (e) {
    isSucceed = false;
    log('Error moving file: $e');
  } finally {
    await sourceFile.delete();
  }
  return isSucceed;
}
