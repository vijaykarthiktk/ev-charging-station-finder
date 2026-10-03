/// A user rating + comment for a station.
class Review {
  const Review({
    required this.id,
    required this.stationId,
    required this.rating,
    required this.comment,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String stationId;

  /// 1–5 stars.
  final int rating;
  final String comment;
  final String author;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationId': stationId,
        'rating': rating,
        'comment': comment,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        stationId: json['stationId'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String? ?? '',
        author: json['author'] as String? ?? 'EV Driver',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
