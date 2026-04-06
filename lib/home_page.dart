import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final bool isGroup;
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;

  const HomePage({
    super.key,
    required this.isGroup,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final targetController = TextEditingController();
  final linkController = TextEditingController();
  
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  String selectedBugId = "";
  bool _isSending = false;
  bool _isVideoInitialized = false;
  
  // Tambahan: Variabel untuk kontrol mode tombol baru
  bool _isNomorMode = true; 
  
  // Progress tracking
  int _currentStep = 0;
  double _progress = 0.0;
  List<String> _progressSteps = [];

  // Warna Tema Purple (Sesuai Kode Asli - TIDAK DIUBAH)
  final Color deepPurple = const Color(0xFF1a0b2e);
  final Color mainPurple = const Color(0xFF6b2d9f);
  final Color lightPurple = const Color(0xFF9d4edd);
  final Color accentPink = const Color(0xFFe0aaff);
  final Color bgDark = const Color(0xFF0d0221);
  final Color cardPurple = const Color(0xFF2a1347);

  @override
  void initState() {
    super.initState();
    
    // Default mode berdasarkan parameter awal
    _isNomorMode = !widget.isGroup;

    _videoController = VideoPlayerController.asset("assets/videos/landing.mp4")
      ..initialize().then((_) {
        setState(() => _isVideoInitialized = true);
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
      });

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    _progressSteps = [
      "Initializing...",
      "Connecting to server...",
      "Validating session...",
      "Preparing payload...",
      "Sending bug...",
      "Success!"
    ];
  }

  @override
  void dispose() {
    _videoController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    targetController.dispose();
    linkController.dispose();
    super.dispose();
  }

  // Simulate progress steps
  Future<void> _updateProgress(int step) async {
    setState(() {
      _currentStep = step;
      _progress = (step + 1) / _progressSteps.length;
    });
    
    _progressController.reset();
    _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ========== SEND BUG NOMOR ==========
  Future<void> _sendBugNomor() async {
    final target = targetController.text.trim();

    if (target.isEmpty) {
      _showPopup("Error", "Nomor target tidak boleh kosong!", isError: true);
      return;
    }

    setState(() {
      _isSending = true;
      _currentStep = 0;
      _progress = 0.0;
    });

    try {
      // Step 1: Initializing
      await _updateProgress(0);
      
      // Step 2: Connecting
      await _updateProgress(1);
      
      // Step 3: Validating
      await _updateProgress(2);
      
      // Step 4: Preparing
      await _updateProgress(3);
      
      final url = "http://privserv.my.id:2435/sendBug?key=${widget.sessionKey}&target=$target&bug=$selectedBugId";
      
      // Step 5: Sending
      await _updateProgress(4);
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      bool isSuccess = false;
      String msg = "";

      if (data["cooldown"] == true) {
        msg = "Cooldown: Tunggu ${data['wait']} detik.";
      } else if (data["valid"] == false) {
        msg = "Sesi Invalid.";
      } else if (data["sended"] == false) {
        msg = "Gagal: Server Maintenance.";
      } else {
        isSuccess = true;
        msg = "Bug berhasil dikirim!";
        // Step 6: Success
        await _updateProgress(5);
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (isSuccess) {
        _showPopup("Success", msg, isError: false);
        targetController.clear();
      } else {
        _showPopup("Failed", msg, isError: true);
      }

    } catch (e) {
      _showPopup("Connection Error", "Gagal menghubungi server.", isError: true);
    } finally {
      setState(() {
        _isSending = false;
        _currentStep = 0;
        _progress = 0.0;
      });
    }
  }

  // ========== SEND BUG GROUP ==========
  Future<void> _sendBugGroup() async {
    final link = linkController.text.trim();

    if (link.isEmpty) {
      _showPopup("Error", "Link group tidak boleh kosong!", isError: true);
      return;
    }

    if (!link.contains("chat.whatsapp.com")) {
      _showPopup("Invalid Link", "Link Group tidak valid!", isError: true);
      return;
    }

    setState(() {
      _isSending = true;
      _currentStep = 0;
      _progress = 0.0;
    });

    try {
      // Step 1: Initializing
      await _updateProgress(0);
      
      // Step 2: Connecting
      await _updateProgress(1);
      
      // Step 3: Validating
      await _updateProgress(2);
      
      // Step 4: Preparing
      await _updateProgress(3);
      
      final encodedLink = Uri.encodeComponent(link);
      final url = "http://privserv.my.id:2435/sendGroupBug?key=${widget.sessionKey}&link=$encodedLink&bug=$selectedBugId";
      
      // Step 5: Sending
      await _updateProgress(4);
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      bool isSuccess = false;
      String msg = "";

      if (data["valid"] == false) {
        msg = "Session Invalid.";
      } else if (data["cooldown"] == true) {
        msg = "Cooldown: Tunggu ${data['wait']} detik.";
      } else if (data["sended"] == true) {
        isSuccess = true;
        msg = "Bug berhasil dikirim ke Group!";
        // Step 6: Success
        await _updateProgress(5);
      } else {
        msg = data["message"] ?? "Gagal mengirim bug.";
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (isSuccess) {
        _showPopup("Success", msg, isError: false);
        linkController.clear();
      } else {
        _showPopup("Failed", msg, isError: true);
      }

    } catch (e) {
      _showPopup("Connection Error", "Gagal menghubungi server.", isError: true);
    } finally {
      setState(() {
        _isSending = false;
        _currentStep = 0;
        _progress = 0.0;
      });
    }
  }

  void _showPopup(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: cardPurple.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isError ? Colors.redAccent : lightPurple, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.redAccent : Colors.greenAccent
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: accentPink)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // BACKGROUND DIGANTI JADI HITAM PEKAT
          Container(
            color: Colors.black, 
          ),

          // Overlay Gelap (Gradient tetap dipertahankan agar tetap estetik)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8), // Sedikit transparan di atas
                  deepPurple.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    
                    _buildVideoBanner(),
                    const SizedBox(height: 20),
                    
                    // === UPDATE: TOMBOL MODE (Tampilan Dirubah, Warna Tetap Ungu) ===
                    _buildModeButtons(),
                    const SizedBox(height: 20),
                    // ======================================

                    // Konten dinamis berdasarkan tombol yang dipilih
                    if (_isNomorMode) ...[
                      // Input Target
                      _buildSectionTitle(Icons.phone_android, "TARGET NUMBER"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: targetController,
                        hint: "628xxxxxxxx",
                        prefixIcon: Icons.phone,
                      ),
                      const SizedBox(height: 25),
                    ] else ...[
                      // Link Group WA
                      _buildSectionTitle(Icons.link, "LINK GROUP WA"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: linkController,
                        hint: "https://chat.whatsapp.com/...",
                        prefixIcon: Icons.link,
                      ),
                      const SizedBox(height: 25),
                    ],

                    // Dropdown Bug (Sama untuk keduanya)
                    _buildSectionTitle(Icons.bug_report, "PILIH BUG"),
                    const SizedBox(height: 10),
                    _buildDropdown(),
                    const SizedBox(height: 30),

                    // Progress Indicator
                    if (_isSending) _buildProgressIndicator(),
                    if (_isSending) const SizedBox(height: 30),

                    // Send Button (Logic berubah sesuai mode)
                    _buildSendButton(
                      onPressed: _isNomorMode ? _sendBugNomor : _sendBugGroup,
                      label: _isNomorMode ? "SEND BUG NOMOR" : "SEND BUG GROUP",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === UPDATE: WIDGET TOMBOL MODE ===
  // Hanya tampilan layout yang disesuaikan dengan foto (lebih compact, ikon di kiri).
  // Warna tetap menggunakan variabel tema ungu (mainPurple, lightPurple, dll).
  Widget _buildModeButtons() {
    return Row(
      children: [
        // Button BUG NOMOR (Kiri)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isNomorMode = true;
              });
            },
            child: Container(
              // Tinggi disesuaikan agar terlihat seperti tombol tool yang compact
              height: 50, 
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // Jika aktif: warna ungu utama dengan gradient
                // Jika pasif: transparan/gelap dengan border abu-abu
                gradient: _isNomorMode 
                    ? LinearGradient(colors: [mainPurple, lightPurple]) 
                    : null,
                color: _isNomorMode ? null : Colors.grey[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isNomorMode ? mainPurple : Colors.grey[700]!,
                  width: 1.5,
                ),
                // Efek glow halus saat aktif
                boxShadow: _isNomorMode 
                    ? [BoxShadow(color: mainPurple.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_android,
                    // Icon putih saat aktif, abu-abu saat pasif
                    color: _isNomorMode ? Colors.white : Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BUG NOMER", // Sesuai tulisan di foto
                    style: TextStyle(
                      color: _isNomorMode ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Button BUG GROUP (Kanan)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isNomorMode = false;
              });
            },
            child: Container(
              // Tinggi disesuaikan agar terlihat seperti tombol tool yang compact
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // Jika aktif: warna ungu utama dengan gradient
                // Jika pasif: transparan/gelap dengan border abu-abu
                gradient: !_isNomorMode 
                    ? LinearGradient(colors: [mainPurple, lightPurple]) 
                    : null,
                color: !_isNomorMode ? null : Colors.grey[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_isNomorMode ? mainPurple : Colors.grey[700]!,
                  width: 1.5,
                ),
                // Efek glow halus saat aktif
                boxShadow: !_isNomorMode 
                    ? [BoxShadow(color: mainPurple.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    // Icon putih saat aktif, abu-abu saat pasif
                    color: !_isNomorMode ? Colors.white : Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BUG GROUP",
                    style: TextStyle(
                      color: !_isNomorMode ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== WIDGET HELPERS (TIDAK DIUBAH) ==========

  Widget _buildVideoBanner() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainPurple.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: mainPurple.withOpacity(0.3),
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
            if (_isVideoInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              Container(
                color: deepPurple,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    deepPurple.withOpacity(0.7),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
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
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.8), deepPurple.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: mainPurple.withOpacity(0.2),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        children: [
          // Step indicator with numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_progressSteps.length, (index) {
              bool isActive = index <= _currentStep;
              bool isCurrent = index == _currentStep;
              
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? LinearGradient(
                                colors: [mainPurple, lightPurple],
                              )
                            : null,
                        color: isActive ? null : cardPurple.withOpacity(0.5),
                        border: Border.all(
                          color: isCurrent ? accentPink : mainPurple.withOpacity(0.3),
                          width: isCurrent ? 2 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: accentPink.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isActive && index < _currentStep
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    if (index < _progressSteps.length - 1)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        height: 2,
                        color: isActive ? lightPurple : cardPurple,
                      ),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // Animated Progress Bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress * _progressAnimation.value,
                      minHeight: 10,
                      backgroundColor: cardPurple,
                      valueColor: AlwaysStoppedAnimation<Color>(accentPink),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progressSteps[_currentStep],
                        style: TextStyle(
                          color: accentPink,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.6), deepPurple.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: mainPurple.withOpacity(0.2), blurRadius: 15)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentPink, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('assets/images/icon.jpg'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [mainPurple.withOpacity(0.6), lightPurple.withOpacity(0.6)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Role: ${widget.role.toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentPink.withOpacity(0.3)),
                          ),
                          child: Text(
                            "Exp: ${widget.expiredDate}",
                            style: TextStyle(
                              color: accentPink,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: accentPink, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.5), deepPurple.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainPurple.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        cursorColor: accentPink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: accentPink, size: 20)
              : null,
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
            onPressed: controller.clear,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardPurple.withOpacity(0.5), deepPurple.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainPurple.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: cardPurple,
          value: selectedBugId,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: accentPink),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: widget.listBug.map((bug) {
            return DropdownMenuItem<String>(
              value: bug['bug_id'],
              child: Text(
                bug['bug_name'],
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedBugId = val!),
        ),
      ),
    );
  }

  Widget _buildSendButton({required VoidCallback onPressed, required String label}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: mainPurple.withOpacity(0.3 * _pulseController.value),
                blurRadius: 15 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isSending ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mainPurple, lightPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isSending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          "SENDING...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}