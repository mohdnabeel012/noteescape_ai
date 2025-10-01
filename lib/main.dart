import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'aws/amplifyconfiguration.dart';
// Import the new home page
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      // call Amplify.configure to use the initialized categories in your app
      // NOTE: Ensure your 'aws/amplifyconfiguration.dart' file exists and is correct.
      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      // Keep your custom sign-up form fields
      signUpForm: SignUpForm.custom(fields: [
        SignUpFormField.name(required: true),
        SignUpFormField.email(required: true),
        SignUpFormField.phoneNumber(required: true),
        SignUpFormField.password(),
        SignUpFormField.passwordConfirmation(),
      ]),
      child: MaterialApp(
        // This builder is essential for the Authenticator to manage state and navigation
        builder: Authenticator.builder(),

        // This is the widget shown when the user is successfully signed in.
        // It now points to your custom HomePage.
        home: const HomePage(),
      ),
    );
  }
}
