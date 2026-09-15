import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization.dart';
import 'login_screen.dart';
import 'main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  
  // Set preferred orientations and system overlay styles
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const SignSpeakApp());
}

class SignSpeakApp extends StatelessWidget {
  const SignSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Localization.appLanguageNotifier,
      builder: (context, langCode, child) {
        return MaterialApp(
          title: 'SignSpeak',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0284C7),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              secondary: Color(0xFF38BDF8),
              surface: Colors.white,
              error: Colors.redAccent,
            ),
            fontFamily: 'Inter',
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F172A),
              elevation: 1,
              shadowColor: Colors.black12,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF0284C7),
              unselectedItemColor: Colors.black45,
            ),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data != null && !Localization.bypassStream) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                        ),
                      );
                    }
                    if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.exists) {
                      final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        Localization.userName = data['name'] ?? 'User';
                        Localization.userEmail = data['email'] ?? snapshot.data!.email ?? '';
                      }
                    } else {
                      Localization.userName = snapshot.data!.email?.split('@').first ?? 'User';
                      Localization.userEmail = snapshot.data!.email ?? '';
                    }
                    return const MainLayout();
                  },
                );
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
