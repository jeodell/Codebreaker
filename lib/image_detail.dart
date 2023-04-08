import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  late final TextRecognizer _textRecognizer;
  late final TextEditingController _textEditingController;
  late final ScrollController _scrollController;
  late final String _imagePath;
  final List<TextElement> _elements = <TextElement>[];
  Size? _imageSize;
  List<CodenamesWord>? _listWords;
  bool _hasGeneratedClues = false;
  String? _generatedClues;

  @override
  void initState() {
    _imagePath = widget.imagePath;
    _textRecognizer = TextRecognizer();
    _textEditingController = TextEditingController();
    _scrollController = ScrollController();
    _recognizeWords();
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _textEditingController.dispose();
    _scrollController.dispose();
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
    await dotenv.load();
    _getImageSize(File(_imagePath));

    // Creating an InputImage object using the image path
    final InputImage inputImage = InputImage.fromFilePath(_imagePath);
    // Retrieving the RecognisedText from the InputImage
    final RecognizedText text = await _textRecognizer.processImage(inputImage);

    // Pattern of RegExp for matching a word
    const String pattern = r'^[a-zA-Z]+$';
    final RegExp regEx = RegExp(pattern);

    final List<CodenamesWord> codenames = <CodenamesWord>[];

    // Finding and storing the text String(s) and the TextElement(s)
    for (final TextBlock block in text.blocks) {
      for (final TextLine line in block.lines) {
        debugPrint('line.text: ${line.text}');
        if (line.text.contains(' ')) {
          final List<String> words = line.text.split(' ');
          for (final String word in words) {
            if (regEx.hasMatch(word)) {
              codenames.add(CodenamesWord(word, false));
            }
          }
        } else {
          if (regEx.hasMatch(line.text)) {
            codenames.add(CodenamesWord(line.text, false));
            for (final TextElement element in line.elements) {
              debugPrint('element: $element');
              _elements.add(element);
            }
          }
        }
      }
    }

    setState(() {
      _listWords = codenames;
    });
  }

  Future<void> _generateClues(List<String> words) async {
    final Uri url = Uri.parse('https://api.openai.com/v1/completions');

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json;charset=UTF-8',
      'Charset': 'utf-8',
      'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}'
    };

    String prompt = 'You are the spymaster for Codenames. Your words are ';
    for (final String word in words) {
      if (word == words.last) {
        prompt += 'and $word. ';
        break;
      }
      prompt += '$word, ';
    }
    prompt +=
        '\n\nGenerate one word clues to link as many of your words together as possible.';
    debugPrint(prompt);

    final String data = jsonEncode(<String, dynamic>{
      'model': 'text-davinci-003',
      'prompt': prompt,
      'temperature': 0.5,
      'max_tokens': 256,
    });

    final http.Response response =
        await http.post(url, headers: headers, body: data);
    Map<String, dynamic> decoded;
    if (response.statusCode == 200) {
      debugPrint(response.body);
      decoded = jsonDecode(response.body);
    } else {
      debugPrint('Error: ${response.statusCode}');
      debugPrint('Reason: ${response.reasonPhrase}');
      return;
    }

    setState(() {
      _hasGeneratedClues = true;
      _generatedClues = decoded['choices'][0]['text'].trimLeft();
    });
  }

  void _addWordToList(String word) {
    if (_listWords != null && word != '') {
      setState(() {
        _listWords!.add(CodenamesWord(word.toUpperCase(), true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _imageSize != null
          ? Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      height: _imageSize!.height * 0.25,
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: _imageSize!.aspectRatio,
                        child: Image.file(
                          File(_imagePath),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                          child: Column(
                            children: _hasGeneratedClues
                                ? <Widget>[
                                    const Text(
                                      'Generated Clues',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.pink.shade900,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _hasGeneratedClues = false;
                                        });
                                      },
                                      child: const Text('Generate New Clues'),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _generatedClues!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ]
                                : <Widget>[
                                    const Text(
                                      'Identified Words',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.pink.shade900,
                                      ),
                                      onPressed: () {
                                        final List<String> words = <String>[];
                                        for (final CodenamesWord codenamesWord
                                            in _listWords!) {
                                          if (codenamesWord.selected) {
                                            words.add(codenamesWord.word);
                                          }
                                        }
                                        _generateClues(words);
                                      },
                                      child: const Text('Generate Clues'),
                                    ),
                                    if (_listWords != null)
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _scrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: <Widget>[
                                                ..._listWords!
                                                    .map((CodenamesWord
                                                            codenamesWord) =>
                                                        CheckboxListTile(
                                                          title: Text(
                                                              codenamesWord
                                                                  .word),
                                                          dense: true,
                                                          controlAffinity:
                                                              ListTileControlAffinity
                                                                  .leading,
                                                          onChanged:
                                                              (bool? value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                codenamesWord
                                                                        .selected
                                                                    ? codenamesWord
                                                                            .selected =
                                                                        false
                                                                    : codenamesWord
                                                                            .selected =
                                                                        true;
                                                              });
                                                            }
                                                          },
                                                          value: codenamesWord
                                                              .selected,
                                                        ))
                                                    .toList(),
                                                Container(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 12),
                                                  height: 40.0,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Checkbox(
                                                        value: false,
                                                        onChanged:
                                                            (bool? value) {},
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              _textEditingController,
                                                          onSubmitted:
                                                              (String value) {
                                                            _addWordToList(
                                                                value);
                                                            _textEditingController
                                                                .clear();
                                                          },
                                                          decoration:
                                                              const InputDecoration(
                                                            hintText:
                                                                'Custom Word',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                ),
              ],
            )
          : Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class CodenamesWord {
  CodenamesWord(this.word, this.selected);

  final String word;
  bool selected;
}

class GPTResponse {
  GPTResponse(
      this.id, this.object, this.created, this.model, this.choices, this.usage);

  final String id;
  final String object;
  final String created;
  final String model;
  final String choices;
  final String usage;
}
