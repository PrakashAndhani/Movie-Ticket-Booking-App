class CouponModel {
  final String code;
  final int discountPercentage;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final int? maxUses;
  final int? currentUses;
  final double? minPurchaseAmount;

  CouponModel({
    required this.code,
    required this.discountPercentage,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.maxUses,
    this.currentUses,
    this.minPurchaseAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercentage': discountPercentage,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'isActive': isActive,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'minPurchaseAmount': minPurchaseAmount,
    };
  }

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    return CouponModel(
      code: map['code'] ?? '',
      discountPercentage: map['discountPercentage']?.toInt() ?? 0,
      validFrom: DateTime.parse(map['validFrom']),
      validUntil: DateTime.parse(map['validUntil']),
      isActive: map['isActive'] ?? false,
      maxUses: map['maxUses']?.toInt(),
      currentUses: map['currentUses']?.toInt(),
      minPurchaseAmount: map['minPurchaseAmount']?.toDouble(),
    );
  }
}
