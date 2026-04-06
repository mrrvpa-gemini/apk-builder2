import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Import halaman-halaman yang dibutuhkan
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'anime_home.dart'; 

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  
  // --- PALET WARNA (Ungu - Hitam) ---
  final Color deepPurple = const Color(0xFF4A148C);   // Deep Purple
  final Color mainPurple = const Color(0xFF6A1B9A);   // Main Purple
  final Color accentPurple = const Color(0xFFAB47BC); // Light Purple
  final Color bgBlack = const Color(0xFF000000);      // Black Background
  final Color cardBlack = const Color(0xFF0F0F0F);    // Card Black

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // 1. Background Animasi Ungu
          _buildAnimatedBackground(),

          // 2. Konten Utama
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header Baru: Digital Tools
                _buildHeaderCard(),
                
                const SizedBox(height: 20),
                
                // List Tools (Dropdown Style)
                Expanded(
                  child: _buildToolList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BACKGROUND ANIMATION ---
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: bgBlack),
            // Partikel Ungu
            ...List.generate(15, (index) {
              final top = (_bgAnimation.value + index * 0.1) % 1.0;
              final left = (index * 0.15) % 1.0;
              final size = 5.0 + (index % 3) * 5.0;
              return Positioned(
                top: top * MediaQuery.of(context).size.height,
                left: left * MediaQuery.of(context).size.width,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: mainPurple.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: mainPurple.withOpacity(0.3), blurRadius: 10)
                    ],
                  ),
                ),
              );
            }),
            // Efek Cahaya Pojok
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [deepPurple.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- HEADER CARD: DIGITAL TOOLS ---
  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, deepPurple.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mainPurple.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: mainPurple.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Globe
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainPurple.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: accentPurple.withOpacity(0.5)),
              ),
              child: Icon(Icons.public, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            // Teks
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Digital Tools",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage & Monitor Assets",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- LIST TOOLS (DROPDOWN) ---
  Widget _buildToolList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildDropdownCategory(
          title: "DDoS Attack",
          subtitle: "Network Stress Testing",
          icon: Icons.flash_on,
          children: [
            _buildSubMenu(
              "Attack Panel", 
              Icons.bolt, 
              () => _navTo(AttackPanel(sessionKey: widget.sessionKey, listDoos: widget.listDoos))
            ),
            _buildSubMenu(
              "Manage Server", 
              Icons.dns, 
              () => _navTo(ManageServerPage(keyToken: widget.sessionKey))
            ),
          ],
        ),
        
        _buildDropdownCategory(
          title: "Network Tools",
          subtitle: "WiFi & Spamming",
          icon: Icons.wifi,
          children: [
            _buildSubMenu(
              "Spam NGL", 
              Icons.newspaper, 
              () => _navTo(NglPage())
            ),
            _buildSubMenu(
              "WiFi Killer (Internal)", 
              Icons.wifi_off, 
              () => _navTo(WifiKillerPage())
            ),
            if (widget.userRole == "vip" || widget.userRole == "owner")
              _buildSubMenu(
                "WiFi Killer (External)", 
                Icons.router, 
                () => _navTo(WifiInternalPage(sessionKey: widget.sessionKey))
              ),
          ],
        ),

        _buildDropdownCategory(
          title: "OSINT Tools",
          subtitle: "Information Gathering",
          icon: Icons.search,
          children: [
            _buildSubMenu(
              "NIK Detail", 
              Icons.badge, 
              () => _navTo(const NikCheckerPage())
            ),
            _buildSubMenu(
              "Domain Check", 
              Icons.domain, 
              () => _navTo(const DomainOsintPage())
            ),
             _buildSubMenu(
              "Phone Lookup", 
              Icons.phone_iphone, 
              () => _showComingSoon()
            ),
          ],
        ),

        _buildDropdownCategory(
          title: "Downloader & Anime",
          subtitle: "Social Media & Streaming",
          icon: Icons.download,
          children: [
            // --- BUTTON ANIME BARU DISINI ---
            _buildSubMenu(
              "Anime Station", 
              Icons.movie_filter, 
              () => _navTo(const HomeAnimePage())
            ),
            _buildSubMenu(
              "TikTok Video", 
              Icons.tiktok, 
              () => _navTo(const TiktokDownloaderPage())
            ),
            _buildSubMenu(
              "Instagram Post", 
              Icons.camera_alt, 
              () => _navTo(const InstagramDownloaderPage())
            ),
          ],
        ),

        _buildDropdownCategory(
          title: "Utilities",
          subtitle: "Helper Tools",
          icon: Icons.build,
          children: [
             _buildSubMenu(
              "QR Generator", 
              Icons.qr_code, 
              () => _navTo(const QrGeneratorPage())
            ),
            _buildSubMenu(
              "IP Scanner", 
              Icons.lan, 
              () => _showComingSoon()
            ),
          ],
        ),
        
        const SizedBox(height: 50), // Spacing bawah
      ],
    );
  }

  // --- WIDGET DROPDOWN CATEGORY ---
  Widget _buildDropdownCategory({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Warna dasar card
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)
        ],
      ),
      child: Theme(
        // Menghilangkan garis divider bawaan ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          // Icon Leading
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [deepPurple, mainPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          // Judul
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
              fontSize: 14,
            ),
          ),
          // Subjudul
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
          // Icon Panah
          iconColor: accentPurple,
          collapsedIconColor: Colors.grey,
          // Isi Dropdown
          children: children,
        ),
      ),
    );
  }

  // --- WIDGET SUB MENU ITEM ---
  Widget _buildSubMenu(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: mainPurple.withOpacity(0.3), width: 2), // Garis indikator kiri
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10), // Indentasi
              Icon(icon, color: accentPurple, size: 16),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade800, size: 10),
            ],
          ),
        ),
      ),
    );
  }

  // --- NAVIGASI HELPER ---
  void _navTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showComingSoon() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.white),
            const SizedBox(width: 10),
            Text("Feature Coming Soon!", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: deepPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
