import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const LoginPage({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        _showSnackBar("Please verify your email before logging in.", isError: true);

        await user.sendEmailVerification();
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user!.uid).get();

      if (!userDoc.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        _showSnackBar("User data not found. Please sign up again.", isError: true);
        await _auth.signOut();
        return;
      }

      String userName = userDoc['fullName'] ?? user.email!;
      String userEmail = user.email!;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            userName: userName,
            userEmail: userEmail,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _handleAuthError(e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar("An error occurred: ${e.toString()}", isError: true);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = "No user found with this email.";
        break;
      case 'wrong-password':
        errorMessage = "Incorrect password.";
        break;
      case 'user-disabled':
        errorMessage = "This account has been disabled.";
        break;
      case 'too-many-requests':
        errorMessage = "Too many attempts. Try again later.";
        break;
      default:
        errorMessage = "Login failed. Please try again.";
    }
    _showSnackBar(errorMessage, isError: true);
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Please enter your email first.", isError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnackBar("Password reset email sent. Check your inbox.");
    } catch (e) {
      _showSnackBar("Failed to send reset email: ${e.toString()}", isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Login"),
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              const Text(
                "Login to your account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "Enter your email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "Enter your password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendPasswordResetEmail,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpPage(
                            isDarkMode: widget.isDarkMode,
                            onToggleTheme: widget.onToggleTheme,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.blue),
                    ),
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