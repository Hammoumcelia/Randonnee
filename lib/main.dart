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
import 'package:randonnee/services/database_service.dart';
import 'package:randonnee/services/review_service.dart';
import 'package:randonnee/screens/admin_screen.dart';
import 'dart:math' show log, pi, pow, tan, cos;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:randonnee/screens/network_utils.dart';
import 'package:randonnee/services/sos_service.dart';
import 'package:randonnee/services/notification_service.dart';

Future<void> _precacheTilesInBackground(DatabaseService dbService) async {
  try {
    // Zone géographique réduite pour les tests
    final bounds = LatLngBounds(
      LatLng(36.0, 2.0), // Nord-Ouest
      LatLng(37.0, 3.0), // Sud-Est
    );

    // Niveaux de zoom utiles seulement
    for (int z = 10; z <= 12; z++) {
      final topLeft = bounds.northWest;
      final bottomRight = bounds.southEast;

      final x0 = ((topLeft.longitude + 180) / 360 * pow(2, z)).floor();
      final x1 = ((bottomRight.longitude + 180) / 360 * pow(2, z)).floor();
      final y0 =
          ((1 -
                  log(
                        tan(topLeft.latitude * pi / 180) +
                            1 / cos(topLeft.latitude * pi / 180),
                      ) /
                      2 *
                      pow(2, z))
              .floor());
      final y1 =
          ((1 -
                  log(
                        tan(bottomRight.latitude * pi / 180) +
                            1 / cos(bottomRight.latitude * pi / 180),
                      ) /
                      2 *
                      pow(2, z))
              .floor());

      // Limite le nombre de tuiles
      int count = 0;
      for (int x = x0; x <= x1 && count < 20; x++) {
        for (int y = y0; y <= y1 && count < 20; y++) {
          try {
            await dbService.cacheMapTile(
              x,
              y,
              z,
              'https://tile.openstreetmap.org/$z/$x/$y.png',
            );
            count++;
            await Future.delayed(const Duration(milliseconds: 10));
          } catch (e) {
            debugPrint('Erreur tuile $z/$x/$y: $e');
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Erreur pré-cache: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  final networkUtils = NetworkUtils();

  // Initialisation des services
  final authService = AuthService();
  final hikeService = HikeService();
  final reviewService = ReviewService(dbService);

  await NotificationService.initialize();
  // Initialisation minimale synchrone
  await dbService.initMapCache();
  await networkUtils.startMonitoring();
  final sosService = SOSService();
  await sosService.initialize();
  // Pré-cache non bloquant
  _precacheTilesInBackground(dbService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => hikeService),
        ChangeNotifierProvider(create: (_) => reviewService),
        Provider.value(value: dbService),
        ChangeNotifierProvider.value(value: networkUtils),
        Provider<SOSService>.value(value: sosService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Écoute des messages SOS
    final sosService = Provider.of<SOSService>(context, listen: false);
    sosService.messageStream.listen((message) {
      // Affiche une notification
      NotificationService.showSOSNotification(message);

      // Affiche un SnackBar si l'app est au premier plan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS reçu: $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
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
        '/admin': (context) => const AdminScreen(),
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
