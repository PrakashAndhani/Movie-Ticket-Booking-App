import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createBooking({
    required String movieTitle,
    required String date,
    required String time,
    required List<String> seats,
    required int totalAmount,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      // Create a new document reference with auto-generated ID
      final docRef = _firestore.collection('movieticket').doc();

      final booking = {
        'userId': user.uid,
        'movieTitle': movieTitle,
        'date': date,
        'time': time,
        'seats': seats,
        'totalAmount': totalAmount,
        'bookingId': docRef.id,
        'userName': user.displayName ?? 'Anonymous',
        'bookingTime': DateTime.now(),
      };

      // Save booking to Firestore
      await docRef.set(booking);

      // Also save in user's bookings subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .doc(docRef.id)
          .set(booking);

      return docRef.id;
    } catch (e) {
      throw 'Failed to create booking: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .orderBy('bookingTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw 'Failed to fetch bookings: $e';
    }
  }

  Future<bool> checkSeatAvailability(
      String movieTitle, String date, String time, List<String> seats) async {
    try {
      final querySnapshot = await _firestore
          .collection('movieticket')
          .where('movieTitle', isEqualTo: movieTitle)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      // Check if any of the selected seats are already booked
      for (var doc in querySnapshot.docs) {
        List<String> bookedSeats = List<String>.from(doc.data()['seats']);
        if (seats.any((seat) => bookedSeats.contains(seat))) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw 'Failed to check seat availability: $e';
    }
  }
}
