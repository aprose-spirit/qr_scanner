import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    if (_usernameController.text == 'admin' &&
        _passwordController.text == 'password') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid username or password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    const barBaseHeight = 65.0;
    final topInset = media.padding.top; // status bar height
    final barHeight = barBaseHeight + topInset;

    return Scaffold(
      // We handle keyboard padding ourselves
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B7FFF),
                Color(0xFF980FFA),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 🔹 Top Bar (status-bar safe)
              Container(
                height: barHeight,
                width: double.infinity,
                padding: EdgeInsets.only(left: 24, top: topInset),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  border: const Border(
                    bottom: BorderSide(color: Color(0x33FFFEFE)),
                  ),
                ),
                child: const Text(
                  'QR Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // 🔹 Login Card (scrolls + avoids keyboard overflow)
              Positioned.fill(
                top: barHeight, // below the top bar
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboard = MediaQuery.of(context).viewInsets.bottom;
                    final cardWidth = constraints.maxWidth > 500
                        ? 448.0
                        : constraints.maxWidth * 0.9;

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: keyboard),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: SizedBox(
                              width: cardWidth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 32,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0x33FFFEFE),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icon
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.qr_code,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    const Text(
                                      'Enter your credentials to access the QR scanner',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xCCFFFEFE),
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Username Field
                                    _buildInput(
                                      controller: _usernameController,
                                      hint: 'Username',
                                      icon: Icons.person,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          FocusScope.of(context).nextFocus(),
                                    ),

                                    const SizedBox(height: 16),

                                    // Password Field
                                    _buildInput(
                                      controller: _passwordController,
                                      hint: 'Password',
                                      icon: Icons.lock,
                                      obscure: true,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _login(),
                                    ),

                                    const SizedBox(height: 24),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Color(0xFF9810FA),
                                            fontSize: 16,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x7FFFFEFE)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x4CFFFEFE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x4CFFFEFE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}