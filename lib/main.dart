import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDLU5gN5lATd74wKgT9TD4H5a7FMG5AGio",
        authDomain: "studentplus-7ba3a.firebaseapp.com",
        projectId: "studentplus-7ba3a",
        storageBucket: "studentplus-7ba3a.firebasestorage.app",
        messagingSenderId: "41081265865",
        appId: "1:41081265865:web:4ad25e694f120dbe547718",
        measurementId: "G-HGZCEW04ST",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const StudentPlusApp());
}

class StudentPlusApp extends StatelessWidget {
  const StudentPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student+',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}