import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/booking_service.dart';
import '../services/coupon_service.dart';
import '../models/coupon_model.dart';
import '../config/razorpay_config.dart';
import '../services/test_coupon.dart';

class SeatBookingScreen extends StatefulWidget {
  final String movieTitle;

  const SeatBookingScreen({Key? key, required this.movieTitle})
      : super(key: key);

  @override
  _SeatBookingScreenState createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  final BookingService _bookingService = BookingService();
  final CouponService _couponService = CouponService();
  bool _isLoading = false;
  late Razorpay _razorpay;
  List<String> selectedSeats = [];
  final List<String> bookedSeats = [
    "D7",
    "D8",
    "D9",
    "E7",
    "E8",
    "E9",
    "H7",
    "H8"
  ];
  String selectedDate = "Dec 10";
  String selectedTime = "6:30 PM";
  final int seatPrice = 200;

  // Add these variables for coupon handling
  final TextEditingController _couponController = TextEditingController();
  CouponModel? _appliedCoupon;
  String? _couponError;
  double _discountedAmount = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Add test coupon when screen loads
    _addTestCoupon();
  }

  Future<void> _addTestCoupon() async {
    await TestCoupon.addTestCoupon();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Create the booking in Firestore
      final bookingId = await _bookingService.createBooking(
        movieTitle: widget.movieTitle,
        date: selectedDate,
        time: selectedTime,
        seats: selectedSeats,
        totalAmount: _appliedCoupon != null
            ? _discountedAmount.toInt()
            : selectedSeats.length * seatPrice,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking confirmed! Booking ID: $bookingId',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back to previous screen after successful booking
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to complete booking: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed: ${response.message ?? "Error occurred"}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName}',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _validateAndApplyCoupon() async {
    setState(() {
      _couponError = null;
      _appliedCoupon = null;
      _discountedAmount = 0;
    });

    if (_couponController.text.isEmpty) {
      setState(() {
        _couponError = 'Please enter a coupon code';
      });
      return;
    }

    try {
      final originalAmount = selectedSeats.length * seatPrice.toDouble();
      final coupon = await _couponService.validateCoupon(
        _couponController.text,
        originalAmount,
      );

      if (coupon != null) {
        setState(() {
          _appliedCoupon = coupon;
          _discountedAmount = _couponService.calculateDiscountedAmount(
            originalAmount,
            coupon.discountPercentage,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon applied successfully! ${coupon.discountPercentage}% off',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _couponError = e.toString();
      });
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool seatsAvailable = await _bookingService.checkSeatAvailability(
        widget.movieTitle,
        selectedDate,
        selectedTime,
        selectedSeats,
      );

      if (!seatsAvailable) {
        throw 'Selected seats are no longer available';
      }

      // Calculate final amount
      int amountInPaise = (selectedSeats.length * seatPrice * 100).toInt();
      if (_appliedCoupon != null) {
        amountInPaise = (_discountedAmount * 100).toInt();
      }

      // Create Razorpay order
      var options = {
        'key': RazorpayConfig.keyId,
        'amount': amountInPaise,
        'name': 'Filmy Fun',
        'description': 'Movie: ${widget.movieTitle}',
        'prefill': {
          'contact': '7041972862',
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      // If coupon is applied, update its usage count
      if (_appliedCoupon != null) {
        await _couponService.applyCoupon(_appliedCoupon!.code);
      }

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply Coupon Code',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: GoogleFonts.poppins(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _couponError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _validateAndApplyCoupon();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffedb41d),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Seats - ${widget.movieTitle}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Screen indicator
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 40),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.panorama_wide_angle_outlined,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "SCREEN",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Seats Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Premium Section
                      Text(
                        "PREMIUM - ₹250",
                        style: GoogleFonts.poppins(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: 32,
                        itemBuilder: (context, index) {
                          String seatNumber = 'P${index + 1}';
                          bool isSelected = selectedSeats.contains(seatNumber);
                          bool isBooked = bookedSeats.contains(seatNumber);

                          return GestureDetector(
                            onTap: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedSeats.remove(seatNumber);
                                      } else {
                                        selectedSeats.add(seatNumber);
                                      }
                                    });
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.grey
                                    : isSelected
                                        ? const Color(0xffedb41d)
                                        : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  seatNumber,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Regular Section
                      Text(
                        "REGULAR - ₹200",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: 40,
                        itemBuilder: (context, index) {
                          String seatNumber = 'R${index + 1}';
                          bool isSelected = selectedSeats.contains(seatNumber);
                          bool isBooked = bookedSeats.contains(seatNumber);

                          return GestureDetector(
                            onTap: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedSeats.remove(seatNumber);
                                      } else {
                                        selectedSeats.add(seatNumber);
                                      }
                                    });
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.grey
                                    : isSelected
                                        ? const Color(0xffedb41d)
                                        : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  seatNumber,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selectedSeats.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Selected Seats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Selected Seats:",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                selectedSeats.join(", "),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Coupon Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Have a coupon code?",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _showCouponBottomSheet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffedb41d),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        color: _appliedCoupon != null
                                            ? Colors.green
                                            : Colors.black,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _appliedCoupon != null
                                            ? '${_appliedCoupon!.discountPercentage}% Discount Applied'
                                            : 'Apply Coupon Code',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Total Amount with Discount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount:",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_appliedCoupon != null)
                                    Text(
                                      "₹${selectedSeats.length * seatPrice}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 14,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    _appliedCoupon != null
                                        ? "₹${_discountedAmount.toStringAsFixed(2)}"
                                        : "₹${selectedSeats.length * seatPrice}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.amber,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Payment Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffedb41d),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : Text(
                                  'Proceed to Payment',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
