import 'package:flutter/material.dart';
import 'package:randonnee/screens/login.dart';
import 'package:randonnee/screens/register.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/screens/safety_tips.dart';
import 'package:randonnee/screens/profile.dart';
import 'package:randonnee/screens/my_hikes_screen.dart';
import 'package:randonnee/screens/welcome_screen.dart';
import 'package:randonnee/screens/map.dart';
import 'package:randonnee/screens/hike_details.dart';
import 'package:randonnee/models/hike.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des services
  final authService = AuthService();
  final hikeService = HikeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => hikeService),
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
        '/home': (context) => const WelcomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/hike-details': (context) {
          final hike = ModalRoute.of(context)!.settings.arguments as Hike;
          return HikeDetailsScreen(hike: hike);
        },
        '/map': (context) {
          final hike = ModalRoute.of(context)?.settings.arguments as Hike?;
          return MapScreen(initialHike: hike);
        },
        '/safety-tips': (context) => const SafetyTipsScreen(),
        '/my-hikes': (context) => const MyHikesScreen(),
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
        ? const WelcomeScreen()
        : const WelcomeScreen();
  }
}
