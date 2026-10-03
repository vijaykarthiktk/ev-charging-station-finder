import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../repositories/reviews_repository.dart';
import 'repository_providers.dart';

/// Reviews + rating summary per station, backed by Postgres.
final reviewsRepositoryProvider = Provider(
  (ref) => PostgresReviewsRepository(ref.watch(pgConnectionProvider)),
);

final stationReviewsProvider =
    FutureProvider.family<List<Review>, String>(
  (ref, stationId) =>
      ref.watch(reviewsRepositoryProvider).fetchReviews(stationId),
);

/// (average stars, review count); (0, 0) when unreviewed.
final reviewSummaryProvider =
    Provider.family<({double avg, int count}), String>(
  (ref, stationId) {
    final reviews = ref.watch(stationReviewsProvider(stationId)).value ?? [];
    if (reviews.isEmpty) return (avg: 0.0, count: 0);
    final sum = reviews.fold<int>(0, (a, r) => a + r.rating);
    return (avg: sum / reviews.length, count: reviews.length);
  },
);

/// Submits a review, then refreshes the station's list + summary.
class ReviewController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> submit({
    required String stationId,
    required int rating,
    required String comment,
    required String author,
  }) async {
    state = const AsyncLoading();
    final outcome = await AsyncValue.guard(() async {
      await ref.read(reviewsRepositoryProvider).addReview(
            stationId: stationId,
            rating: rating,
            comment: comment,
            author: author,
          );
      ref.invalidate(stationReviewsProvider(stationId));
    });
    state = outcome;
    if (outcome.hasError) throw outcome.error!;
  }
}

final reviewControllerProvider =
    NotifierProvider<ReviewController, AsyncValue<void>>(
        ReviewController.new);
