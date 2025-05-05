import 'package:cloud_firestore/cloud_firestore.dart';

class TestCoupon {
  static Future<void> addTestCoupon() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      // First check if the coupon already exists
      var existingCoupons = await _firestore
          .collection('Coupon Code')
          .where('code', isEqualTo: 'FIRST50')
          .get();

      if (existingCoupons.docs.isEmpty) {
        // Add test coupon if it doesn't exist
        await _firestore.collection('Coupon Code').add({
          'code': 'FIRST50',
          'discountPercentage': 50,
          'validFrom': DateTime.now().toIso8601String(),
          'validUntil':
              DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'isActive': true,
          'maxUses': 100,
          'currentUses': 0,
          'minPurchaseAmount': 200.0,
        });
        print('Test coupon FIRST50 added successfully!');
      } else {
        print('Test coupon FIRST50 already exists!');
      }
    } catch (e) {
      print('Error adding test coupon: $e');
    }
  }
}
