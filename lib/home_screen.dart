import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'display_picture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _initCamera();
  }

  Future<void> _initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();

    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);

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
        return Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 400,
              child: Column(
                children: [
                  AspectRatio(
                      aspectRatio: 3 / 4,
                      child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // If the Future is complete, display the preview.
                            return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CameraPreview(_controller));
                          } else {
                            // Otherwise, display a loading indicator.
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      )),
                  Expanded(
                      child: MasonryGridView.builder(
                          itemCount: itemList.length,
                          scrollDirection: Axis.horizontal,
                          gridDelegate:
                              const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2),
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.all(2),
                              child: ElevatedButton(
                                  onPressed: () {},
                                  child: Text(itemList[index])),
                            );
                          })),
                ],
              ),
            ));
      },
    );
  }
}

Future<void> takeSnap(Future<void> initializeControllerFuture,
    CameraController controller, BuildContext context) async {
  try {
    // Ensure that the camera is initialized.
    await initializeControllerFuture;

    // Attempt to take a picture and get the file `image`
    // where it was saved.
    final image = await controller.takePicture();

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
          imagePath: image.path,
        ),
      ),
    );
  } catch (e) {
    print(e);
  }
}
