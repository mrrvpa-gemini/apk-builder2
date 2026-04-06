import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

// Import halaman-halaman
import 'anime_home.dart';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;
  VideoPlayerController? _videoController;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  // --- PALET WARNA UNGU (SESUAI GAMBAR) ---
  final Color deepPurple = const Color(0xFF1a0b2e);   // Background gelap
  final Color mainPurple = const Color(0xFF6b2d9f);   // Purple utama
  final Color lightPurple = const Color(0xFF9d4edd);  // Purple terang
  final Color accentPink = const Color(0xFFe0aaff);   // Aksen pink/ungu muda
  final Color bgDark = const Color(0xFF0d0221);       // Background super gelap
  final Color cardPurple = const Color(0xFF2a1347);   // Card background

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Initialize video controller
    _initializeVideo();

    // Default Page: Dashboard Home
    _selectedPage = _buildEnhancedDashboard();
    _initAndroidIdAndConnect();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
        _videoController?.setVolume(0); // Mute video
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws:fantzy.hostingvvip.web.id:4000'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          _handleInvalidSession("Session invalid, please re-login.");
        }
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: cardPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: mainPurple, width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: lightPurple, size: 28),
              const SizedBox(width: 10),
              Text("Session Expired",
                  style: TextStyle(color: accentPink, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainPurple, lightPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildEnhancedDashboard();
      } else if (index == 1) {
        // WhatsApp (Index 1)
        _selectedPage = HomePage(
          isGroup: false, 
          username: username,
          password: password,
          sessionKey: sessionKey,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
        );
      } else if (index == 2) {
        // Anime (Index 2 - Pindah dari index 3)
        _selectedPage = HomeAnimePage();
      } else if (index == 3) {
        // Tools (Index 3 - Pindah dari index 2)
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      }
    });
  }

  // Fungsi _showWhatsAppMenu dan _buildMenuOption DIHAPUS

  void _navigateToAdminPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(sessionKey: sessionKey)));
  }

  void _navigateToSellerPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SellerPage(keyToken: sessionKey)));
  }

  Widget _buildEnhancedDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgDark, deepPurple],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Stats Cards (Online & Connections)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cardPurple.withOpacity(0.6), deepPurple.withOpacity(0.4)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainPurple.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_alt_rounded, color: accentPink, size: 15),
                              const SizedBox(width: 5),
                              const Text(
                                "Online",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "0",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cardPurple.withOpacity(0.6), deepPurple.withOpacity(0.4)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainPurple.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hub_rounded, color: accentPink, size: 15),
                              const SizedBox(width: 5),
                              const Text(
                                "Connections",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "0",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Banner Video Scary Ghost
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mainPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: mainPurple.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Player
                    if (_videoController != null && _videoController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    else
                      Container(
                        color: deepPurple,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            deepPurple.withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Text Overlay
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Scary Ghost",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Upgrade to the New Scary Ghost",
                            style: TextStyle(
                              color: accentPink,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Join Scary Ghost Info Channel Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardPurple.withOpacity(0.6), deepPurple.withOpacity(0.4)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: mainPurple.withOpacity(0.5)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      const url = 'https://t.me/ScaryGhost_info';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [mainPurple.withOpacity(0.3), lightPurple.withOpacity(0.3)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(FontAwesomeIcons.telegram, color: accentPink, size: 20),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              "JOIN SCARY GHOST INFO CHANNEL",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: accentPink, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Manage Bug Sender Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainPurple, lightPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: mainPurple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BugSenderPage(
                            sessionKey: sessionKey,
                            username: username,
                            role: role,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.bug_report_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "MANAGE BUG SENDER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMenuIcon() {
    return Builder(
      builder: (context) => IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24, 
              height: 2.5, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5)
              )
            ),
            const SizedBox(height: 5),
            Container(
              width: 16, 
              height: 2.5, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5)
              )
            ),
            const SizedBox(height: 5),
            Container(
              width: 8, 
              height: 2.5, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5)
              )
            ),
          ],
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: deepPurple,
        elevation: 0,
        centerTitle: false,
        leading: _buildCustomMenuIcon(),
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            "Hai, $username",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.purple, size: 26),
            onPressed: () {
              // Audio/Music settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Colors.purple, size: 28),
            onPressed: () {
              // Profile
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      extendBody: true,
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.95), deepPurple.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: mainPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: mainPurple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: accentPink,
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            // Ganti Icon Message menjadi Logo WhatsApp
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.whatsapp), 
              activeIcon: Icon(FontAwesomeIcons.whatsapp),
              label: "WhatsApp",
            ),
            // POSISI DITUKAR: Anime sekarang di Index 2
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_filter_outlined),
              activeIcon: Icon(Icons.movie_filter),
              label: "Anime",
            ),
            // POSISI DITUKAR: Tools sekarang di Index 3
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: "Tools",
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: cardPurple,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: mainPurple.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              const Text("Logout", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout?", 
            style: TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[400])),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
                child: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: deepPurple,
      child: Column(
        children: [
          // Banner Video di paling atas
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: mainPurple, width: 2)),
              boxShadow: [
                BoxShadow(
                  color: mainPurple.withOpacity(0.3),
                  blurRadius: 10,
                )
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_videoController != null && _videoController!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                else
                  Container(
                    color: cardPurple,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        deepPurple.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Scary Ghost",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Powerful Bug Sender Tool",
                        style: TextStyle(
                          color: accentPink,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Profile Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deepPurple, cardPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: mainPurple.withOpacity(0.5), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hallo, $username",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [mainPurple, lightPurple],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: deepPurple,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // Owner: Admin Page & Seller Page
                  if (role.toLowerCase() == "owner") ...[
                    _buildDrawerItem(Icons.admin_panel_settings_rounded, 'Admin Page', _navigateToAdminPage),
                    _buildDrawerItem(Icons.storefront_rounded, 'Seller Page', _navigateToSellerPage),
                  ],
                  
                  // Reseller VIP: Seller Page only
                  if (role.toLowerCase() == "reseller" || role.toLowerCase() == "vip")
                    _buildDrawerItem(Icons.storefront_rounded, 'Seller Page', _navigateToSellerPage),
                  
                  _buildDrawerItem(Icons.lock_clock_rounded, 'Change Password', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordPage(
                          username: username, 
                          sessionKey: sessionKey
                        )
                      )
                    );
                  }),
                  _buildDrawerItem(Icons.badge_rounded, 'NIK Check', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => NikCheckerPage())
                    );
                  }),
                  
                  const SizedBox(height: 10),
                  
                  // Logout Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: Colors.grey.shade800, width: 3)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.black),
                      title: const Text(
                        'Logout', 
                        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.purple.withOpacity(0.7), size: 14),
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog();
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Credits
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          "Credits",
                          style: TextStyle(
                            color: accentPink,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "@hafz_reals [ Developer ]",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "@InfoChHafzz [ CHANNEL ]",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.5), deepPurple.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: mainPurple, width: 3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentPink),
        title: Text(
          title, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade600, size: 14),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatelessWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url, 
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1a0b2e),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey)
        ),
      ),
    );
  }
}