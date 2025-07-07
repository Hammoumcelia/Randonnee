import 'package:flutter/foundation.dart';
import 'package:randonnee/services/database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      name: map['name'],
      email: map['email'],
      role: map['role'] ?? 'user',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
  bool get isAdmin => role == 'admin';
}

class AuthService with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;

  bool get isLoading => _isLoading;
  String? get error => _error;
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;

      final db = DatabaseService();
      final user = await db.getUserByEmail(email);

      if (user == null) {
        throw AuthException('Utilisateur non trouvé');
      }

      final hashedPassword = _hashPassword(password);
      if (user['password'] != hashedPassword) {
        throw AuthException('Mot de passe incorrect');
      }

      _user = User.fromMap(user);
      notifyListeners();
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = 'Erreur de connexion';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      _setLoading(true);
      _error = null;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw AuthException('Tous les champs sont obligatoires');
      }

      if (password.length < 6) {
        throw AuthException('Le mot de passe doit faire au moins 6 caractères');
      }

      final db = DatabaseService();
      final existingUser = await db.getUserByEmail(email);

      if (existingUser != null) {
        throw AuthException('Cet email est déjà utilisé');
      }

      final userId = await db.createUser({
        'name': name,
        'email': email,
        'password': _hashPassword(password),
        'role': 'user',
      });

      _user = User(
        id: userId.toString(),
        name: name,
        email: email,
        role: 'user',
        createdAt: DateTime.now(),
      );
      notifyListeners();
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = "Erreur d'inscription";
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
