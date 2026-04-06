import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['reseller', 'reseller1', 'owner', 'member'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 10;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // --- PALET WARNA UNGU ---
  final Color deepPurple = const Color(0xFF4A148C);
  final Color mainPurple = const Color(0xFF6A1B9A);
  final Color lightPurple = const Color(0xFF9d4edd);
  final Color accentPurple = const Color(0xFFAB47BC);
  final Color bgBlack = const Color(0xFF000000);
  final Color cardBlack = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _fetchUsers();
  }

  @override
  void dispose() {
    _animController.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://privserv.my.id:2435/listUsers?key=$sessionKey'),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['authorized'] == true) {
          setState(() {
            fullUserList = data['users'] ?? [];
            _filterAndPaginate();
          });
        } else {
          _showSnack("⚠️ Error: ${data['message'] ?? 'Akses ditolak.'}");
        }
      } else {
        _showSnack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _showSnack("🌐 Gagal memuat data user: $e");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    if (start >= filteredList.length) return [];
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => filteredList.isEmpty ? 1 : (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _showSnack("⚠️ Masukkan username!");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://privserv.my.id:2435/deleteUser?key=$sessionKey&username=$username'),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['deleted'] == true) {
          _showSnack("✅ User '${data['user']?['username'] ?? username}' dihapus!", isSuccess: true);
          deleteController.clear();
          _fetchUsers();
        } else {
          _showSnack("❌ Gagal: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        _showSnack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _showSnack("🌐 Error koneksi: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showSnack("⚠️ Semua field wajib diisi!");
      return;
    }

    // Validasi day harus angka
    if (int.tryParse(day) == null) {
      _showSnack("⚠️ Days harus berupa angka!");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://privserv.my.id:2435/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['created'] == true) {
          _showSnack("✅ Akun '${data['user']?['username'] ?? username}' berhasil dibuat!", isSuccess: true);
          createUsernameController.clear();
          createPasswordController.clear();
          createDayController.clear();
          newUserRole = 'member';
          _fetchUsers();
        } else {
          _showSnack("❌ Gagal: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        _showSnack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _showSnack("🌐 Error koneksi: $e");
    }
    setState(() => isLoading = false);
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSuccess ? Colors.green[800] : deepPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // Background Ambience
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [deepPurple.withOpacity(0.2), Colors.transparent]),
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // --- HEADER ---
                    _buildHeader(),
                    const SizedBox(height: 25),

                    // --- CREATE USER CARD ---
                    _buildSectionTitle("Create New User", Icons.person_add),
                    const SizedBox(height: 10),
                    _buildCreateUserCard(),

                    const SizedBox(height: 30),

                    // --- DELETE USER CARD (Compact) ---
                    _buildDeleteUserCard(),

                    const SizedBox(height: 30),

                    // --- USER LIST SECTION ---
                    _buildSectionTitle("Database Users", Icons.storage),
                    const SizedBox(height: 10),
                    _buildUserListSection(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(color: accentPurple)),
            ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [deepPurple, const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: mainPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))
        ],
        border: Border.all(color: mainPurple.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accentPurple),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ADMIN PANEL",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "Manage Access & Users",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accentPurple, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: accentPurple,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: mainPurple.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildCreateUserCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildInput(createUsernameController, "Username", Icons.person_outline),
          const SizedBox(height: 15),
          _buildInput(createPasswordController, "Password", Icons.lock_outline),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildInput(createDayController, "Days", Icons.calendar_today, isNumber: true),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: _buildDropdown(newUserRole, (val) => setState(() => newUserRole = val!)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGradientButton("CREATE ACCOUNT", Icons.add_circle, _createAccount),
        ],
      ),
    );
  }

  Widget _buildDeleteUserCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: deepPurple.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: accentPurple, size: 20),
              const SizedBox(width: 10),
              Text("Danger Zone", style: TextStyle(color: accentPurple, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInput(deleteController, "Username to Delete", Icons.delete_outline),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: deepPurple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  onPressed: _deleteUser,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListSection() {
    return Column(
      children: [
        // Filter Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1A1A1A),
              value: selectedRole,
              isExpanded: true,
              icon: Icon(Icons.filter_list, color: accentPurple),
              items: roleOptions.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(
                    "Filter: ${role.toUpperCase()}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedRole = val!;
                  _filterAndPaginate();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 15),

        // List
        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Icon(Icons.person_off, color: Colors.grey, size: 40),
                const SizedBox(height: 10),
                Text("No users found for '$selectedRole'", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _getCurrentPageData().length,
            itemBuilder: (context, index) {
              final user = _getCurrentPageData()[index];
              return _buildUserItem(user);
            },
          ),
        
        const SizedBox(height: 20),
        
        // Pagination
        if (totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainPurple.withOpacity(0.3)),
            ),
            child: Icon(Icons.person, color: accentPurple, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username']?.toString() ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniBadge(user['role']?.toString() ?? 'member', Colors.blue),
                    const SizedBox(width: 8),
                    _buildMiniBadge("Exp: ${user['expiredDate']?.toString() ?? 'N/A'}", Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[700]),
            onPressed: () {
              deleteController.text = user['username']?.toString() ?? '';
              _showSnack("Tekan tombol ungu di 'Danger Zone' untuk menghapus.", isSuccess: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final page = index + 1;
          final isActive = currentPage == page;
          return GestureDetector(
            onTap: () => setState(() => currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isActive ? mainPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isActive ? accentPurple : Colors.grey.shade800),
                boxShadow: isActive ? [BoxShadow(color: deepPurple, blurRadius: 10)] : [],
              ),
              child: Center(
                child: Text(
                  "$page",
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        cursorColor: accentPurple,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: mainPurple, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String val, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF222222),
          value: val,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: accentPurple),
          items: roleOptions.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [deepPurple, accentPurple]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: mainPurple.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
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
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}