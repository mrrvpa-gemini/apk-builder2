import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // --- THEME COLORS (UPDATED TO MATCH SCREENSHOT) ---
  final Color deepViolet = const Color(0xFF1A0B2E);    // Ungu background sangat gelap (Dark Mode)
  final Color mainViolet = const Color(0xFFB388FF);   // Ungu utama (Vibrant Violet)
  final Color accentViolet = const Color(0xFFB388FF); // Neon purple terang untuk highlight/tombol
  final Color solidBg = const Color(0xFF120524);      // Warna dasar latar belakang (Deep Purple)
  final Color whatsappGreen = const Color(0xFFB388FF); // Tetap, sudah kontras bagus

  // --- LOGIC ---
  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: solidBg,
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT BASE
          _buildBackground(),

          // 2. GLASS EFFECT OVERLAY (BackdropFilter)
          _buildGlassOverlay(),

          // 3. MAIN CONTENT (Centered)
          _buildMainContent(),

          // 4. FLOATING ACTION BUTTONS (Bottom Corners)
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (MODULAR) ---

  // 1. Background Gradient
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            solidBg,
            const Color(0xFF000000), // Sedikit transisi ke hitam di bawah agar elegan
          ],
        ),
      ),
    );
  }

  // 2. Frosted Glass Effect
  Widget _buildGlassOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: Colors.white.withOpacity(0.02), // Sangat tipis untuk nuansa
      ),
    );
  }

  // 3. Main Content Column
  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60), // Spacer atas

            // Logo
            Center(
              child: Image.asset(
                'assets/images/wel.png',
                height: 260,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 20),

            // Title Text
            FittedBox(
              child: Text(
                "Scary Ghost",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(
                      color: accentViolet.withOpacity(0.6),
                      blurRadius: 25,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle Text
            Text(
              "The Ultimate Digital Tools & Security",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // BUTTON 1: LOGIN
            _buildGradientButton(
              label: "🌐 Sign In",
              onTap: () => Navigator.pushNamed(context, "/login"),
            ),

            const SizedBox(height: 16),

            // BUTTON 2: BUY ACCESS
            _buildOutlineButton(
              label: "🛒 Buy Access",
              url: "https://t.me/DiyyOfficial",
            ),

            // Spacer bawah cukup agar tidak tertutup tombol floating
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 4. Floating Buttons Wrapper (Side by Side)
  Widget _buildFloatingButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
        child: Row(
          children: [
            // BUTTON TELEGRAM (Kiri - Expanded agar seimbang)
            Expanded(
              child: _buildLargeSocialButton(
                icon: FontAwesomeIcons.telegram,
                label: "TELEGRAM",
                color: mainViolet,
                url: "https://t.me/DiyyOfficial",
              ),
            ),

            const SizedBox(width: 12), // Jarak antar tombol

            // BUTTON WHATSAPP (Kanan - Expanded agar seimbang)
            Expanded(
              child: _buildLargeSocialButton(
                icon: FontAwesomeIcons.whatsapp,
                label: "WHATSAPP",
                color: whatsappGreen,
                url: "https://wa.me/6282313734892",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS FOR BUTTONS ---

  Widget _buildGradientButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainViolet, deepViolet], // Menggunakan variabel warna yang baru
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: mainViolet.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({required String label, required String url}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: () => _openUrl(url),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentViolet, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentViolet,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Widget tombol sosial dengan ukuran & style mirip Buy Access
  Widget _buildLargeSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return SizedBox(
      height: 55, // Tinggi sama dengan tombol Buy Access (55)
      child: OutlinedButton.icon(
        onPressed: () => _openUrl(url),
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15, // Font size disesuaikan agar muat
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Radius sama dengan tombol atas
          ),
          backgroundColor: color.withOpacity(0.15), // Background sedikit transparan
        ),
      ),
    );
  }
}