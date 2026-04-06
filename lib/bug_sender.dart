import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> privateSenders = [];
  List<dynamic> publicSenders = [];
  bool isLoadingPrivate = false;
  bool isLoadingPublic = false;
  String? errorMessagePrivate;
  String? errorMessagePublic;

  final Color primaryDark = Colors.black;
  final Color primaryWhite = Colors.white;
  final Color accentPurple = Colors.purple;
  final Color cardDark = const Color(0xFF1A1A1A);
  final Color successGreen = Colors.green;
  final Color errorRed = Colors.red;

  // ✅ Check if user can access public senders
  bool get canAccessPublicSenders {
    return ['vip', 'owner'].contains(widget.role.toLowerCase());
  }

  // ✅ Get tab length based on role
  int get tabLength {
    return canAccessPublicSenders ? 2 : 1;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabLength, vsync: this);
    
    // Fetch senders based on role
    _fetchPrivateSenders();
    if (canAccessPublicSenders) {
      _fetchPublicSenders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBothSenders() async {
    if (canAccessPublicSenders) {
      await Future.wait([
        _fetchPrivateSenders(),
        _fetchPublicSenders(),
      ]);
    } else {
      await _fetchPrivateSenders();
    }
  }

  // ✅ Fetch Private Senders (endpoint: /mySender)
  Future<void> _fetchPrivateSenders() async {
    setState(() {
      isLoadingPrivate = true;
      errorMessagePrivate = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://privserv.my.id:2435/mySender?key=${widget.sessionKey}"),
      );

      print("Private Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            privateSenders = data["connections"] ?? [];
          });
        } else {
          setState(() {
            errorMessagePrivate = data["error"] ?? "Failed to fetch private senders";
          });
        }
      } else {
        setState(() {
          errorMessagePrivate = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessagePrivate = "Connection failed: $e";
      });
      print("Error fetching private: $e");
    } finally {
      setState(() {
        isLoadingPrivate = false;
      });
    }
  }

  // ✅ Fetch Public Senders (endpoint: /getPublicSenders)
  Future<void> _fetchPublicSenders() async {
    if (!canAccessPublicSenders) return;

    setState(() {
      isLoadingPublic = true;
      errorMessagePublic = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://privserv.my.id:2435/getPublicSenders?key=${widget.sessionKey}"),
      );

      print("Public Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            publicSenders = data["senders"] ?? [];
          });
        } else {
          setState(() {
            errorMessagePublic = data["message"] ?? "Failed to fetch public senders";
          });
        }
      } else {
        setState(() {
          errorMessagePublic = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessagePublic = "Connection failed: $e";
      });
      print("Error fetching public: $e");
    } finally {
      setState(() {
        isLoadingPublic = false;
      });
    }
  }

  void _showAddPrivateSenderDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: accentPurple),
            const SizedBox(width: 12),
            Text("Add Private Sender",
                style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: primaryWhite),
          decoration: InputDecoration(
            labelText: "Phone Number",
            labelStyle: TextStyle(color: accentPurple),
            hintText: "62xxx",
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.phone, color: accentPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentPurple),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: errorRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final number = phoneController.text.trim();

              if (number.isEmpty) {
                _showSnackBar("Please enter phone number", isError: true);
                return;
              }

              Navigator.pop(context);
              await _addPrivateSender(number);
            },
            child: Text("ADD SENDER", style: TextStyle(color: primaryDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _addPrivateSender(String number) async {
    setState(() => isLoadingPrivate = true);

    try {
      final response = await http.get(
        Uri.parse("http://privserv.my.id:2435/getPairing?key=${widget.sessionKey}&number=$number"),
      );

      print("Pairing Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode']);
          _showSnackBar("Pairing code generated successfully!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Failed to generate pairing code", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
      print("Error adding private sender: $e");
    } finally {
      setState(() => isLoadingPrivate = false);
      _fetchPrivateSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.qr_code_2, color: accentPurple, size: 50),
            const SizedBox(height: 10),
            Text("Pairing Required",
                style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentPurple.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Number: $number", style: TextStyle(color: primaryWhite)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentPurple),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: accentPurple,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Open WhatsApp → Settings → Linked Devices → Link a Device\nEnter this code to complete pairing",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: TextStyle(color: primaryWhite)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentPurple),
            onPressed: () {
              Navigator.pop(context);
              _fetchPrivateSenders();
            },
            child: Text("REFRESH LIST", style: TextStyle(color: primaryDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePrivateSender(String sessionName) async {
    final confirmed = await _showDeleteConfirmDialog();

    if (confirmed == true) {
      setState(() => isLoadingPrivate = true);

      try {
        _showSnackBar("Delete feature not implemented in backend yet", isError: true);
        
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoadingPrivate = false);
      }
    }
  }

  Future<void> _deletePublicSender(String sessionName) async {
    if (widget.role != "owner") {
      _showSnackBar("Only owner can delete public senders", isError: true);
      return;
    }

    final confirmed = await _showDeleteConfirmDialog();

    if (confirmed == true) {
      setState(() => isLoadingPublic = true);

      try {
        final response = await http.get(
          Uri.parse("http://privserv.my.id:2435/deletePublicSender?key=${widget.sessionKey}&sessionName=$sessionName"),
        );

        print("Delete Public Response: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Public sender deleted successfully!", isError: false);
            _fetchPublicSenders();
          } else {
            _showSnackBar(data["message"] ?? "Failed to delete public sender", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
        print("Error deleting public sender: $e");
      } finally {
        setState(() => isLoadingPublic = false);
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            Text("Confirm Delete", style: TextStyle(color: primaryWhite)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this sender? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: primaryWhite)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text("DELETE", style: TextStyle(color: primaryWhite)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPrivateSenderCard(Map<String, dynamic> sender) {
    final name = sender['sessionName'] ?? 'Unnamed';
    final type = sender['type'] ?? 'Unknown';
    final isActive = sender['isActive'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: isActive ? successGreen : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: accentPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? "ACTIVE" : "INACTIVE",
                              style: TextStyle(
                                color: isActive ? successGreen : Colors.grey,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentPurple,
                      side: BorderSide(color: accentPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _fetchPrivateSenders,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete, size: 16),
                    label: Text("DELETE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorRed.withOpacity(0.2),
                      foregroundColor: errorRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _deletePrivateSender(name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicSenderCard(Map<String, dynamic> sender) {
    final name = sender['sessionName'] ?? 'Unnamed';
    final type = sender['type'] ?? 'Unknown';
    final isActive = sender['isActive'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.public,
                    color: isActive ? successGreen : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "PUBLIC",
                              style: TextStyle(
                                color: successGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: type == "Business" 
                                  ? Colors.blue.withOpacity(0.2) 
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: type == "Business" ? Colors.blue : Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? "ACTIVE" : "INACTIVE",
                              style: TextStyle(
                                color: isActive ? successGreen : Colors.grey,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: successGreen,
                      side: BorderSide(color: successGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _fetchPublicSenders,
                  ),
                ),
                if (widget.role == "owner") ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete, size: 16),
                      label: Text("DELETE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorRed.withOpacity(0.2),
                        foregroundColor: errorRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _deletePublicSender(name),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isPrivate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPrivate ? Icons.lock : Icons.public,
            color: accentPurple,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            isPrivate ? "No Private Senders" : "No Public Senders",
            style: TextStyle(color: primaryWhite, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isPrivate
                ? "Add your first private sender"
                : "Public senders managed by owner",
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (isPrivate) ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("ADD SENDER"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showAddPrivateSenderDialog,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isPrivate) {
    final isLoading = isPrivate ? isLoadingPrivate : isLoadingPublic;
    final errorMessage = isPrivate ? errorMessagePrivate : errorMessagePublic;
    final senders = isPrivate ? privateSenders : publicSenders;

    if (isLoading && senders.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentPurple));
    }

    if (errorMessage != null && senders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorRed, size: 80),
            const SizedBox(height: 20),
            Text(
              "Failed to Load",
              style: TextStyle(color: primaryWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("TRY AGAIN"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () => isPrivate ? _fetchPrivateSenders() : _fetchPublicSenders(),
            ),
          ],
        ),
      );
    }

    if (senders.isEmpty) {
      return _buildEmptyState(isPrivate);
    }

    return RefreshIndicator(
      color: accentPurple,
      backgroundColor: cardDark,
      onRefresh: () => isPrivate ? _fetchPrivateSenders() : _fetchPublicSenders(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: senders.length,
        itemBuilder: (context, index) => isPrivate
            ? _buildPrivateSenderCard(Map<String, dynamic>.from(senders[index]))
            : _buildPublicSenderCard(Map<String, dynamic>.from(senders[index])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "Manage Bug Sender",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ Dynamic TabBar based on role
        bottom: canAccessPublicSenders 
          ? TabBar(
              controller: _tabController,
              indicatorColor: accentPurple,
              labelColor: accentPurple,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(
                  icon: Icon(Icons.lock),
                  text: "PRIVATE",
                ),
                Tab(
                  icon: Icon(Icons.public),
                  text: "PUBLIC",
                ),
              ],
            )
          : null, // No tabs for member/reseller
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentPurple),
            onPressed: _fetchBothSenders,
          ),
        ],
      ),
      body: canAccessPublicSenders
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(true), // Private Tab
                _buildTabContent(false), // Public Tab
              ],
            )
          : _buildTabContent(true), // Only Private for member/reseller
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentPurple,
        foregroundColor: primaryWhite,
        onPressed: _showAddPrivateSenderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}