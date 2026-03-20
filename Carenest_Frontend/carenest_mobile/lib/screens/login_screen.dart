import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'caregiver/caregiver_verification_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Check email and password with Supabase Auth
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passController.text,
        );

        final user = res.user;

        if (user != null && mounted) {
          final uid = user.id;

          // 2. Check if user is an Admin
          final adminCheck = await supabase
              .from('admins')
              .select('id')
              .eq('auth_id', uid)
              .maybeSingle(); // maybeSingle returns null if nothing is found

          if (adminCheck != null && mounted) {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
            return;
          }

          // 3. Check if user is a Caregiver
          final caregiverCheck = await supabase
              .from('caregiver_profiles')
              .select('id, verified')
              .eq('auth_id', uid)
              .maybeSingle();

          if (caregiverCheck != null && mounted) {
            final isVerified = caregiverCheck['verified'] == true;
            final caregiverId = caregiverCheck['id'] as int;

            if (isVerified) {
              Navigator.pushReplacementNamed(context, '/caregiver_dashboard');
            } else {
              // Check if there's an existing application
              final existingApp = await supabase
                  .from('caregiver_applications')
                  .select('status')
                  .eq('caregiver_id', caregiverId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              final appStatus = existingApp?['status'] as String?;

              // If application is already approved, go straight to dashboard
              if (appStatus == 'Approved' && mounted) {
                Navigator.pushReplacementNamed(context, '/caregiver_dashboard');
              } else if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaregiverVerificationPage(
                      caregiverId: caregiverId,
                      applicationStatus: appStatus,
                    ),
                  ),
                );
              }
            }
            return;
          }

          // 4. Check if user is a Patient
          final patientCheck = await supabase
              .from('patient_profiles')
              .select('id')
              .eq('auth_id', uid)
              .maybeSingle();

          if (patientCheck != null && mounted) {
            Navigator.pushReplacementNamed(context, '/patient_dashboard');
            return;
          }

          // If no profile is found in any table
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile not found. Please contact support.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } on AuthException catch (error) {
        // If email does not exist or password is wrong, Supabase throws this error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.message,
              ), // This will say "Invalid login credentials"
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    '../assets/images/logo_black.png',
                    height: 100,
                    errorBuilder: (context, error, stack) {
                      return const Icon(
                        Icons.favorite,
                        size: 80,
                        color: AppTheme.primaryDark,
                      );
                    },
                  ),
                  Image.asset(
                    '../assets/images/typo_black.png',
                    height: 30,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox(height: 30),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: AppTheme.headingLarge,
                  ),
                  Text(
                    "Sign in to continue",
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText,
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      hintText: "example@email.com",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Email must contain "@" sign';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/reset_password'),
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

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Login", style: TextStyle(fontSize: 15)),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTheme.bodyText),
                      GestureDetector(
                        // This goes to your signup page
                        onTap: () =>
                            Navigator.pushNamed(context, '/role_select'),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
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
