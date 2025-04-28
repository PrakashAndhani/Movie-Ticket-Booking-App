import 'package:application/page/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'BookingPage.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, String>> movies = [
    {
      "title": "Infinity",
      "image": "images/infinity.jpg",
      "genre": "Sci-Fi, Action"
    },
    {"title": "Stree", "image": "images/stree.jpg", "genre": "Horror, Comedy"},
    {"title": "Thor", "image": "images/thor.jpg", "genre": "Action, Fantasy"},
  ];

  final List<String> sliderImages = [
    "images/infinity.jpg",
    "images/stree.jpg",
    "images/thor.jpg"
  ];

  int _currentIndex = 0;

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset("images/wave.png", height: 40, width: 40),
                    const SizedBox(width: 10.0),
                    const Text(
                      "Hello Abc",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset("images/download (2).jpeg",
                          height: 50, width: 50, fit: BoxFit.cover),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                const Text("Welcome to",
                    style: TextStyle(color: Colors.white70, fontSize: 22.0)),
                Row(
                  children: const [
                    Text("Filmy",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36.0,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 5.0),
                    Text("Fun",
                        style: TextStyle(
                            color: Color(0xffedb41d),
                            fontSize: 36.0,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20.0),
                CarouselSlider(
                  items: sliderImages
                      .map((url) => ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(url, fit: BoxFit.cover),
                          ))
                      .toList(),
                  options: CarouselOptions(
                    height: 250,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                  ),
                ),
                const SizedBox(height: 25.0),
                sectionTitle("Top Trending Movies"),
                const SizedBox(height: 15.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: movies.map((movie) {
                      return buildMovieCard(
                        title: movie["title"]!,
                        imagePath: movie["image"]!,
                        genre: movie["genre"]!,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => LoginScreen()));
          } else {
            setState(() => _currentIndex = index);
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xffedb41d),
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.movie_creation), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildMovieCard(
      {required String title,
      required String imagePath,
      required String genre}) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(imagePath,
                  height: 210, width: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 5.0),
            Text(genre,
                style: const TextStyle(color: Colors.white70, fontSize: 16.0)),
            const SizedBox(height: 5.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffedb41d),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SeatBookingScreen(movieTitle: title)),
                  );
                },
                child: const Text("Book Now",
                    style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeatBookingScreen extends StatefulWidget {
  final String movieTitle;
  const SeatBookingScreen({super.key, required this.movieTitle});

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
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
  final List<String> seatLabels = [
    for (var row in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'])
      for (var col in List.generate(12, (i) => i + 1)) "$row$col"
  ];
  String selectedDate = "Dec 10";
  final int seatPrice = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Select seat - ${widget.movieTitle}"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "SCREEN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Seat Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: GridView.builder(
                shrinkWrap: true, // Prevents scrolling issues
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 12,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1.2,
                ),
                itemCount: seatLabels.length,
                itemBuilder: (context, index) {
                  String seat = seatLabels[index];
                  bool isSelected = selectedSeats.contains(seat);
                  bool isBooked = bookedSeats.contains(seat);

                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                selectedSeats.remove(seat);
                              } else {
                                selectedSeats.add(seat);
                              }
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.white
                            : isSelected
                                ? Colors.orange
                                : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          seat,
                          style: TextStyle(
                            color: isBooked ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ["Dec 08", "Dec 09", "Dec 10", "Dec 11", "Dec 12"]
                      .map((date) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: ChoiceChip(
                              label: Text(date),
                              selected: selectedDate == date,
                              onSelected: (selected) {
                                setState(() {
                                  selectedDate = date;
                                });
                              },
                              selectedColor: Colors.orange,
                              backgroundColor: Colors.grey.shade800,
                              labelStyle: TextStyle(
                                color: selectedDate == date
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            // Total Price & Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    "Total: ${selectedSeats.length * seatPrice} Rs.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedSeats.isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Booking Confirmed! Seats: ${selectedSeats.join(", ")}"),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Book Ticket",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
