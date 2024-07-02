import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
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
    _controller = CameraController(cameras[0], ResolutionPreset.max);

    _initializeControllerFuture = _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
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
                        if (snapshot.connectionState == ConnectionState.done) {
                          // If the Future is complete, display the preview.
                          return Visibility(
                            visible: !isCapturing,
                              child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: CameraPreview(_controller)));
                        } else {
                          // Otherwise, display a loading indicator.
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    )),
              ),
            ),
            Expanded(
                child: MasonryGridView.builder(
                    padding: EdgeInsets.fromLTRB(saversRowPadding, 0, saversRowPadding, 12),
                    itemCount: itemList.length,
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        child: ElevatedButton(
                            onPressed: () async {
                              try {

                                await _initializeControllerFuture;

                                setState(() {
                                  isCapturing = true;
                                });

                                final image = await _controller.takePicture();

                                setState(() {
                                  isCapturing = false;
                                });

                                await moveXFileToFile(image, itemList[index].path);

                                if (!context.mounted) return;

                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Text(itemList[index].name)),
                      );
                    })),
          ],
        );
      },
    );
  }
}

Future<void> moveXFileToFile(XFile xFile, String destinationPath) async {
  try {
    File sourceFile = File(xFile.path);
    final sourceFileName = basename(sourceFile.path);
    File destinationFile = File('$destinationPath/$sourceFileName');

    await sourceFile.copy(destinationFile.path);

    await sourceFile.delete();

    print('File moved to: ${destinationFile.path}');
  } catch (e) {
    print('Error moving file: $e');
  }
}
