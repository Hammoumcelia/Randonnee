import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class SOSService {
  final Nearby _nearby = Nearby();
  final StreamController<String> _messageStream = StreamController.broadcast();
  bool _isInitialized = false;
  String? _currentEndpointId;

  // Déclaration du callback pour onEndpointLost
  void Function(String) get _onEndpointLostCallback => (String endpointId) {
    if (kDebugMode) {
      debugPrint("Endpoint lost: $endpointId");
    }
  };

  Stream<String> get messageStream => _messageStream.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint("Service Nearby prêt");
    } catch (e) {
      debugPrint("Erreur initialisation Nearby: $e");
      _isInitialized = false;
      rethrow;
    }
  }

  Future<bool> sendSOSMessage(BuildContext context) async {
    try {
      if (!_isInitialized) await initialize();

      final position = await _getCurrentPositionWithFallback();
      if (position == null) throw Exception("Impossible d'obtenir la position");

      final message = _createSOSMessage(position);
      return await _sendViaNearby(message);
    } catch (e) {
      debugPrint("Erreur envoi SOS: $e");
      rethrow;
    }
  }

  Future<bool> sendVoiceSOS(BuildContext context) async {
    try {
      if (!_isInitialized) await initialize();

      final audioPath = await _recordVoiceMessage();
      if (audioPath == null) return false;

      final position = await _getCurrentPositionWithFallback();
      if (position == null) throw Exception("Impossible d'obtenir la position");

      final message = _createSOSMessage(position);
      return await _sendViaNearby(message, audioPath: audioPath);
    } catch (e) {
      debugPrint("Erreur envoi vocal SOS: $e");
      rethrow;
    }
  }

  Future<void> callEmergency(BuildContext context) async {
    const phoneNumber = 'tel:112';
    try {
      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
        await launchUrl(Uri.parse(phoneNumber));
      } else {
        throw "Impossible d'ouvrir l'application téléphone";
      }
    } catch (e) {
      debugPrint("Erreur appel urgence: $e");
      rethrow;
    }
  }

  Future<bool> _sendViaNearby(String message, {String? audioPath}) async {
    try {
      // Start Advertising
      await _nearby.startAdvertising(
        "RandoSOS",
        Strategy.P2P_STAR,
        onConnectionInitiated: (String endpointId, ConnectionInfo info) {
          _handleConnectionInitiated(endpointId, info);
        },
        onConnectionResult: (String endpointId, Status status) {
          debugPrint("Connection result: $status");
          if (status == Status.CONNECTED) {
            _currentEndpointId = endpointId;
          }
        },
        onDisconnected: (String endpointId) {
          debugPrint("Disconnected: $endpointId");
          if (_currentEndpointId == endpointId) {
            _currentEndpointId = null;
          }
        },
      );

      // Start Discovery
      await _nearby.startDiscovery(
        "RandoSOS",
        Strategy.P2P_STAR,
        onEndpointFound: (
          String endpointId,
          String serviceId,
          String endpointName,
        ) {
          debugPrint("Endpoint found: $endpointName");
          _nearby.requestConnection(
            "RandoSOS",
            endpointId,
            onConnectionInitiated: (String endpointId, ConnectionInfo info) {
              _handleConnectionInitiated(endpointId, info);
            },
            onConnectionResult: (String endpointId, Status status) {
              debugPrint("Connection result: $status");
              if (status == Status.CONNECTED) {
                _currentEndpointId = endpointId;
              }
            },
            onDisconnected: (String endpointId) {
              debugPrint("Disconnected: $endpointId");
              if (_currentEndpointId == endpointId) {
                _currentEndpointId = null;
              }
            },
          );
        },
        onEndpointLost:
            (String endpointId) {
                  if (kDebugMode) {
                    debugPrint("Endpoint lost: $endpointId");
                  }
                }
                as OnEndpointLost,
      );

      // Wait for connection
      await Future.delayed(const Duration(seconds: 10));
      if (_currentEndpointId == null) return false;

      // Send message
      await _nearby.sendBytesPayload(
        _currentEndpointId!,
        Uint8List.fromList(message.codeUnits),
      );

      // Send audio if exists
      if (audioPath != null && File(audioPath).existsSync()) {
        await _nearby.sendFilePayload(_currentEndpointId!, audioPath);
      }

      return true;
    } catch (e) {
      debugPrint("Erreur Nearby: $e");
      return false;
    } finally {
      await _cleanupNearby();
    }
  }

  void _handleConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint("Connection initiated with ${info.endpointName}");
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (String endpointId, Payload payload) async {
        if (payload.type == PayloadType.BYTES) {
          final message = String.fromCharCodes(payload.bytes!);
          _messageStream.add(message);
          debugPrint("Message received: $message");
        }
      },
      onPayloadTransferUpdate: (
        String endpointId,
        PayloadTransferUpdate update,
      ) {
        debugPrint("Transfer update: $update");
      },
    );
  }

  Future<void> _cleanupNearby() async {
    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      if (_currentEndpointId != null) {
        await _nearby.disconnectFromEndpoint(_currentEndpointId!);
      }
    } catch (e) {
      debugPrint("Erreur nettoyage Nearby: $e");
    }
  }

  Future<Position?> _getCurrentPositionWithFallback() async {
    try {
      final hasPermission = await Permission.location.request().isGranted;
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      debugPrint("Erreur position actuelle: $e");
      return await Geolocator.getLastKnownPosition();
    }
  }

  String _createSOSMessage(Position position) {
    return "URGENCE RANDONNÉE!\n\n"
        "Je suis en danger et besoin d'aide immédiate.\n"
        "Position: https://www.google.com/maps?q=${position.latitude},${position.longitude}\n"
        "Altitude: ${position.altitude.toStringAsFixed(1)}m\n"
        "Précision: ~${position.accuracy.toStringAsFixed(0) ?? 'N/A'}m\n\n"
        "Merci de prévenir les secours!";
  }

  Future<String?> _recordVoiceMessage() async {
    final recorder = FlutterSoundRecorder();
    try {
      if (!await Permission.microphone.isGranted) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) return null;
      }

      await recorder.openRecorder();

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sos_audio.aac';

      await recorder.startRecorder(toFile: path, codec: Codec.aacADTS);

      await Future.delayed(const Duration(seconds: 10));

      await recorder.stopRecorder();
      return path;
    } catch (e) {
      debugPrint("Erreur enregistrement: $e");
      return null;
    } finally {
      await recorder.closeRecorder();
    }
  }

  void dispose() {
    _messageStream.close();
    _cleanupNearby();
  }
}
