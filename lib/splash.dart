import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  bool _fadeOutStarted = false;

  // Palet Warna
  final Color c1 = const Color(0xFF4A148C);
  final Color c2 = const Color(0xFF9d4edd);
  final Color c3 = const Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/videos/load.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(false);
        _videoController.play();

        _fadeController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );

        _videoController.addListener(() {
          final position = _videoController.value.position;
          final duration = _videoController.value.duration;

          // Logic fade out sebelum video selesai
          if (position >= duration - const Duration(seconds: 1) &&
              !_fadeOutStarted) {
            _fadeOutStarted = true;
            _fadeController.forward();
          }

          // Navigasi setelah video selesai
          if (position >= duration) {
            _navigateToDashboard();
          }
        });
      });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
          news: widget.news,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c3,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // === 1. FULL SCREEN VIDEO ===
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Center(child: CircularProgressIndicator(color: c1)),

          // === 2. GRADIENT OVERLAY ===
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    c3.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // === 3. LOGO TEKS ===
          Positioned(
            bottom: 80,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [c2, c1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    "HoxtenCloud",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      fontFamily: 'Orbitron',
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "System Initializing...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // === 4. FADE OUT TRANSITION ===
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController.drive(Tween(begin: 1.0, end: 0.0)),
              child: Container(color: Colors.black),
            ),
        ],
      ),
    );
  }
}