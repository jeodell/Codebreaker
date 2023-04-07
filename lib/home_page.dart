import 'package:camera/camera.dart';
import 'package:codebreaker/image_detail.dart';
import 'package:codebreaker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  late final CameraController _controller;
  bool _takingPicture = false;

  @override
  void initState() {
    _initializeCamera();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final CameraController cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    _controller = cameraController;

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
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
        body: !_takingPicture
            ? Container(
                decoration: BoxDecoration(
                  // oval gradient
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
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Take Picture @',
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
            : _controller.value.isInitialized
                ? GestureDetector(
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
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera),
                              label: const Text('Click'),
                              onPressed: () async {
                                // If the returned path is not null, navigate
                                // to the DetailScreen
                                await _takePicture().then((String? path) {
                                  if (path != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<dynamic>(
                                        builder: (BuildContext context) =>
                                            DetailScreen(
                                          imagePath: path,
                                        ),
                                      ),
                                    );
                                  } else {
                                    debugPrint('Image path not found!');
                                  }
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
      ),
    );
  }
}
