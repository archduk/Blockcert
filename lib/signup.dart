import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const SignUpPage({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedCountry = 'Kenya';
  String _countryCode = '+254';
  DateTime? _selectedDate;

  final List<String> _countries = ['Kenya', 'Uganda', 'Tanzania', 'Nigeria', 'Ghana'];
  final Map<String, String> _countryCodes = {
    'Kenya': '+254',
    'Uganda': '+256',
    'Tanzania': '+255',
    'Nigeria': '+234',
    'Ghana': '+233',
  };

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String fullName = _fullNameController.text.trim();
      String email = _emailController.text.trim().toLowerCase(); // Ensure lowercase email
      String password = _passwordController.text.trim();
      String phone = '$_countryCode${_phoneController.text.trim()}';
      String address = _addressController.text.trim();
      String dob = _dobController.text.trim();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'address': address,
          'dob': dob,
          'country': _selectedCountry,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
        _showSnackBar("Verification email sent. Please check your inbox.");

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              isDarkMode: widget.isDarkMode,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showSnackBar("An error occurred: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = "This email is already registered.";
        break;
      case 'weak-password':
        errorMessage = "Password should be at least 8 characters with special characters.";
        break;
      case 'invalid-email':
        errorMessage = "Invalid email format.";
        break;
      case 'network-request-failed':
        errorMessage = "No internet connection.";
        break;
      default:
        errorMessage = "Registration failed: ${e.message}";
    }
    _showSnackBar(errorMessage, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number, one special character
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: const Color(0xFF0888E8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.verified_outlined, size: 60, color: Colors.blue),
                    SizedBox(height: 10),
                    Text(
                      'BlockCert',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              const Text(
                "Create a new account",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter your full name";
                        if (value.trim().split(' ').length < 2) return "Enter both first and last name";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter your email";
                        if (!_isValidEmail(value)) return "Enter a valid email (e.g., user@example.com)";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
                        labelText: "Country",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue!;
                          _countryCode = _countryCodes[newValue]!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixText: '$_countryCode ',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter phone number";
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return "Only numbers allowed";
                        if (value.length < 9) return "Phone number too short";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please select date of birth";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: "Address",
                        prefixIcon: const Icon(Icons.home),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter your address";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter your password";
                        if (!_isValidPassword(value)) {
                          return "Password must be at least 8 characters with:\n- 1 uppercase\n- 1 lowercase\n- 1 number\n- 1 special character";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please confirm your password";
                        if (value != _passwordController.text) return "Passwords do not match";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            isDarkMode: widget.isDarkMode,
                            onToggleTheme: widget.onToggleTheme,
                          ),
                        ),
                      );
                    },
                    child: const Text("Login", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}