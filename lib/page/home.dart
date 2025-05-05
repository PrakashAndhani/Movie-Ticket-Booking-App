import 'package:application/page/LoginPage.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application/services/booking_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/razorpay_config.dart';
import 'package:application/main.dart';
import 'package:application/services/pdf_service.dart';
import 'package:application/page/MyTicketsPage.dart';
import 'package:application/page/BookingPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:application/page/SearchPage.dart';
import 'package:application/page/SettingsPage.dart';
import 'package:application/app_state.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> trendingMovies = [];
  List<Map<String, dynamic>> upcomingMovies = [];
  List<Map<String, dynamic>> nowRunningMovies = [];
  List<String> sliderImages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isEditingProfile = false;
  String _selectedLanguage = 'English'; // Default language

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      print('Starting to initialize data...');
      // Check if Firebase is initialized
      if (FirebaseFirestore.instance == null) {
        throw Exception('Firebase is not initialized');
      }
      print('Firebase is initialized');

      await _loadMovies();
      print('Movies loaded successfully');

      _nameController.text = "User";
      _mobileController.text = "";
      _cityController.text = "Rajkot";
      await _loadLanguagePreference();
      print('Language preferences loaded');
      await _loadUserData();
      print('User data loaded');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        print('State updated: loading complete');
      }
    } catch (e, stackTrace) {
      print('Error initializing data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize app data: $e';
        });
      }
    }
  }

  Future<void> _loadMovies() async {
    try {
      print('Starting to load movies from Firestore...');
      print('Collection name being used: adminpanle');

      // Fetch trending movies
      print('Fetching trending movies...');
      final trendingSnapshot = await FirebaseFirestore.instance
          .collection('adminpanle')
          .where('category', isEqualTo: 'trending')
          .get();
      print('Found ${trendingSnapshot.docs.length} trending movies');
      print(
          'Trending movies data: ${trendingSnapshot.docs.map((doc) => doc.data())}');

      // Fetch upcoming movies
      print('Fetching upcoming movies...');
      final upcomingSnapshot = await FirebaseFirestore.instance
          .collection('adminpanle')
          .where('category', isEqualTo: 'upcoming')
          .get();
      print('Found ${upcomingSnapshot.docs.length} upcoming movies');

      // Fetch now running movies
      print('Fetching now running movies...');
      final nowRunningSnapshot = await FirebaseFirestore.instance
          .collection('adminpanle')
          .where('category', isEqualTo: 'now_running')
          .get();
      print('Found ${nowRunningSnapshot.docs.length} now running movies');

      if (!mounted) return;

      setState(() {
        trendingMovies = trendingSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['movieName'] ?? 'Untitled Movie',
            'posterUrl': data['imageUrl'] ??
                'https://via.placeholder.com/300x450?text=No+Poster',
            'description': data['description'] ?? 'No description available',
            'rating': data['rating']?.toString() ?? '0.0',
            'duration': data['duration'] ?? '2h 30m',
            'category': data['category'] ?? 'trending',
            'genre': data['genre'] ?? 'Unknown',
            'language': data['language'] ?? 'Unknown',
            'releaseDate': data['releaseDate'] ?? 'Coming Soon',
            'director': data['director'] ?? 'Unknown',
            'cast': (data['cast'] as List?)?.cast<String>() ?? [],
          };
        }).toList();

        upcomingMovies = upcomingSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['movieName'] ?? 'Untitled Movie',
            'posterUrl': data['imageUrl'] ??
                'https://via.placeholder.com/300x450?text=No+Poster',
            'description': data['description'] ?? 'No description available',
            'rating': data['rating']?.toString() ?? '0.0',
            'duration': data['duration'] ?? '2h 30m',
            'category': data['category'] ?? 'upcoming',
            'genre': data['genre'] ?? 'Unknown',
            'language': data['language'] ?? 'Unknown',
            'releaseDate': data['releaseDate'] ?? 'Coming Soon',
            'director': data['director'] ?? 'Unknown',
            'cast': (data['cast'] as List?)?.cast<String>() ?? [],
          };
        }).toList();

        nowRunningMovies = nowRunningSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['movieName'] ?? 'Untitled Movie',
            'posterUrl': data['imageUrl'] ??
                'https://via.placeholder.com/300x450?text=No+Poster',
            'description': data['description'] ?? 'No description available',
            'rating': data['rating']?.toString() ?? '0.0',
            'duration': data['duration'] ?? '2h 30m',
            'category': data['category'] ?? 'now_running',
            'genre': data['genre'] ?? 'Unknown',
            'language': data['language'] ?? 'Unknown',
            'releaseDate': data['releaseDate'] ?? 'Now Showing',
            'director': data['director'] ?? 'Unknown',
            'cast': (data['cast'] as List?)?.cast<String>() ?? [],
          };
        }).toList();

        // Update slider images from trending movies
        if (trendingMovies.isNotEmpty) {
          sliderImages = trendingMovies
              .take(3)
              .map((movie) => movie['posterUrl'] as String)
              .toList();
        }
      });
    } catch (e, stackTrace) {
      print('Error loading movies: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load movies',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Please check your internet connection and try again',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _loadMovies(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _processMovieDocuments(
      List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'title': data['title'] ?? 'Untitled Movie',
        'posterUrl': data['posterUrl'] ??
            'https://via.placeholder.com/300x450?text=No+Poster',
        'description': data['description'] ?? 'No description available',
        'rating': data['rating']?.toString() ?? '0.0',
        'duration': data['duration'] ?? '2h 30m',
        'category': data['category'] ?? 'unknown',
        'genre': data['genre'] ?? 'Unknown',
        'language': data['language'] ?? 'Unknown',
        'releaseDate': data['releaseDate'] ?? 'Coming Soon',
        'director': data['director'] ?? 'Unknown',
        'cast': (data['cast'] as List?)?.cast<String>() ?? [],
      };
    }).toList();
  }

  Future<void> _createSampleMovies() async {
    final batch = FirebaseFirestore.instance.batch();
    final moviesRef = FirebaseFirestore.instance.collection('movies');

    // Sample trending movies
    final trendingMovie = {
      'title': 'Sample Trending Movie',
      'posterUrl': 'https://via.placeholder.com/300x450?text=Trending+Movie',
      'description': 'This is a sample trending movie description.',
      'rating': '4.5',
      'duration': '2h 30m',
      'category': 'trending',
      'genre': 'Action',
      'language': 'English',
      'releaseDate': '2024-03-15',
      'director': 'John Doe',
      'cast': ['Actor 1', 'Actor 2', 'Actor 3'],
    };
    batch.set(moviesRef.doc(), trendingMovie);

    // Sample upcoming movie
    final upcomingMovie = {
      'title': 'Sample Upcoming Movie',
      'posterUrl': 'https://via.placeholder.com/300x450?text=Upcoming+Movie',
      'description': 'This is a sample upcoming movie description.',
      'rating': '0.0',
      'duration': '2h 15m',
      'category': 'upcoming',
      'genre': 'Drama',
      'language': 'English',
      'releaseDate': '2024-04-01',
      'director': 'Jane Smith',
      'cast': ['Actor 4', 'Actor 5', 'Actor 6'],
    };
    batch.set(moviesRef.doc(), upcomingMovie);

    // Sample now running movie
    final nowRunningMovie = {
      'title': 'Sample Now Running Movie',
      'posterUrl': 'https://via.placeholder.com/300x450?text=Now+Running',
      'description': 'This is a sample now running movie description.',
      'rating': '4.0',
      'duration': '2h 45m',
      'category': 'now_running',
      'genre': 'Comedy',
      'language': 'English',
      'releaseDate': '2024-03-01',
      'director': 'Bob Wilson',
      'cast': ['Actor 7', 'Actor 8', 'Actor 9'],
    };
    batch.set(moviesRef.doc(), nowRunningMovie);

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xffedb41d),
              ),
              SizedBox(height: 16),
              Text(
                'Loading movies...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Color(0xffedb41d),
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffedb41d),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentIndex == 3) {
      return _buildProfilePage();
    } else if (_currentIndex == 2) {
      return const MyTicketsPage();
    } else if (_currentIndex == 1) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          title: Text(
            "Movies",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel Slider
              if (sliderImages.isNotEmpty)
                CarouselSlider(
                  items: sliderImages.map((image) {
                    return Container(
                      margin: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffedb41d).withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading carousel image: $error');
                            return Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.error_outline,
                                color: Color(0xffedb41d),
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 250.0,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    viewportFraction: 0.8,
                  ),
                ),

              // Movie Sections
              _buildMovieSection('Top Trending Movies', trendingMovies),
              _buildMovieSection('Now Running Movies', nowRunningMovies),
              _buildMovieSection('Upcoming Movies', upcomingMovies),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Filmy',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Fun',
              style: GoogleFonts.poppins(
                color: const Color(0xffedb41d),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: const Color(0xffedb41d),
                child: Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : 'P',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 30,
                          color: Color(0xffedb41d),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          "Hello ${_nameController.text.isNotEmpty ? _nameController.text : 'User'}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Rest of the content...
              if (trendingMovies.isNotEmpty) ...[
                _buildFeaturedMovies(),
                _buildCategories(),
                _buildLatestMovies(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFeaturedMovies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            "Featured Movies",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CarouselSlider(
          items: trendingMovies
              .map((movie) => _buildFeaturedMovieCard(movie))
              .toList(),
          options: CarouselOptions(
            height: 400.0,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movie),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffedb41d).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                movie['posterUrl'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.movie_creation_rounded,
                      color: Color(0xffedb41d),
                      size: 50,
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffedb41d),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movie['duration'] as String,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_rounded,
                          color: Color(0xffedb41d),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${movie['rating']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.language_rounded,
                          color: Color(0xffedb41d),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie['language'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie['genre'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster with Gradient Overlay
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    movie['posterUrl'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.movie_creation_rounded,
                          color: Color(0xffedb41d),
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.grey[900]!,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Movie Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            movie['title'] as String,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffedb41d),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.black,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${movie['rating']}',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Movie Info Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.access_time_rounded,
                            movie['duration'] as String),
                        _buildInfoChip(Icons.movie_filter_rounded,
                            movie['category'] as String),
                        _buildInfoChip(Icons.language_rounded,
                            movie['language'] as String),
                        _buildInfoChip(Icons.calendar_today_rounded,
                            movie['releaseDate'] as String),
                        _buildInfoChip(
                            Icons.category_rounded, movie['genre'] as String),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Director
                    if (movie['director'] != null &&
                        movie['director'] != 'Unknown')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Director',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.movie_creation_rounded,
                                  color: Color(0xffedb41d), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                movie['director'] as String,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Cast
                    if (movie['cast'] != null &&
                        (movie['cast'] as List).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cast',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (movie['cast'] as List)
                                .map((actor) => Chip(
                                      avatar: Icon(Icons.person_rounded,
                                          color: Color(0xffedb41d), size: 16),
                                      label: Text(
                                        actor.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      backgroundColor: Colors.grey[800],
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Description
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie['description'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeatBookingScreen(
                                movieTitle: movie['title'] as String,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffedb41d),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xffedb41d),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withAlpha(128),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withAlpha(128),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xffedb41d),
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? const Color(0xffedb41d).withAlpha(64)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentIndex == 0
                            ? const Color(0xffedb41d).withAlpha(96)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.home_rounded, size: 24),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? const Color(0xffedb41d).withAlpha(64)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentIndex == 1
                            ? const Color(0xffedb41d).withAlpha(96)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.movie_creation_rounded, size: 24),
                  ),
                  label: 'Movies',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2
                          ? const Color(0xffedb41d).withAlpha(64)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentIndex == 2
                            ? const Color(0xffedb41d).withAlpha(96)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child:
                        const Icon(Icons.confirmation_number_rounded, size: 24),
                  ),
                  label: 'My Tickets',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 3
                          ? const Color(0xffedb41d).withAlpha(64)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentIndex == 3
                            ? const Color(0xffedb41d).withAlpha(96)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded, size: 24),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String languageInEnglish) {
    bool isSelected = _selectedLanguage == language;
    return InkWell(
      onTap: () => _changeLanguage(language),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$language ($languageInEnglish)",
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categories",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton(
                "Now Running",
                Icons.play_circle_filled,
                () {
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildCategoryButton(
                "Upcoming",
                Icons.upcoming,
                () {
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildCategoryButton(
                "Trending",
                Icons.trending_up,
                () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMovies() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Movies",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _currentIndex = 1);
                },
                child: Text(
                  "See All",
                  style: GoogleFonts.poppins(
                    color: Color(0xffedb41d),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: nowRunningMovies.length,
              itemBuilder: (context, index) {
                final movie = nowRunningMovies[index];
                return GestureDetector(
                  onTap: () => _showMovieDetails(movie),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              movie['posterUrl'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Color(0xffedb41d),
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          movie['title'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Color(0xffedb41d),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${movie['rating']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              movie['duration'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffedb41d).withAlpha(64),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xffedb41d),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieSection(String title, List<Map<String, dynamic>> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => _showMovieDetails(movie),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie['posterUrl'] as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.movie,
                                  color: Color(0xffedb41d),
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie['title'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Color(0xffedb41d),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movie['rating']}',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            movie['duration'] as String,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    });
  }

  Future<void> _changeLanguage(String language) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final appState = AppState.of(context);

    if (appState == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', language);

      // Update app locale based on selected language
      Locale newLocale;
      switch (language) {
        case 'ગુજરાતી':
          newLocale = const Locale('gu', 'IN');
          break;
        case 'हिंदी':
          newLocale = const Locale('hi', 'IN');
          break;
        default:
          newLocale = const Locale('en', 'US');
      }

      if (!mounted) return;

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              const SizedBox(width: 16),
              Text(
                'Changing language...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: const Color(0xffedb41d),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Wait for the snackbar to show
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Update the app's locale
      appState.setLocale(newLocale);

      // Show success message
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Language changed successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to change language. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else if (hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xffedb41d).withAlpha(64),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'P',
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarProfileImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xffedb41d).withAlpha(64),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'P',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      children: [
                        // Profile Header with Gradient
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xffedb41d).withAlpha(64),
                                Colors.black,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Background Pattern
                              Positioned(
                                right: -50,
                                top: -50,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        const Color(0xffedb41d).withAlpha(32),
                                  ),
                                ),
                              ),
                              // Profile Content
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildProfileImage(),
                                    const SizedBox(height: 15),
                                    Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                          : 'User',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      user?.email ?? 'No Email',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit Profile Button
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditingProfile = !_isEditingProfile;
                              });
                              if (_isEditingProfile) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Edit mode enabled',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: const Color(0xffedb41d),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                _saveUserData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffedb41d),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditingProfile ? Icons.save : Icons.edit,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditingProfile
                                      ? 'Save Profile'
                                      : 'Edit Profile',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // User Details Card
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildProfileField(
                                icon: Icons.person_outline_rounded,
                                label: 'Name',
                                value: _nameController.text,
                                isEditable: true,
                                controller: _nameController,
                              ),
                              _buildProfileField(
                                icon: Icons.phone_outlined,
                                label: 'Mobile',
                                value: _mobileController.text,
                                isEditable: true,
                                controller: _mobileController,
                              ),
                              _buildProfileField(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: user?.email ?? 'No Email',
                                isEditable: false,
                              ),
                              _buildProfileField(
                                icon: Icons.location_city_outlined,
                                label: 'City',
                                value: "Rajkot",
                                isEditable: false,
                              ),
                              // Gender Selection
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        color: Colors.white70),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gender',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (_isEditingProfile)
                                            DropdownButton<String>(
                                              value: _selectedGender,
                                              dropdownColor: Colors.grey[900],
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              underline: Container(),
                                              isExpanded: true,
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                                color: Color(0xffedb41d),
                                              ),
                                              items: <String>[
                                                'Male',
                                                'Female',
                                                'Other'
                                              ].map<DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    _selectedGender = newValue;
                                                  });
                                                }
                                              },
                                            )
                                          else
                                            Text(
                                              _selectedGender,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isEditingProfile)
                                      Icon(
                                        Icons.edit,
                                        color: const Color(0xffedb41d),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Language Selection
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.language,
                                      color: const Color(0xffedb41d)),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Select Language",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildLanguageOption('English', 'English'),
                              _buildLanguageOption('ગુજરાતી', 'Gujarati'),
                              _buildLanguageOption('हिंदी', 'Hindi'),
                            ],
                          ),
                        ),
                        // Logout Button
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10, bottom: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              bool confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      'Confirm Logout',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to logout?',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm) {
                                try {
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Logged out successfully',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to logout. Please try again.',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "Logout",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    TextEditingController? controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (_isEditingProfile && label != 'Email' && label != 'City')
                  TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your ${label.toLowerCase()}',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (_isEditingProfile && label != 'Email' && label != 'City')
            Icon(
              Icons.edit,
              color: const Color(0xffedb41d),
              size: 20,
            ),
        ],
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(width: 16),
                Text(
                  'Saving profile...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );

        final updatedData = {
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'city': "Rajkot",
          'gender': _selectedGender,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('profile')
            .doc(user.uid)
            .update(updatedData);

        await user.updateDisplayName(_nameController.text.trim());

        if (!mounted) return;

        setState(() {
          _isEditingProfile = false;
        });

        _showSuccessSnackBar('Profile updated successfully');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('profile')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (profileDoc.exists) {
          Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? "User";
            _mobileController.text = data['mobile'] ?? "";
            _cityController.text = "Rajkot";
            _selectedGender = data['gender'] ?? 'Male';
          });
        } else {
          // Initialize new profile
          final profileData = {
            'name': user.displayName ?? "User",
            'email': user.email ?? "",
            'mobile': "",
            'city': "Rajkot",
            'gender': 'Male',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('profile')
              .doc(user.uid)
              .set(profileData);

          if (!mounted) return;

          setState(() {
            _nameController.text = profileData['name'] as String;
            _mobileController.text = profileData['mobile'] as String;
            _cityController.text = profileData['city'] as String;
            _selectedGender = profileData['gender'] as String;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class SeatBookingScreen extends StatefulWidget {
  final String movieTitle;
  const SeatBookingScreen({super.key, required this.movieTitle});

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  final BookingService _bookingService = BookingService();
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

  final List<String> showTimes = [
    "10:30 AM",
    "1:30 PM",
    "4:00 PM",
    "6:30 PM",
    "9:30 PM"
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment successful, now create the booking
    try {
      String bookingId = await _bookingService.createBooking(
        movieTitle: widget.movieTitle,
        date: selectedDate,
        time: selectedTime,
        seats: selectedSeats,
        totalAmount: selectedSeats.length * seatPrice,
      );

      // Generate PDF ticket
      final pdfService = PdfService();
      await pdfService.generateTicketPDF(
        movieTitle: widget.movieTitle,
        bookingId: bookingId,
        date: selectedDate,
        time: selectedTime,
        seats: selectedSeats,
        totalAmount: selectedSeats.length * seatPrice,
        paymentId: response.paymentId ?? '',
        context: context,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking confirmed! Redirecting to My Tickets...',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Wait for snackbar to show
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to MyTickets page
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyTicketsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to complete booking. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External wallet selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First check if seats are still available
      bool seatsAvailable = await _bookingService.checkSeatAvailability(
        widget.movieTitle,
        selectedDate,
        selectedTime,
        selectedSeats,
      );

      if (!seatsAvailable) {
        throw 'Selected seats are no longer available';
      }

      // Calculate amount in paise (Razorpay requires amount in smallest currency unit)
      int amountInPaise = selectedSeats.length * seatPrice * 100;

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

      _razorpay.open(options);
    } catch (e) {
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "Booking Failed",
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: Colors.amber),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.movieTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cinema Screen
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Screen Curve
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(100)),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  // Screen Glow Effect
                  Positioned(
                    top: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Screen Text
                  Positioned(
                    bottom: 5,
                    child: Text(
                      "SCREEN",
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 12,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem("Available", Colors.grey),
                  _buildLegendItem("Selected", Colors.amber),
                  _buildLegendItem("Booked", Colors.white),
                ],
              ),
            ),

            // Seat Grid with Premium/Regular Sections
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Premium Section Label
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "PREMIUM - ₹250",
                      style: GoogleFonts.poppins(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Premium Seats (A-E)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: _buildSeatGrid(0, 5), // First 5 rows
                  ),

                  const SizedBox(height: 20),

                  // Regular Section Label
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "REGULAR - ₹200",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Regular Seats (F-J)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: _buildSeatGrid(5, 10), // Last 5 rows
                  ),
                ],
              ),
            ),

            // Show Times
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: showTimes.length,
                itemBuilder: (context, index) {
                  bool isSelected = showTimes[index] == selectedTime;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = showTimes[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.amber : Colors.white24,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        showTimes[index],
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Date Selection with better styling
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  String date = "Dec ${8 + index}";
                  bool isSelected = selectedDate == date;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.amber : Colors.white24,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        date,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Booking Summary
            if (selectedSeats.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                        Text(
                          "₹${selectedSeats.length * seatPrice}",
                          style: GoogleFonts.poppins(
                            color: Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Text(
                                "Confirm Booking",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(int startRow, int endRow) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1,
      ),
      itemCount: (endRow - startRow) * 12,
      itemBuilder: (context, index) {
        int row = index ~/ 12 + startRow;
        int col = index % 12 + 1;
        String seat = "${String.fromCharCode(65 + row)}$col";
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
                      ? Colors.amber
                      : Colors.grey,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.amber.withAlpha(96),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                seat,
                style: GoogleFonts.poppins(
                  color: isBooked || isSelected ? Colors.black : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
