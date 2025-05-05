class BookingModel {
  final String userId;
  final String movieTitle;
  final String date;
  final String time;
  final List<String> seats;
  final int totalAmount;
  final String bookingId;
  final String userName;
  final DateTime bookingTime;

  BookingModel({
    required this.userId,
    required this.movieTitle,
    required this.date,
    required this.time,
    required this.seats,
    required this.totalAmount,
    required this.bookingId,
    required this.userName,
    required this.bookingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'movieTitle': movieTitle,
      'date': date,
      'time': time,
      'seats': seats,
      'totalAmount': totalAmount,
      'bookingId': bookingId,
      'userName': userName,
      'bookingTime': bookingTime.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      userId: map['userId'] ?? '',
      movieTitle: map['movieTitle'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      seats: List<String>.from(map['seats'] ?? []),
      totalAmount: map['totalAmount']?.toInt() ?? 0,
      bookingId: map['bookingId'] ?? '',
      userName: map['userName'] ?? '',
      bookingTime: DateTime.parse(map['bookingTime']),
    );
  }
}
