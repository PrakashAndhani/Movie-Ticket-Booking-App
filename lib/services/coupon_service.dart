import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CouponModel?> validateCoupon(String code, double amount) async {
    try {
      final couponDoc = await _firestore
          .collection('Coupon Code')
          .where('code', isEqualTo: code)
          .get();

      if (couponDoc.docs.isEmpty) {
        throw 'Invalid coupon code';
      }

      final couponData = couponDoc.docs.first.data();
      final coupon = CouponModel.fromMap(couponData);

      // Validate coupon
      final now = DateTime.now();
      if (!coupon.isActive) {
        throw 'Coupon is not active';
      }
      if (now.isBefore(coupon.validFrom)) {
        throw 'Coupon is not yet valid';
      }
      if (now.isAfter(coupon.validUntil)) {
        throw 'Coupon has expired';
      }
      if (coupon.maxUses != null &&
          coupon.currentUses != null &&
          coupon.currentUses! >= coupon.maxUses!) {
        throw 'Coupon usage limit exceeded';
      }
      if (coupon.minPurchaseAmount != null &&
          amount < coupon.minPurchaseAmount!) {
        throw 'Minimum purchase amount not met';
      }

      return coupon;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final couponRef = _firestore
          .collection('Coupon Code')
          .where('code', isEqualTo: code)
          .limit(1);

      final couponDoc = await couponRef.get();
      if (couponDoc.docs.isEmpty) return;

      await _firestore.runTransaction((transaction) async {
        final docRef = couponDoc.docs.first.reference;
        final couponData = couponDoc.docs.first.data();

        if (couponData['currentUses'] != null) {
          transaction.update(
              docRef, {'currentUses': (couponData['currentUses'] as int) + 1});
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  double calculateDiscountedAmount(
      double originalAmount, int discountPercentage) {
    final discount = (originalAmount * discountPercentage) / 100;
    return originalAmount - discount;
  }
}
