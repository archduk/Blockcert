import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(User?)? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'Male';
  String _selectedCountry = 'Kenya';
  String _countryCode = '+254';

  // Animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Constants
  static const _countries = ['Kenya', 'Uganda', 'Tanzania', 'Nigeria', 'Ghana'];
  static const _countryPrefixes = {
    'Kenya': '+254',
    'Uganda': '+256',
    'Tanzania': '+255',
    'Nigeria': '+234',
    'Ghana': '+233',
  };
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      User? user;
      if (_isLogin) {
        user = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        user = await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phone: '$_countryCode${_phoneController.text.trim()}',
          dob: _dobController.text.trim(),
          gender: _selectedGender,
          country: _selectedCountry,
        );
      }

      if (user != null && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${_isLogin ? 'Login' : 'Sign up'} successful!')),
        );
        widget.onAuthSuccess?.call(user);
      }
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_getAuthError(e.code))),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email format';
      default:
        return 'Authentication failed';
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAuthMode() {
    _formKey.currentState?.reset();
    setState(() => _isLogin = !_isLogin);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const FlutterLogo(size: 80),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 30),

                    if (!_isLogin) ...[
                      _buildFullNameField(),
                      const SizedBox(height: 16),
                      _buildGenderDropdown(),
                      const SizedBox(height: 16),
                      _buildCountryDropdown(),
                      const SizedBox(height: 16),
                      _buildPhoneField(),
                      const SizedBox(height: 16),
                      _buildDobField(),
                      const SizedBox(height: 16),
                    ],

                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                    ],

                    if (_isLogin) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleAuthMode,
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
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

  Widget _buildFullNameField() => TextFormField(
    controller: _fullNameController,
    decoration: const InputDecoration(
      labelText: 'Full Name',
      prefixIcon: Icon(Icons.person),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (value.trim().split(' ').length < 2) return 'Enter first & last name';
      return null;
    },
    textCapitalization: TextCapitalization.words,
  );

  Widget _buildGenderDropdown() => DropdownButtonFormField<String>(
    value: _selectedGender,
    items: ['Male', 'Female', 'Other'].map((gender) {
      return DropdownMenuItem(
        value: gender,
        child: Text(gender),
      );
    }).toList(),
    onChanged: (value) => setState(() => _selectedGender = value!),
    decoration: const InputDecoration(
      labelText: 'Gender',
      prefixIcon: Icon(Icons.people),
    ),
  );

  Widget _buildCountryDropdown() => DropdownButtonFormField<String>(
    value: _selectedCountry,
    items: _countries.map((country) {
      return DropdownMenuItem(
        value: country,
        child: Text(country),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        _selectedCountry = value!;
        _countryCode = _countryPrefixes[value]!;
      });
    },
    decoration: const InputDecoration(
      labelText: 'Country',
      prefixIcon: Icon(Icons.location_on),
    ),
  );

  Widget _buildPhoneField() => TextFormField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: 'Phone Number',
      prefixIcon: const Icon(Icons.phone),
      prefixText: '$_countryCode ',
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (value.length < 9) return 'Invalid phone number';
      return null;
    },
  );

  Widget _buildDobField() => TextFormField(
    controller: _dobController,
    readOnly: true,
    onTap: _selectDate,
    decoration: const InputDecoration(
      labelText: 'Date of Birth',
      prefixIcon: Icon(Icons.calendar_today),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      return null;
    },
  );

  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.email),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (!_emailRegex.hasMatch(value)) return 'Invalid email';
      return null;
    },
  );

  Widget _buildPasswordField() => TextFormField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (value.length < 6) return 'Minimum 6 characters';
      return null;
    },
  );

  Widget _buildConfirmPasswordField() => TextFormField(
    controller: _confirmPasswordController,
    obscureText: _obscureConfirmPassword,
    decoration: InputDecoration(
      labelText: 'Confirm Password',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (value != _passwordController.text) return 'Passwords don\'t match';
      return null;
    },
  );
}