import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'AdminPanelScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'English';
  bool _isDarkTheme = true;
  bool _isAdmin = false;
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isAdmin = user?.email == "admin@gmail.com";
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      _isDarkTheme = prefs.getBool('isDark') ?? true;
    });
  }

  Future<void> _changeLanguage(String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', language);

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

      setState(() {
        _selectedLanguage = language;
      });

      appState.setLocale(newLocale);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to change language',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAdminLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Admin Login',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _adminEmailController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Admin Email',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adminPasswordController,
              style: GoogleFonts.poppins(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = _adminEmailController.text.trim();
                final password = _adminPasswordController.text.trim();

                if (email == "admin@gmail.com" && password == "password123") {
                  if (!mounted) return;
                  Navigator.pop(context); // Close dialog
                  setState(() => _isAdmin = true);
                  // Open admin panel
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invalid credentials',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'An error occurred',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              _adminEmailController.clear();
              _adminPasswordController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffedb41d),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xffedb41d)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLanguageOption(String language, String displayName) {
    final isSelected = _selectedLanguage == language;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        Icons.language,
        color: isSelected ? const Color(0xffedb41d) : Colors.white54,
        size: 20,
      ),
      title: Text(
        displayName,
        style: GoogleFonts.poppins(
          color: isSelected ? const Color(0xffedb41d) : Colors.white,
          fontSize: 14,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: Color(0xffedb41d),
              size: 20,
            )
          : null,
      onTap: () => _changeLanguage(language),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Login Option
            _buildListTile(
              title: 'Admin Access',
              subtitle: _isAdmin
                  ? 'Logged in as admin'
                  : 'Login as admin to manage content',
              icon: Icons.admin_panel_settings,
              onTap: _isAdmin
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AdminPanelScreen()),
                      );
                    }
                  : _showAdminLoginDialog,
              trailing: _isAdmin
                  ? const Icon(Icons.check_circle, color: Color(0xffedb41d))
                  : const Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 16),
            ),

            _buildListTile(
              title: 'Account',
              subtitle: 'Manage your account settings',
              icon: Icons.person_outline,
              onTap: () {
                // Handle account settings
              },
            ),

            // Language Section
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                    child: Text(
                      'Language',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildLanguageOption('English', 'English'),
                  _buildLanguageOption('ગુજરાતી', 'Gujarati'),
                  _buildLanguageOption('हिंदी', 'Hindi'),
                ],
              ),
            ),

            // Theme Section
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                    child: Text(
                      'Theme',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Dark Theme',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    value: _isDarkTheme,
                    onChanged: (isDark) async {
                      final appState = AppState.of(context);
                      if (appState != null) {
                        appState.setThemeMode(
                            isDark ? ThemeMode.dark : ThemeMode.light);
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('isDark', isDark);
                        setState(() {
                          _isDarkTheme = isDark;
                        });
                      }
                    },
                    activeColor: const Color(0xffedb41d),
                  ),
                ],
              ),
            ),

            _buildListTile(
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              icon: Icons.help_outline,
              onTap: () {
                // Handle help and support
              },
            ),

            _buildListTile(
              title: 'About',
              subtitle: 'Learn more about the app',
              icon: Icons.info_outline,
              onTap: () {
                // Handle about section
              },
            ),

            const SizedBox(height: 16),

            // Sign Out Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
