import 'package:cloud_firestore/cloud_firestore.dart';

// Example of how to add a coupon to Firestore
Future<void> addExampleCoupon() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Example coupon data
  final couponData = {
    'code': 'FIRST50', // કૂપન કોડ
    'discountPercentage': 50, // ડિસ્કાઉન્ટ પર્સેન્ટેજ (અહીં 50% છે)
    'validFrom': DateTime.now().toIso8601String(), // આજથી વેલિડ
    'validUntil': DateTime.now()
        .add(Duration(days: 30))
        .toIso8601String(), // 30 દિવસ સુધી વેલિડ
    'isActive': true, // કૂપન એક્ટિવ છે
    'maxUses': 100, // મહત્તમ 100 વાર વાપરી શકાય
    'currentUses': 0, // હાલમાં 0 વાર વપરાયો છે
    'minPurchaseAmount': 200.0, // મિનિમમ ખરીદી ₹200
  };

  // Add coupon to Firestore
  await _firestore.collection('Coupon Code').add(couponData);
}
