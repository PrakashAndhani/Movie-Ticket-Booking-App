import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  final List<String> bookedMovies;
  const BookingPage({super.key, required this.bookedMovies});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final List<Map<String, String>> movies = [
    {"title": "Avatar 2", "image": "images/avatar2.jpg", "genre": "Sci-Fi"},
    {"title": "Joker", "image": "images/joker.jpg", "genre": "Drama"},
    {
      "title": "Inception",
      "image": "images/inception.jpg",
      "genre": "Thriller"
    },
  ];

  List<String> bookedMovies = [];

  @override
  void initState() {
    super.initState();
    bookedMovies = widget.bookedMovies;
  }

  void bookMovie(String movieTitle) {
    setState(() {
      bookedMovies.add(movieTitle);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$movieTitle booked successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Book Your Movie"),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return movieCard(movie);
        },
      ),
    );
  }

  Widget movieCard(Map<String, String> movie) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(movie["image"]!,
              height: 80, width: 60, fit: BoxFit.cover),
        ),
        title:
            Text(movie["title"]!, style: const TextStyle(color: Colors.white)),
        subtitle: Text(movie["genre"]!,
            style: const TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => bookMovie(movie["title"]!),
          child: const Text("Book"),
        ),
      ),
    );
  }
}
