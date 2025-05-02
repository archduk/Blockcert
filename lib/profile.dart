import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode; // Pass the dark mode state
  const ProfileScreen({super.key, required this.isDarkMode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  // Fetch user profile from Firestore
  Future<void> fetchUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            emailController.text = userDoc['email'] ?? "";
            phoneController.text = userDoc['phone'] ?? "";
            dobController.text = userDoc['dob'] ?? "";
            addressController.text = userDoc['address'] ?? "";
            countryController.text = userDoc['country'] ?? "";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  // Save updated profile to Firestore
  Future<void> saveProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'phone': phoneController.text,
          'dob': dobController.text,
          'address': addressController.text,
          'country': countryController.text,
        });

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text("Profile updated successfully."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  // Theme builder for light and dark mode
  ThemeData _buildThemeData() {
    return widget.isDarkMode
        ? ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.0),
        ),
      ),
    )
        : ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
        bodyLarge: TextStyle(color: Colors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildThemeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Profile", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildField("Email", emailController, enabled: false),
              _buildField("Phone Number", phoneController),
              _buildField("Date of Birth", dobController),
              _buildField("Address", addressController),
              _buildField("Country", countryController),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: saveProfile,
                child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build input fields
  Widget _buildField(String label, TextEditingController controller,
      {bool obscureText = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
