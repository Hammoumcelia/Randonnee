import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils extends ChangeNotifier {
  bool _isOnline = true;
  bool _forceOfflineMode = false;
  bool get isOnline => _isOnline;
  bool get forceOfflineMode => _forceOfflineMode;

  Future<void> toggleOfflineMode(bool enabled) async {
    _forceOfflineMode = enabled;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final newStatus = connectivityResult != ConnectivityResult.none;
    if (newStatus != _isOnline) {
      _isOnline = newStatus;
      notifyListeners();
    }
  }

  // Appeler cette méthode régulièrement ou à l'initialisation
  Future<void> startMonitoring() async {
    await checkConnection();
    Connectivity().onConnectivityChanged.listen((result) {
      checkConnection();
    });
  }
}
