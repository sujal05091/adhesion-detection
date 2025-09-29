import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        // <-- CHANGED: Added AuthService to the list of providers
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        Provider<StorageService>.value(value: storageService),
      ],
      child: const AdhesioSenseApp(),
    ),
  );
}

class AdhesioSenseApp extends StatelessWidget {
  const AdhesioSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // <-- CHANGED: Removed the local instance of AuthService.
    // We will now get it from the provider.

    return MaterialApp(
      title: 'AdhesioSense - AI Adhesion Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A6EBD),
          primary: const Color(0xFF0A6EBD),
          secondary: const Color(0xFF45B08C),
          error: const Color(0xFFE63946),
          background: const Color(0xFFF8F9FA),
          surface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A6EBD),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      // <-- CHANGED: Get the authService from the context
      home: StreamBuilder<User?>(
        stream: context.watch<AuthService>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Debug logging
          print('Auth State - Has Data: ${snapshot.hasData}');
          print('Auth State - Has Error: ${snapshot.hasError}');
          if (snapshot.hasData) {
            print('User logged in: ${snapshot.data!.email}');
            // User is logged in, show home screen
            return const HomeScreen();
          } else {
            print('No user logged in, showing landing screen');
            // User is not logged in, show landing screen
            return const LandingScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/results': (context) => const ResultScreen(),
        '/history': (context) => const HistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
