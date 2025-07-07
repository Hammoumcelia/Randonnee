import 'package:flutter/foundation.dart';
import 'package:randonnee/services/database_service.dart';

class ReviewService with ChangeNotifier {
  final DatabaseService _dbService;

  ReviewService(this._dbService);

  Future<int> addReview({
    required String hikeId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    try {
      // Vérifiez d'abord que l'utilisateur existe
      final user = await _dbService.getUserById(userId);
      if (user == null) throw Exception('Utilisateur non trouvé');

      // Vérifiez que la randonnée existe
      final hike = await _dbService.getHikeById(hikeId);
      if (hike == null) throw Exception('Randonnée non trouvée');

      final review = {
        'hike_id': hikeId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      };

      final id = await _dbService.addHikeReview(review);
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du commentaire: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForHike(String hikeId) async {
    try {
      final db = await _dbService.db;
      final reviews = await db.rawQuery(
        '''
      SELECT r.*, u.name as user_name 
      FROM hike_reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.hike_id = ?
      ORDER BY r.created_at DESC
      ''',
        [hikeId],
      );

      // Debug: affiche les commentaires récupérés
      debugPrint('Commentaires récupérés pour hike $hikeId: $reviews');

      return reviews;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des commentaires: $e');
      rethrow;
    }
  }

  Future<double> getAverageRatingForHike(String hikeId) async {
    try {
      return await _dbService.getAverageRating(hikeId);
    } catch (e) {
      debugPrint('Erreur lors du calcul de la note moyenne: $e');
      rethrow;
    }
  }

  // nombres de commentaires
  Future<int> getReviewCount(String hikeId) async {
    try {
      final db = await _dbService.db;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM hike_reviews WHERE hike_id = ?',
        [hikeId],
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('Erreur lors du comptage des avis: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getHikeRatingSummary(String hikeId) async {
    try {
      final db = await _dbService.db;
      final result = await db.rawQuery(
        '''
      SELECT 
        AVG(rating) as average,
        COUNT(*) as count
      FROM hike_reviews 
      WHERE hike_id = ?
    ''',
        [hikeId],
      );

      return {
        'average': (result.first['average'] as num?)?.toDouble() ?? 0.0,
        'count': result.first['count'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du résumé des avis: $e');
      return {'average': 0.0, 'count': 0};
    }
  }
}
