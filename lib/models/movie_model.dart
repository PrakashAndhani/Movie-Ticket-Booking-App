import 'package:cloud_firestore/cloud_firestore.dart';

class MovieModel {
  final String id;
  final String title;
  final String posterUrl;
  final String description;
  final String category; // 'upcoming', 'trending', 'now_running'
  final double rating;
  final String duration;
  final String releaseDate;

  MovieModel({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.description,
    required this.category,
    required this.rating,
    required this.duration,
    required this.releaseDate,
  });

  factory MovieModel.fromMap(Map<String, dynamic> map, String id) {
    return MovieModel(
      id: id,
      title: map['title'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      duration: map['duration'] ?? '',
      releaseDate: map['releaseDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'posterUrl': posterUrl,
      'description': description,
      'category': category,
      'rating': rating,
      'duration': duration,
      'releaseDate': releaseDate,
    };
  }
}
