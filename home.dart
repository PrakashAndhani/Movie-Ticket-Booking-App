import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<String> imageUrls = [
    "images/infinity.jpg",
    "images/tiger.jpg",
    "images/stree.jpg"
  ];

  final List<String> movieTitles = [
    "Infinity Wars",
    "Tiger 3",
    "Stree 2",
  ];

  final List<String> movieGenres = [
    "Action, Adventure",
    "Action Thriller",
    "Comedy Horror",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  "images/prakash.jpg",
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 10, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Welcome to Filmy Fun" Section - First at the Top
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'images/hello.jpg',
                            height: 40, // Smaller image
                            width: 40, // Smaller image
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 10.0),
                          const Text(
                            "Hello Prakash,",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30.0, // Smaller text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Welcome To,",
                        style: TextStyle(
                          color: Color.fromARGB(186, 255, 255, 255),
                          fontSize: 16.0, // Smaller text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Filmy",
                            style: TextStyle(
                              color: Color(0xffedb41d),
                              fontSize: 24.0, // Smaller text
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Text(
                            "Fun",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0, // Smaller text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: CarouselSlider(
                  items: imageUrls.asMap().entries.map((entry) {
                    int index = entry.key;
                    String url = entry.value;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DetailPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(url, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 250,
                    autoPlay: false,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Top Trending Movies",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DetailPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.asset(
                                imageUrls[index],
                                height: 220,
                                width: 180,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(
                                      color: Colors.black45),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        movieTitles[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        movieGenres[index],
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                              173, 255, 255, 255),
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile App',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController mobileController = TextEditingController();
    TextEditingController otpController = TextEditingController();

    // Default OTP
    const String defaultOTP = "1234";

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: "Mobile Number"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String enteredOTP = otpController.text;

                if (enteredOTP == defaultOTP) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Login Successful!")),
                  );

                  // Navigate to HomePage after successful login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid OTP! Try again.")),
                  );
                }
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int quantity = 1; // Quantity tracking variable
  int selectedMovieIndex = 0; // Index to track the currently selected movie

  final List<Map<String, dynamic>> movies = [
    {
      'title': 'Infinity Wars',
      'image': 'images/infinity.jpg',
      'genre': 'Action, Adventure',
      'description':
          'The Avengers and their allies must be willing to sacrifice all in an attempt to defeat the powerful Thanos before his blitz of devastation and ruin puts an end to the universe.',
      'price': 550,
    },
    {
      'title': 'Tiger 3',
      'image': 'images/tiger.jpg',
      'genre': 'Action, Thrillers',
      'description':
          'The Avengers and their allies must be willing to sacrifice all in an attempt to defeat the powerful Thanos before his blitz of devastation and ruin puts an end to the universe.',
      'price': 550,
    },
    {
      'title': 'Stree 2',
      'image': 'images/stree.jpg',
      'genre': 'Action, Adventure',
      'description':
          'The Avengers and their allies must be willing to sacrifice all in an attempt to defeat the powerful Thanos before his blitz of devastation and ruin puts an end to the universe.',
      'price': 550,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final movie = movies[selectedMovieIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(movie['image']),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(movie['genre'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(
                    movie['description'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Fri 3")),
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Sat 4")),
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Sun 5")),
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Mon 5")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select Time Slot",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                            onPressed: () {}, child: const Text("08:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("10:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("06:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("07:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("08:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("09:00 PM")),
                        ElevatedButton(
                            onPressed: () {}, child: const Text("10:00 PM")),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (quantity > 1) quantity--;
                              });
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text("$quantity"),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Total : ${quantity * movie['price']}"),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("Book Now"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedMovieIndex,
        onTap: (index) {
          setState(() {
            selectedMovieIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.movie), label: 'Infinity Wars'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Tiger 3'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Stree 2'),
        ],
      ),
    );
  }
}
