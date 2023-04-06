import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  late final String _imagePath;
  late final TextRecognizer _textRecognizer;
  Size? _imageSize;
  List<TextElement> _elements = <TextElement>[];
  List<String>? _listCodenames;

  @override
  void initState() {
    _imagePath = widget.imagePath;
    _textRecognizer = TextRecognizer();
    _recognizeWords();
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // Fetching the image size from the image file
  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();
    const ImageConfiguration imageConfiguration = ImageConfiguration();

    final Image image = Image.file(imageFile);
    image.image.resolve(imageConfiguration).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  // To detect the words in an image
  Future<void> _recognizeWords() async {
    _getImageSize(File(_imagePath));

    // Creating an InputImage object using the image path
    final InputImage inputImage = InputImage.fromFilePath(_imagePath);
    // Retrieving the RecognisedText from the InputImage
    final RecognizedText text = await _textRecognizer.processImage(inputImage);

    // Pattern of RegExp for matching a word
    const String pattern = r'^[a-zA-Z]+$';
    final RegExp regEx = RegExp(pattern);

    final List<String> codenames = <String>[];

    // Finding and storing the text String(s) and the TextElement(s)
    for (final TextBlock block in text.blocks) {
      for (final TextLine line in block.lines) {
        print('line.text: ${line.text}');
        if (line.text.contains(' ')) {
          final List<String> words = line.text.split(' ');
          for (final String word in words) {
            if (regEx.hasMatch(word)) {
              codenames.add(word);
            }
          }
        } else {
          if (regEx.hasMatch(line.text)) {
            codenames.add(line.text);
            for (final TextElement element in line.elements) {
              print('element: ${element}');
              _elements.add(element);
            }
          }
        }
      }
    }

    setState(() {
      _listCodenames = codenames;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _imageSize != null
          ? Stack(
              children: <Widget>[
                Container(
                  width: double.maxFinite,
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: _imageSize!.aspectRatio,
                    child: Image.file(
                      File(_imagePath),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Card(
                    elevation: 8,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Identified Words',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: SingleChildScrollView(
                              child: _listCodenames != null
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _listCodenames!.length,
                                      itemBuilder:
                                          (BuildContext context, int index) =>
                                              Text(_listCodenames![index]),
                                    )
                                  : Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: IconButton(
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
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            )
          : Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
