import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/review_service.dart';

class HikeDetailsScreen extends StatefulWidget {
  final Hike hike;

  const HikeDetailsScreen({super.key, required this.hike});

  @override
  State<HikeDetailsScreen> createState() => _HikeDetailsScreenState();
}

class _HikeDetailsScreenState extends State<HikeDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  late Future<double> _averageRatingFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final reviewService = context.read<ReviewService>();
    setState(() {
      _reviewsFuture = reviewService.getReviewsForHike(widget.hike.id);
      _averageRatingFuture = reviewService.getAverageRatingForHike(
        widget.hike.id,
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _isSubmitting) return;

    final authService = context.read<AuthService>();
    final reviewService = context.read<ReviewService>();

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez être connecté pour commenter"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await reviewService.addReview(
        hikeId: widget.hike.id,
        userId: int.parse(authService.currentUser!.id),
        rating: _rating,
        comment:
            _commentController.text.isNotEmpty ? _commentController.text : null,
      );

      _commentController.clear();
      _rating = 0;
      _refreshData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Merci pour votre avis !')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hike.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image et métadonnées
                  _buildHikeHeader(theme),
                  const SizedBox(height: 24),

                  // Description
                  _buildDescriptionSection(theme),
                  const SizedBox(height: 24),

                  // Section avis
                  _buildReviewsHeader(theme),
                ],
              ),
            ),
          ),

          // Note moyenne
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildAverageRating(theme),
            ),
          ),

          // Formulaire d'avis
          if (authService.isAuthenticated)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildReviewForm(theme),
              ),
            ),

          // Liste des commentaires
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildReviewsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHikeHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hike.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              widget.hike.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),

        Text(
          widget.hike.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${widget.hike.location}, ${widget.hike.wilaya}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Métriques
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(Icons.straighten, '${widget.hike.distance} km'),
            _buildMetricItem(Icons.timer, '${widget.hike.duration} h'),
            _buildMetricItem(Icons.terrain, widget.hike.difficulty),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(widget.hike.description, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildReviewsHeader(ThemeData theme) {
    return Text(
      'Avis et Commentaires',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAverageRating(ThemeData theme) {
    return FutureBuilder<double>(
      future: _averageRatingFuture,
      builder: (context, snapshot) {
        final avgRating = snapshot.data ?? 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Text('Note moyenne: ', style: theme.textTheme.bodyMedium),
              Text(
                avgRating > 0
                    ? avgRating.toStringAsFixed(1)
                    : 'Pas encore noté',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildStarRating(avgRating, false),
              Text(
                ' (${snapshot.hasData ? _getRatingCountText() : '...'})',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donnez votre avis',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Sélection de la note
        Center(child: _buildRatingStars()),
        const SizedBox(height: 16),

        // Champ de commentaire
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Votre commentaire (optionnel)',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 16),

        // Bouton d'envoi
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReview,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Envoyer mon avis'),
          ),
        ),
        const Divider(height: 40),
      ],
    );
  }

  Widget _buildReviewsList(ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Erreur de chargement des avis ',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Aucun commentaire pour le moment',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildReviewCard(reviews[index], theme),
            childCount: reviews.length,
          ),
        );
      },
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
    );
  }

  Widget _buildStarRating(double rating, bool interactive) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 20),
        if (hasHalfStar)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < 5 - fullStars - (hasHalfStar ? 1 : 0); i++)
          const Icon(Icons.star_border, color: Colors.amber, size: 20),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review['user_name'] ?? 'Anonyme',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStarRating(review['rating'].toDouble(), false),
              ],
            ),
            const SizedBox(height: 8),
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              Text(review['comment'], style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text(
              _formatDate(review['created_at']?.toString()),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getRatingCountText() {
    // Implémentez la logique réelle de comptage ici
    return 'basé sur plusieurs avis';
  }
}
