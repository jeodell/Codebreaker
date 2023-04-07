import 'package:camera/camera.dart';
import 'package:codebreaker/home_page.dart';
import 'package:flutter/material.dart';

// Global variable for storing the list of cameras available
List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  // Fetch the available cameras before initializing the app
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.description}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Codebreaker',
      home: Home(),
    );
  }
}
