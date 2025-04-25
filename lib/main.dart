import 'package:flutter/material.dart';
import 'package:randonnee/screens/home.dart';
import 'package:randonnee/screens/login.dart';
import 'package:randonnee/screens/register.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/screens/safety_tips.dart';
import 'package:randonnee/screens/profile.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => HikeService()), // Ajout crucial
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiking App',

      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/safety-tips': (context) => const SafetyTipsScreen(),

        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return authService.isAuthenticated
        ? const HomeScreen()
        : const LoginScreen();
  }
}
