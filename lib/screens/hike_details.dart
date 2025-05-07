// hike_details.dart
import 'package:flutter/material.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/weather_service.dart';

class HikeDetailsScreen extends StatefulWidget {
  final Hike hike;

  const HikeDetailsScreen({super.key, required this.hike});

  @override
  State<HikeDetailsScreen> createState() => _HikeDetailsScreenState();
}

class _HikeDetailsScreenState extends State<HikeDetailsScreen> {
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _forecastData;
  bool _isLoading = false;
  bool _isLoadingForecast = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);
    try {
    final weather = await WeatherService.getWeather(
  widget.hike.coordinates!.latitude,
  widget.hike.coordinates!.longitude,
);
      setState(() => _weatherData = weather);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger la météo: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadForecast() async {
    setState(() => _isLoadingForecast = true);
    try {
      final forecast = await WeatherService.getWeatherForecast(
        widget.hike.coordinates!.latitude,
        widget.hike.coordinates!.longitude,
      );
      setState(() => _forecastData = forecast);
      _showForecastDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les prévisions: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingForecast = false);
    }
  }

  void _showForecastDialog() {
    if (_forecastData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévisions météo'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildForecastList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    if (_forecastData == null || _forecastData!['list'] == null) {
      return const Center(child: Text('Aucune donnée de prévision disponible'));
    }

    final forecasts = _forecastData!['list'] as List;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: forecasts.length > 5 ? 5 : forecasts.length, // Limiter à 5 prévisions
      itemBuilder: (context, index) {
        final forecast = forecasts[index];
        final weather = forecast['weather'][0];
        final main = forecast['main'];
        final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);

        return ListTile(
          leading: Text(
            WeatherService.getWeatherIcon(weather['main']),
            style: const TextStyle(fontSize: 24),
          ),
          title: Text('${date.hour}h - ${weather['description']}'),
          subtitle: Text('${main['temp'].round()}°C (${main['humidity']}% humidité)'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hike.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _isLoadingForecast ? null : _loadForecast,
            tooltip: 'Voir les prévisions météo',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hike.imageUrl != null) 
              Image.network(widget.hike.imageUrl!),
            
            // Section Météo actuelle
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Météo actuelle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildWeatherInfo(),
                  ],
                ),
              ),
            ),

            // Reste des détails de la randonnée
            Text(
              widget.hike.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // ... (le reste de votre code existant)
          ],
        ),
      ),
    );
  }

 Widget _buildWeatherInfo() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_weatherData == null) {
    return const Text('Données météo non disponibles');
  }

  final weather = _weatherData!['weather'][0];
  final main = _weatherData!['main'];

  return Row(
    children: [
      Text(
        WeatherService.getWeatherIcon(weather['main']),
        style: const TextStyle(fontSize: 40),
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weather['description'],
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '${main['temp'].round()}°C (Ressenti ${main['feels_like'].round()}°C)',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Vent: ${_weatherData!['wind']['speed']} m/s',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ],
  );
} 
}