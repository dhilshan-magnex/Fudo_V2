import 'package:flutter/material.dart';
import 'database/database_helper.dart'; // adjust path to match where you saved db_helper.dart


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  static const accentColor = Color(0xFF2D2D2D); // change to your brand color

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = await DBHelper.validateLogin(
      _userIdController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username or Password Incorrect'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  bool _obscurePassword = true;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  const Text(
                    'FUDO V2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 60),

                  // User ID
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User ID',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Password
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Login button (right-aligned within the 280-width block)
                  SizedBox(
                    width: 280,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Bottom bar: company name + version (left), settings icon (right)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Company Name',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                print('settings tapped');
              },
            ),
          ],
        ),
      ),
    );
  }
}
