import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
    });
  }

  Future<void> _startListening() async {
    await _speechToText.listen(onResult: onSpeechResult);
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("noteScape AI"),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening
                    ? "Making note! You can focus on lecture"
                    : _speechEnabled
                    ? "Tap when lecture starts!"
                    : "Initializing...",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  _wordsSpoken,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            if (_speechToText.isNotListening) SizedBox.shrink(),
          ],
        ),

      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: FloatingActionButton(
          onPressed:
          _speechToText.isListening ? _stopListening : _startListening,
          tooltip: 'listen',
          child: Icon(
            _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
//test