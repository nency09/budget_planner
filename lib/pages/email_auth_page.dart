import 'package:flutter/material.dart';
import 'package:budget/services/email_auth_service.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/textInput.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({Key? key}) : super(key: key);

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Validation state
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      _emailError = "Please enter your email";
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      _emailError = "Please enter a valid email";
      isValid = false;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      _passwordError = "Please enter your password";
      isValid = false;
    } else if (_isSignUp && _passwordController.text.length < 6) {
      _passwordError = "Password must be at least 6 characters";
      isValid = false;
    }

    // Validate confirm password (only for sign up)
    if (_isSignUp) {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = "Please confirm your password";
        isValid = false;
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = "Passwords do not match";
        isValid = false;
      }
    }

    setState(() {});
    return isValid;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        // Sign up
        await EmailAuthService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          openSnackbar(SnackbarMessage(title: "Account created successfully!"));
          Navigator.of(context).pop(true);
        }
      } else {
        // Sign in
        await EmailAuthService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          openSnackbar(SnackbarMessage(title: "Signed in successfully!"));
          await updateSettings(
            "hasOnboarded",
            true,
            updateGlobalState: true,
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "An error occurred";
        if (e.toString().contains('user-not-found')) {
          errorMessage = "No account found with this email address";
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = "Incorrect password. Please try again";
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = "An account already exists with this email address";
        } else if (e.toString().contains('weak-password')) {
          errorMessage =
              "Password is too weak. Please use at least 6 characters";
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = "Please enter a valid email address";
        } else if (e.toString().contains('service-unavailable') ||
            e.toString().contains('CONFIGURATION_NOT_FOUND') ||
            e.toString().contains('recaptcha-not-configured')) {
          errorMessage =
              "Authentication service is temporarily unavailable. Please try again later";
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = "This account has been disabled";
        }

        openSnackbar(SnackbarMessage(title: errorMessage));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      openSnackbar(SnackbarMessage(title: "Please enter your email address"));
      return;
    }

    try {
      await EmailAuthService.resetPassword(email: _emailController.text.trim());
      if (mounted) {
        openSnackbar(SnackbarMessage(title: "Password reset email sent!"));
      }
    } catch (e) {
      if (mounted) {
        openSnackbar(SnackbarMessage(title: "Error sending reset email"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? "Sign Up" : "Sign In"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Welcome text
                Text(
                  _isSignUp ? "Create Account" : "Welcome Back!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  _isSignUp
                      ? "Sign up to sync your data across devices"
                      : "Sign in to access your synced data",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextInput(
                      labelText: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (_emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        }
                      },
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          _emailError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextInput(
                          labelText: "Password",
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (value) {
                            if (_passwordError != null) {
                              setState(() {
                                _passwordError = null;
                              });
                            }
                          },
                        ),
                        Positioned(
                          right: 30,
                          child: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          _passwordError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Confirm password field (only for sign up)
                if (_isSignUp) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextInput(
                            labelText: "Confirm Password",
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            onChanged: (value) {
                              if (_confirmPasswordError != null) {
                                setState(() {
                                  _confirmPasswordError = null;
                                });
                              }
                            },
                          ),
                          Positioned(
                            right: 30,
                            child: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_confirmPasswordError != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            _confirmPasswordError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                if (!_isSignUp) const SizedBox(height: 24),

                // Submit button
                Button(
                  label: _isSignUp ? "Sign Up" : "Sign In",
                  onTap: _submitForm,
                  disabled: _isLoading,
                ),

                const SizedBox(height: 16),

                // Forgot password (only for sign in)
                if (!_isSignUp) ...[
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text("Forgot Password?"),
                  ),
                  const SizedBox(height: 16),
                ],

                // Toggle between sign in and sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSignUp
                        ? "Already have an account? "
                        : "Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _confirmPasswordController.clear();
                        });
                      },
                      child: Text(_isSignUp ? "Sign In" : "Sign Up"),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Continue without sign in
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    "Continue Without Sign In",
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ),

                // Add bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
