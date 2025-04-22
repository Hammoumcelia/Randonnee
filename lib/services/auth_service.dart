import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class AuthService with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get currentUser => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    // Ici, vous implémenteriez la logique de connexion réelle
    // Pour l'exemple, nous simulons une connexion réussie
    await Future.delayed(const Duration(seconds: 1));

    _user = User(id: '1', name: 'Randonneur Test', email: email);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    // Ici, vous implémenteriez la logique d'inscription réelle
    // Pour l'exemple, nous simulons une inscription réussie
    await Future.delayed(const Duration(seconds: 1));

    _user = User(id: '1', name: name, email: email);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
