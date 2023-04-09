import 'package:camera/camera.dart';
import 'package:codebreaker/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global variable for storing the list of cameras available
List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final List<CameraDescription> cameras = await availableCameras();
  final CameraDescription firstCamera = cameras.first;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.pink.shade900, secondary: Colors.pinkAccent),
      ),
      title: 'Codebreaker',
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}
