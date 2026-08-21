import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../session/session_provider.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _clientService = ClientService();

  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  static const accentColor = Color(0xFF2D2D2D);

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final loginId = _userNameController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter username and password',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {

      // Get client information
      final clientInfo =
          await _clientService.getClientInfo();

      if (clientInfo == null) {
        throw Exception(
          'Client information not found',
        );
      }

      final clientId =
          (clientInfo['Client_ID'] ?? '')
              .toString()
              .trim();

      final clientName =
          (clientInfo['Client_Name'] ?? '')
              .toString()
              .trim();

      final clientType =
          (clientInfo['Client_Type'] ?? '')
              .toString()
              .trim();

      if (clientId.isEmpty) {
        throw Exception(
          'Client ID not found',
        );
      }

      // Validate user
      final user =
          await _authService.validateLogin(
        clientId,
        loginId,
        password,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoggingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Username or Password Incorrect',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // Get logged-in user information

      final userId =
          (user['User_ID'] ?? '')
              .toString();

      final userName =
          (user['User_Name'] ?? '')
              .toString();

      // Create session

      context.read<SessionProvider>().setSession(
        clientId: clientId,
        clientName: clientName,
        clientType: clientType,
        userId: userId,
        userName: userName,
      );

      setState(() {
        _isLoggingIn = false;
      });

      // Go to HomePage

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 60),

                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),

                        TextField(
                          controller:
                              _userNameController,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            border:
                                OutlineInputBorder(),
                            enabledBorder:
                                OutlineInputBorder(
                              borderSide:
                                  BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderSide:
                                  BorderSide(
                                color:
                                    accentColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),

                        TextField(
                          controller:
                              _passwordController,
                          obscureText:
                              _obscurePassword,
                          textInputAction:
                              TextInputAction.done,
                          onSubmitted: (_) =>
                              _isLoggingIn
                                  ? null
                                  : _handleLogin(),
                          decoration:
                              InputDecoration(
                            border:
                                const OutlineInputBorder(),
                            enabledBorder:
                                const OutlineInputBorder(
                              borderSide:
                                  BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder:
                                const OutlineInputBorder(
                              borderSide:
                                  BorderSide(
                                color:
                                    accentColor,
                                width: 2,
                              ),
                            ),
                            suffixIcon:
                                IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                        .visibility_off
                                    : Icons.visibility,
                                color:
                                    Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: 280,
                    child: Align(
                      alignment:
                          Alignment.centerRight,
                      child: SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: _isLoggingIn
                              ? null
                              : _handleLogin,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                accentColor,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                6,
                              ),
                            ),
                          ),
                          child: Text(
                            _isLoggingIn
                                ? 'Please wait'
                                : 'Login',
                          ),
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

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Company Name',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}