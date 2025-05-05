import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AdminPanelScreen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email ==
        "admin@gmail.com"; // You can modify this condition based on your admin logic

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAdmin) ...[
            _buildSettingItem(
              context,
              'Admin Panel',
              'Manage movies and content',
              Icons.admin_panel_settings,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildSettingItem(
            context,
            'Account',
            'Manage your account settings',
            Icons.person_outline,
            () {
              // Handle account settings
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            'Notifications',
            'Configure notification preferences',
            Icons.notifications_none,
            () {
              // Handle notifications settings
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            'Privacy',
            'Manage your privacy settings',
            Icons.privacy_tip_outlined,
            () {
              // Handle privacy settings
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            'Help & Support',
            'Get help and contact support',
            Icons.help_outline,
            () {
              // Handle help and support
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            'About',
            'Learn more about the app',
            Icons.info_outline,
            () {
              // Handle about section
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        leading: Icon(icon, color: const Color(0xffedb41d)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
