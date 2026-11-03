import 'package:flutter/material.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/functions/authentication/auth_service.dart';
import 'package:fudo_v2/functions/authentication/client_service.dart';
import 'package:fudo_v2/pages/home/home_page.dart';
import 'package:fudo_v2/functions/orders/state/order_provider.dart';

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

  static const accentColor = GlobalColors.homeActionBackground;

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
        SnackBar(
          content: Text('Please enter username and password'),
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
      final clientInfo = await _clientService.getClientInfo();

      if (clientInfo == null) {
        throw Exception('Client information not found');
      }

      final clientId = (clientInfo['Client_ID'] ?? '').toString().trim();

      final clientName = (clientInfo['Client_Name'] ?? '').toString().trim();

      final clientType = (clientInfo['Client_Type'] ?? '').toString().trim();

      if (clientId.isEmpty) {
        throw Exception('Client ID not found');
      }

      // Validate user
      final user = await _authService.validateLogin(
        clientType,
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
            content: Text('Username or Password Incorrect'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // Get logged-in user information

      final userId = (user['User_ID'] ?? '').toString();

      final userName = (user['User_Name'] ?? '').toString();

      // Create session

      await context.read<SessionProvider>().setSession(
        clientId: clientId,
        clientName: clientName,
        clientType: clientType,
        userId: userId,
        userName: userName,
        groupCode: user['Group_Code']?.toString(),
        groupName: user['Group_Name']?.toString(),
      );
      await context.read<OrderProvider>().load();

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
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (error, stackTrace) {
      debugPrint('Login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login setup failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600;

    return Scaffold(
      backgroundColor: GlobalColors.homeBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 40,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: EdgeInsets.all(compact ? 24 : 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlobalColors.billingCardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'FUDO V2',
                          style: TextStyle(
                            color: GlobalColors.primaryText,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to continue',
                          style: TextStyle(
                            color: GlobalColors.secondaryText,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildInputLabel('Username'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _userNameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: 'Enter your username',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildInputLabel('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) =>
                              _isLoggingIn ? null : _handleLogin(),
                          decoration: _inputDecoration(
                            hint: 'Enter your password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: GlobalColors.secondaryText,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: accentColor.withValues(alpha: 0.65),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoggingIn
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
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
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Magnex Solutions',
              style: TextStyle(
                fontSize: 12,
                color: GlobalColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              color: GlobalColors.secondaryText,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: GlobalColors.primaryText,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _inputDecoration({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9BA8AA), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: GlobalColors.secondaryText),
        filled: true,
        fillColor: const Color(0xFFF8FAFA),
        contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlobalColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlobalColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.6),
        ),
      );
}
