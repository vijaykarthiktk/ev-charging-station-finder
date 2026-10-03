import 'package:postgres/postgres.dart';

import '../core/errors/app_exception.dart';
import '../models/review.dart';

abstract class ReviewsRepository {
  Future<List<Review>> fetchReviews(String stationId);
  Future<Review> addReview({
    required String stationId,
    required int rating,
    required String comment,
    required String author,
  });
}

class PostgresReviewsRepository implements ReviewsRepository {
  PostgresReviewsRepository(this._connection);
  final Future<Connection> _connection;

  Future<Result> _run(String sql,
      [Map<String, dynamic>? params]) async {
    try {
      final conn = await _connection;
      if (params == null) return await conn.execute(sql);
      return await conn.execute(Sql.named(sql), parameters: params);
    } catch (_) {
      throw const StorageException();
    }
  }

  Review _row(Map<String, dynamic> m) => Review(
        id: m['id'] as String,
        stationId: m['station_id'] as String,
        rating: m['rating'] as int,
        comment: m['comment'] as String? ?? '',
        author: m['author'] as String? ?? 'EV Driver',
        createdAt: (m['created_at'] as DateTime).toLocal(),
      );

  @override
  Future<List<Review>> fetchReviews(String stationId) async {
    final result = await _run(
      'SELECT * FROM reviews WHERE station_id = @id '
      'ORDER BY created_at DESC',
      {'id': stationId},
    );
    return result.map((row) => _row(row.toColumnMap())).toList();
  }

  @override
  Future<Review> addReview({
    required String stationId,
    required int rating,
    required String comment,
    required String author,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const BookingValidationException('Please select a star rating.');
    }
    final review = Review(
      id: 'RV-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      stationId: stationId,
      rating: rating,
      comment: comment.trim(),
      author: author.trim().isEmpty ? 'EV Driver' : author.trim(),
      createdAt: DateTime.now(),
    );
    await _run(
      'INSERT INTO reviews (id, station_id, rating, comment, author, '
      'created_at) VALUES (@id, @station_id, @rating, @comment, '
      '@author, @created_at)',
      {
        'id': review.id,
        'station_id': review.stationId,
        'rating': review.rating,
        'comment': review.comment,
        'author': review.author,
        'created_at': review.createdAt,
      },
    );
    return review;
  }
}
