import 'package:application/page/controllers/user_auth.dart';
import 'package:application/page/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:application/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isObscure = true;
  final UserController userController = UserController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String verificationId = '';
  bool isLoading = false;
  bool isPhoneAuthSelected = false;
  Locale selectedLocale = const Locale('en', 'US');
  String _selectedLanguage = 'English';

  final Map<String, Locale> languages = {
    "English": const Locale('en', 'US'),
    "યિનિ": const Locale('gu', 'IN'),
    "हिंदी": const Locale('hi', 'IN'),
  };

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _checkCurrentUser();
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lang = prefs.getString("selectedLanguage");

    if (lang != null && languages.containsKey(lang)) {
      setState(() {
        selectedLocale = languages[lang]!;
      });
    }
  }

  Future<void> _changeLanguage(String language) async {
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

      final appState = AppState.of(context);
      if (appState == null) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
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

      setState(() {
        _selectedLanguage = language;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  void _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  Future<void> loginWithEmailPassword() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // Get user's display name
      String displayName = userCredential.user?.displayName ?? 'User';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Hello $displayName, Welcome Back!",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $errorMessage",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleGoogleSignIn() async {
    try {
      await userController.signOutGoogle();
      UserCredential? userCredential = await userController.signInWithGoogle();

      if (userCredential != null) {
        if (!mounted) return;

        // Get user's display name from Google sign in
        String displayName = userCredential.user?.displayName ?? 'User';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Hello $displayName, Welcome to Filmy Fun!",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Google Sign-In Failed: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> verifyPhoneNumber() async {
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter a phone number",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String phoneNumber = phoneController.text.trim();
      // Remove any spaces from the phone number
      phoneNumber = phoneNumber.replaceAll(" ", "");
      // Add +91 prefix if not present
      if (!phoneNumber.startsWith("+91")) {
        phoneNumber = "+91$phoneNumber";
      }

      // Validate phone number format
      if (phoneNumber.length != 13) {
        // +91 + 10 digits
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please enter a valid 10-digit phone number",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      print("Attempting to verify phone number: $phoneNumber");

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("Verification completed automatically");
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Auto verification completed!",
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } catch (e) {
            print("Auto verification error: $e");
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Auto verification failed: $e",
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
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.code} - ${e.message}");
          setState(() {
            isLoading = false;
          });
          String errorMessage = e.message ?? "Verification Failed";
          if (e.code == 'invalid-phone-number') {
            errorMessage = "Invalid phone number format";
          } else if (e.code == 'quota-exceeded') {
            errorMessage = "OTP quota exceeded. Please try again later.";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many attempts. Please try again later.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        codeSent: (String vId, int? resendToken) {
          print("Code sent successfully. Verification ID: $vId");
          setState(() {
            verificationId = vId;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "OTP sent successfully! Please check your messages.",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String vId) {
          print("Code auto retrieval timeout");
          setState(() {
            verificationId = vId;
            isLoading = false;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print("General error during verification: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
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

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter OTP",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login Successful!",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invalid OTP",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon with Animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xffedb41d),
                            const Color(0xffedb41d).withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.movie_creation_rounded,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Filmy Fun',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xffedb41d),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your Ultimate Movie Experience',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xffedb41d).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Login Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xffedb41d).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Toggle between Email and Phone login
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isPhoneAuthSelected = false;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: !isPhoneAuthSelected
                                        ? const Color(0xffedb41d)
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Email',
                                    style: GoogleFonts.poppins(
                                      color: !isPhoneAuthSelected
                                          ? Colors.black
                                          : const Color(0xffedb41d),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isPhoneAuthSelected = true;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: isPhoneAuthSelected
                                        ? const Color(0xffedb41d)
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Phone',
                                    style: GoogleFonts.poppins(
                                      color: isPhoneAuthSelected
                                          ? Colors.black
                                          : const Color(0xffedb41d),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isPhoneAuthSelected) ...[
                            TextField(
                              controller: emailController,
                              style: GoogleFonts.poppins(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                labelStyle: GoogleFonts.poppins(
                                    color: const Color(0xffedb41d)),
                                hintStyle:
                                    GoogleFonts.poppins(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.black45,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.email,
                                    color: Color(0xffedb41d)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xffedb41d)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xffedb41d),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: isObscure,
                              style: GoogleFonts.poppins(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                labelStyle: GoogleFonts.poppins(
                                    color: const Color(0xffedb41d)),
                                hintStyle:
                                    GoogleFonts.poppins(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.black45,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.lock,
                                    color: Color(0xffedb41d)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xffedb41d)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xffedb41d),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    isObscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xffedb41d),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: phoneController,
                              style: GoogleFonts.poppins(color: Colors.white),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                labelStyle: GoogleFonts.poppins(
                                    color: const Color(0xffedb41d)),
                                hintStyle:
                                    GoogleFonts.poppins(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.black45,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.phone,
                                    color: Color(0xffedb41d)),
                                prefixText: '+91 ',
                                prefixStyle:
                                    GoogleFonts.poppins(color: Colors.white),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xffedb41d)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xffedb41d),
                                  ),
                                ),
                              ),
                            ),
                            if (verificationId.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              TextField(
                                controller: otpController,
                                style: GoogleFonts.poppins(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'OTP',
                                  hintText: 'Enter OTP',
                                  labelStyle: GoogleFonts.poppins(
                                      color: const Color(0xffedb41d)),
                                  hintStyle: GoogleFonts.poppins(
                                      color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.black45,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Color(0xffedb41d)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xffedb41d)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xffedb41d),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 30),
                          if (!isPhoneAuthSelected)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading ? null : loginWithEmailPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffedb41d),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.black)
                                    : Text(
                                        "Login",
                                        style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : (verificationId.isEmpty
                                        ? verifyPhoneNumber
                                        : verifyOTP),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffedb41d),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.black)
                                    : Text(
                                        verificationId.isEmpty
                                            ? "Send OTP"
                                            : "Verify OTP",
                                        style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          if (!isPhoneAuthSelected) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xffedb41d)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: Text(
                                    "OR",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xffedb41d),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xffedb41d)
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xffedb41d),
                                side: BorderSide(
                                  color:
                                      const Color(0xffedb41d).withOpacity(0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.login),
                              label: Text(
                                'Sign in with Google',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isPhoneAuthSelected)
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            color: const Color(0xffedb41d),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
