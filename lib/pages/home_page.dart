import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Imports for Storage
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";

  // Controller for the filename input
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
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
    // Clear previous text when starting new recording
    setState(() {
      _wordsSpoken = "";
    });
    // NOTE: We don't need setState() here because onResult will handle it.
    await _speechToText.listen(onResult: onSpeechResult);
  }

  // NOTE: _stopListening is now private and only handles the STT API call
  Future<void> _stopListening() async {
    await _speechToText.stop();
    // No setState() here; the mic button logic handles the UI update
  }

  // Unified logic for the Floating Action Button
  void _micButtonPressed() async {
    if (_speechToText.isListening) {
      // 1. Microphone is active, user clicked to STOP recording.
      await _stopListening();

      // 2. Trigger the upload process immediately after stopping.
      // We use the existing _handleSaveNote logic, renamed for clarity.
      await _saveAndUploadNote();

    } else {
      // 3. Microphone is off, user clicked to START recording.
      await _startListening();
    }
    // Update the UI state after the action is complete
    setState(() {});
  }


  // Upload the transcribed string directly using uploadData
  Future<void> _uploadNote(String content, String filename) async {
    final key = 'public/$filename.txt';

    try {
      final dataPayload = StorageDataPayload.string(
        content,
        contentType: 'text/plain',
      );

      await Amplify.Storage.uploadData(
        data: dataPayload,
        path: StoragePath.fromString(key),
      ).result;

      // Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note "$filename.txt" uploaded successfully!')),
        );
      }

      // Clear the text field and transcribed text
      setState(() {
        _fileNameController.clear();
        _wordsSpoken = "";
      });

    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.message}')),
        );
      }
    }
  }

  // Renamed and streamlined function for saving/uploading
  Future<void> _saveAndUploadNote() async {
    final filename = _fileNameController.text.trim();

    // VALIDATION CHECKS
    if (filename.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note name before recording.')),
      );
      return;
    }
    if (_wordsSpoken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No speech recognized. Not saving.')),
      );
      // Ensure UI is ready for the next recording
      setState(() {
        _wordsSpoken = "";
      });
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording complete. Uploading "$filename.txt"...')),
      );
    }

    // Execute the upload directly with the spoken words
    await _uploadNote(_wordsSpoken, filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("noteScape AI"),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SignOutButton(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening
                    ? "Recording... Tap again to STOP and SAVE!" // Updated status message
                    : _speechEnabled
                    ? "Tap the mic to start recording."
                    : "Initializing speech service...",
                style: const TextStyle(fontSize: 20),
              ),
            ),

            // Filename Input Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'Enter Note Name',
                  hintText: 'e.g., Lecture_Maths_Week5',
                  border: OutlineInputBorder(),
                ),
                enabled: !_speechToText.isListening, // Disable input while recording
              ),
            ),

            // Transcribed Text Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    _wordsSpoken,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),

            // REMOVED: The separate "Save to Cloud" button is no longer needed.
            // A spacer is used instead to push the mic button up slightly.
            const SizedBox(height: 70),
          ],
        ),
      ),

      // Mic Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: FloatingActionButton(
          // CORRECTED: Call the unified function
          onPressed: _micButtonPressed,
          tooltip: _speechToText.isListening ? 'Stop and Save' : 'Start Listening',
          backgroundColor: _speechToText.isListening ? Colors.red : Theme.of(context).primaryColor,
          child: Icon(
            _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
            color: Colors.white,
          ),
        ),
      ),
      // Position the button correctly
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}