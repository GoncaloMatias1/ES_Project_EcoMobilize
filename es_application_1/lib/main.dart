import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if the user's email and password are stored in local storage
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? storedEmail = prefs.getString('email');
  final String? storedPassword = prefs.getString('password');

  runApp(MyApp(storedEmail: storedEmail, storedPassword: storedPassword));
}

class MyApp extends StatelessWidget {
  final String? storedEmail;
  final String? storedPassword;

  const MyApp({Key? key, this.storedEmail, this.storedPassword}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _initialScreen;

    final isLoggedIn = storedEmail != null && storedPassword != null;

    if (isLoggedIn) {
      // Check if the stored credentials are valid
      _initialScreen = FutureBuilder(
        future: FirebaseAuth.instance.signInWithEmailAndPassword(
          email: storedEmail!,
          password: storedPassword!,
        ),
        builder: (BuildContext context, AsyncSnapshot<UserCredential> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasError) {
              // If sign-in fails, the stored credentials are invalid
              return WelcomeScreen();
            } else {
              // If sign-in is successful, the stored credentials are valid
              return MainPage();
            }
          }
        },
      );
    } else {
      // If there are no stored credentials, show the onboarding or welcome screen
      // depending on whether the user has seen the onboarding screen before
      final seenOnboarding = SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool('seenOnboarding') ?? false);

      _initialScreen = FutureBuilder<bool>(
        future: seenOnboarding,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == false) {
              return OnboardingScreen();
            } else {
              return WelcomeScreen();
            }
          } else {
            return CircularProgressIndicator();
          }
        },
      );
    }

    return MaterialApp(
      title: 'EcoMobilize',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _initialScreen,
    );
  }
}
