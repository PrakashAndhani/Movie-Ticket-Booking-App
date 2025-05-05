import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _movieNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _directorController = TextEditingController();
  final _durationController = TextEditingController();
  final _genreController = TextEditingController();
  final _languageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _releaseDateController = TextEditingController();
  final _imageUrlController = TextEditingController();
  List<String> cast = [];
  String _selectedCategory = 'trending';
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  List<Map<String, dynamic>> movies = [];
  final _castController = TextEditingController();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  void dispose() {
    _movieNameController.dispose();
    _descriptionController.dispose();
    _directorController.dispose();
    _durationController.dispose();
    _genreController.dispose();
    _languageController.dispose();
    _ratingController.dispose();
    _releaseDateController.dispose();
    _castController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await _loadMovies();
    } catch (e) {
      print('Error initializing Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('adminpanle').get();

      setState(() {
        movies = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error loading movies: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading movies: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      // For Android 13 and above
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Request photos permission for Android 13+
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            throw Exception('Photos permission denied');
          }
        } else {
          // Request storage permission for Android 12 and below
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      setState(() => _isLoading = true);

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        if (await imageFile.exists()) {
          setState(() {
            _imageFile = imageFile;
          });
        } else {
          throw Exception('Selected image file does not exist');
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (!mounted) return;

      String errorMessage = 'Error picking image. ';
      if (e.toString().contains('permission')) {
        errorMessage += 'Please grant permission from settings.';
      } else {
        errorMessage += 'Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: e.toString().contains('permission')
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      setState(() => _isLoading = true);

      // Create a unique filename using timestamp
      final fileName = 'movie_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create the storage reference with proper path
      final storageRef = FirebaseStorage.instance.ref();
      final movieImageRef = storageRef.child('movie_posters').child(fileName);

      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'admin',
          'timestamp': DateTime.now().toString(),
        },
      );

      // Upload the file with metadata
      await movieImageRef.putFile(_imageFile!, metadata);

      // Get the download URL
      final downloadUrl = await movieImageRef.getDownloadURL();

      setState(() => _isLoading = false);
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _addMovie() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _imageUrlController.text.trim();

      if (imageUrl.isEmpty) {
        throw Exception('Please enter an image URL');
      }

      // Prepare movie data
      final movieData = {
        'movieName': _movieNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'director': _directorController.text.trim(),
        'duration': _durationController.text.trim(),
        'genre': _genreController.text.trim(),
        'language': _languageController.text.trim(),
        'rating': double.tryParse(_ratingController.text.trim()) ?? 0.0,
        'releaseDate': _releaseDateController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'cast': cast,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      await FirebaseFirestore.instance.collection('adminpanle').add(movieData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movie added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form
      _clearForm();
      // Refresh movie list
      await _loadMovies();
    } catch (e) {
      print('Error adding movie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding movie: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateMovie(String id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      final movieData = {
        'movieName': _movieNameController.text,
        'description': _descriptionController.text,
        'director': _directorController.text,
        'duration': _durationController.text,
        'genre': _genreController.text,
        'language': _languageController.text,
        'rating': double.parse(_ratingController.text),
        'releaseDate': _releaseDateController.text,
        'category': _selectedCategory,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'cast': cast,
      };

      await FirebaseFirestore.instance
          .collection('adminpanle')
          .doc(id)
          .update(movieData);

      _clearForm();
      _loadMovies();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Movie updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating movie: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteMovie(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('adminpanle')
          .doc(id)
          .delete();

      _loadMovies();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Movie deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting movie: $e')),
      );
    }
  }

  void _clearForm() {
    _movieNameController.clear();
    _descriptionController.clear();
    _directorController.clear();
    _durationController.clear();
    _genreController.clear();
    _languageController.clear();
    _ratingController.clear();
    _releaseDateController.clear();
    _castController.clear();
    _imageUrlController.clear();
    setState(() {
      _imageFile = null;
      _imageUrl = null;
      cast = [];
      _selectedCategory = 'trending';
    });
  }

  void _editMovie(Map<String, dynamic> movie) {
    _movieNameController.text = movie['movieName'] ?? '';
    _descriptionController.text = movie['description'] ?? '';
    _directorController.text = movie['director'] ?? '';
    _durationController.text = movie['duration'] ?? '';
    _genreController.text = movie['genre'] ?? '';
    _languageController.text = movie['language'] ?? '';
    _ratingController.text = movie['rating']?.toString() ?? '';
    _releaseDateController.text = movie['releaseDate'] ?? '';
    setState(() {
      _selectedCategory = movie['category'] ?? 'trending';
      _imageUrl = movie['imageUrl'];
      cast = List<String>.from(movie['cast'] ?? []);
    });
  }

  void _addCastMember() {
    if (_castController.text.isNotEmpty) {
      setState(() {
        cast.add(_castController.text);
        _castController.clear();
      });
    }
  }

  void _removeCastMember(int index) {
    setState(() {
      cast.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add/Edit Movie',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Image URL Input Field
                          TextFormField(
                            controller: _imageUrlController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Image URL',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter image URL';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Preview Image if URL is entered
                          if (_imageUrlController.text.isNotEmpty)
                            Center(
                              child: Container(
                                width: 200,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image:
                                        NetworkImage(_imageUrlController.text),
                                    fit: BoxFit.cover,
                                    onError: (error, stackTrace) {
                                      print('Error loading image: $error');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 16),

                          // Movie Details Form Fields
                          TextFormField(
                            controller: _movieNameController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Movie Name',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter movie name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            style: TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: Colors.grey[900],
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                            items: ['trending', 'upcoming', 'now_running']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              }
                            },
                          ),
                          SizedBox(height: 16),

                          // Other form fields
                          TextFormField(
                            controller: _directorController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Director',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _durationController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Duration (e.g., 2h 30m)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _genreController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Genre',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _languageController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Language',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _ratingController,
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rating (0-5)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter rating';
                              }
                              final rating = double.tryParse(value);
                              if (rating == null || rating < 0 || rating > 5) {
                                return 'Rating must be between 0 and 5';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _releaseDateController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Release Date',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xffedb41d)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Cast Members
                          Text(
                            'Cast Members',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _castController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Add cast member',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xffedb41d)),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, color: Color(0xffedb41d)),
                                onPressed: _addCastMember,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: List.generate(
                              cast.length,
                              (index) => Chip(
                                label: Text(cast[index]),
                                deleteIcon: Icon(Icons.close, size: 16),
                                onDeleted: () => _removeCastMember(index),
                                backgroundColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addMovie,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffedb41d),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Add Movie',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Movies List
                  Text(
                    'Movies List',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          leading: movie['imageUrl'] != null
                              ? Image.network(
                                  movie['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.movie,
                                        color: Colors.white);
                                  },
                                )
                              : Icon(Icons.movie, color: Colors.white),
                          title: Text(
                            movie['movieName'] ?? '',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            movie['category'] ?? '',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _editMovie(movie),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMovie(movie['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
