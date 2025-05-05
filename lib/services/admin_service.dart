import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'adminpanle';

  // Add a new movie
  Future<String> addMovie(MovieModel movie) async {
    try {
      final docRef =
          await _firestore.collection(collectionName).add(movie.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to add movie: $e';
    }
  }

  // Update an existing movie
  Future<void> updateMovie(MovieModel movie) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(movie.id)
          .update(movie.toMap());
    } catch (e) {
      throw 'Failed to update movie: $e';
    }
  }

  // Delete a movie
  Future<void> deleteMovie(String movieId) async {
    try {
      await _firestore.collection(collectionName).doc(movieId).delete();
    } catch (e) {
      throw 'Failed to delete movie: $e';
    }
  }

  // Get movies by category
  Stream<List<MovieModel>> getMoviesByCategory(String category) {
    return _firestore
        .collection(collectionName)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MovieModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all movies
  Stream<List<MovieModel>> getAllMovies() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MovieModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
