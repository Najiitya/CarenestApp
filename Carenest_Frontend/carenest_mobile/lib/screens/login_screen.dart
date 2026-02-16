import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Key to track the form state (for validation)
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers to capture user typing
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscure = true; // To toggle password visibility

  void _handleLogin() {
    // A. Check if the form is valid (Calls the 'validator' functions below)
    if (_formKey.currentState!.validate()) {

      // B. Simulate a successful login action
      print("Email is valid: ${_emailController.text}");
      print("Password: ${_passController.text}");

      // C. Navigate to the Gatekeeper (which decides Caregiver vs Patient)
      Navigator.pushReplacementNamed(context, '/dashboard_gate');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the background color from your Theme
      backgroundColor: AppTheme.background,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey, // Attach the key here
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  Image.asset('../assets/images/logo_black.png', height: 100, errorBuilder: (context, error, stack) {
                    // Fallback if logo isn't added yet
                    return const Icon(Icons.favorite, size: 80, color: AppTheme.primaryDark);
                  }),
                  Image.asset('../assets/images/typo_black.png', height: 30),

                  const SizedBox(height: 24),

                  Text(
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: AppTheme.headingLarge, // Uses Poppins Bold
                  ),
                  Text(
                    "Sign in to continue to CareNest",
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText, // Uses Grey Inter text
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    // The Theme automatically styles this!
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      hintText: "example@email.com",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    // VALIDATION LOGIC HERE:
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Email must contain "@" sign';
                      }
                      return null; // Valid!
                    },
                  ),
                  const SizedBox(height: 20),

                  //Password Input
                  TextFormField(
                    controller: _passController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      // Basic validation: non-empty and at least 6 characters
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        // Validation for minimum password length
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // --- FORGOT PASSWORD ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/reset_password'),
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- LOGIN BUTTON ---
                  ElevatedButton(
                    onPressed: _handleLogin,
                    // The style is automatically pulled from AppTheme!
                    child: const Text("Login", style: TextStyle(fontSize: 15)),
                  ),

                  const SizedBox(height: 24),

                  // --- REGISTER LINK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTheme.bodyText),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/role_select'),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins', // Matches theme font
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}