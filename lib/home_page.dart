import 'package:camera/camera.dart';
import 'package:codebreaker/image_detail.dart';
import 'package:codebreaker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _takingPicture = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _takePicture() async {
    if (!_controller.value.isInitialized) {
      debugPrint('Controller is not initialized');
      return null;
    }

    String? imagePath;

    if (_controller.value.isTakingPicture) {
      debugPrint('Processing is in progress...');
      return null;
    }

    try {
      // Turning off the camera flash
      _controller.setFlashMode(FlashMode.off);
      // Returns the image in cross-platform file abstraction
      final XFile file = await _controller.takePicture();
      // Retrieving the path
      imagePath = file.path;
    } on CameraException catch (e) {
      debugPrint('Camera Exception: $e');
      return null;
    }

    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              return !_takingPicture
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: <Color>[
                            Colors.yellow.shade500,
                            Colors.yellow.shade700,
                            Colors.orange.shade400,
                            Colors.orange.shade700,
                            Colors.red.shade700,
                            Colors.pink.shade900,
                          ],
                          stops: const <double>[0.0, 0.3, 0.4, 0.65, 0.85, 1.0],
                          radius: 0.9,
                          focal: Alignment.center,
                          focalRadius: 0.25,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              'CODEBREAKER',
                              style: TextStyle(
                                fontSize: 36,
                                fontFamily: 'SkyFall Done',
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.pink.shade900,
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text(
                                'Get Clues',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'SkyFall Done',
                                ),
                              ),
                              onPressed: () => setState(() {
                                _takingPicture = true;
                              }),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onHorizontalDragUpdate: (DragUpdateDetails details) {
                        const int sensitivity = 16;
                        if (details.delta.dx > sensitivity) {
                          setState(() {
                            _takingPicture = false;
                          });
                        }
                      },
                      child: Stack(
                        children: <Widget>[
                          CameraPreview(_controller),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 32,
                              shadows: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black87,
                                  blurStyle: BlurStyle.outer,
                                  blurRadius: 8,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            onPressed: () {
                              setState(() {
                                _takingPicture = false;
                              });
                            },
                          ),
                        ],
                      ),
                    );
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _takingPicture
            ? FloatingActionButton(
                backgroundColor: Colors.pink.shade900,
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;

                    // Turning off the camera flash
                    _controller.setFlashMode(FlashMode.off);

                    // Attempt to take a picture and get the file `image`
                    // where it was saved.
                    final XFile image = await _controller.takePicture();

                    if (!mounted) {
                      return;
                    }

                    // If the picture was taken, display it on a new screen.
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => DetailScreen(
                          // Pass the automatically generated path to
                          // the DisplayPictureScreen widget.
                          imagePath: image.path,
                        ),
                      ),
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                child: const Icon(
                  Icons.camera_alt,
                  size: 24,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
