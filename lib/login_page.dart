import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = "http://privserv.my.id:2435";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  // Palet warna purple sesuai dashboard
  final Color deepPurple = const Color(0xFF1a0b2e);
  final Color mainPurple = const Color(0xFF6b2d9f);
  final Color lightPurple = const Color(0xFF9d4edd);
  final Color accentPink = const Color(0xFFe0aaff);
  final Color bgDark = const Color(0xFF0d0221);
  final Color cardPurple = const Color(0xFF2a1347);
  final Color glassBlack = Colors.black.withOpacity(0.7);

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: savedUser,
                password: savedPass,
                role: data['role'],
                sessionKey: data['key'],
                expiredDate: data['expiredDate'],
                listBug: (data['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (data['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (data['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);
      print("VALIDATE RESPONSE => $validData");

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Your access has expired.\nPlease renew it.",
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        _showPopup(
          title: "❌ Login Failed",
          message: "Invalid username or password.",
          color: Colors.red,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              username: username,
              password: password,
              role: validData['role'],
              sessionKey: validData['key'],
              expiredDate: validData['expiredDate'],
              listBug: (validData['listBug'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              listDoos: (validData['listDDoS'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              news: (validData['news'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
          ),
        );
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message:
        "Failed to connect to the server.\nPlease check your internet connection.",
        color: mainPurple,
      );
    }

    setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = Colors.red,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: glassBlack,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style:
          TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                final uri = Uri.parse("https://t.me/hafz_reals");
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text("Contact Admin",
                  style: TextStyle(color: lightPurple)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputWidth = MediaQuery.of(context).size.width * 0.85;
    final gradientPurple = LinearGradient(
      colors: [mainPurple, lightPurple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // 🔹 Gradient latar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deepPurple, bgDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 🔹 Efek kaca blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 🔹 Konten utama
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo glass
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: gradientPurple,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: mainPurple.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        "WELCOME BACK",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: accentPink.withOpacity(0.8),
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                              color: mainPurple.withOpacity(0.6),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      const Text("Sign in to continue",
                          style:
                          TextStyle(color: Colors.white60, fontSize: 14)),

                      const SizedBox(height: 40),

                      // 🔹 Form glass
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: glassBlack,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: mainPurple.withOpacity(0.3),
                              width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: mainPurple.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _glassTextField(
                                  controller: userController,
                                  label: "Username",
                                  icon: Icons.person_outline),
                              const SizedBox(height: 16),
                              _glassTextField(
                                  controller: passController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  isPassword: true),
                              const SizedBox(height: 24),

                              // 🔹 Tombol login
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: gradientPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      )
                                          : const Text("Sign In",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Custom TextField bergaya kaca
  Widget _glassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: accentPink),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white60,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: mainPurple.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightPurple, width: 2),
        ),
      ),
      validator: (value) =>
      value == null || value.isEmpty ? "Please enter $label" : null,
    );
  }
}