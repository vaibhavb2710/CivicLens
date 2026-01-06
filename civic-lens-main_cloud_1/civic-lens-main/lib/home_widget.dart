import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_model.dart';
import 'report_issue_screen.dart';
import 'notifications_screen.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'services/notification_service.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;
  String _username = 'User';
  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _model = HomeModel();
    _loadUsername();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future _loadUsername() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          Map userData = doc.data() as Map;
          setState(() {
            _username = userData['username'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading username: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
          );
        },
        backgroundColor: const Color(0xFF8B7355),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text(
          'Report Issue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.location_city,
              color: const Color(0xFF8B7355),
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'CIVIC LENS',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E6E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => print('Map pressed'),
                    icon: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFF8B7355),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      try {
                        await AuthService().signOut();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging out: $e')),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Color(0xFF8B7355)),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E6E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF8B7355),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Color(0xFF2D2D2D),
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8E6E1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF8B7355),
                                size: 24,
                              ),
                            ),
                            // Notification badge
                            StreamBuilder<int>(
                              stream: _notificationService.getUnreadNotificationCount(
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data! > 0) {
                                  return Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        snapshot.data.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
               // _buildDebugSection(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B7355), Color(0xFFA68B5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report an Issue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Help make your city better by reporting problems in your area',
                          style: TextStyle(
                            color: Color(0xffe6ffffff),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF8B7355),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Start Report',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildCategoriesSection(context),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Recent Reports',
                      style: TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAllReportsDialog(),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF8B7355),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentReportsList(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Categories',
          style: TextStyle(
            color: const Color(0xFF2D2D2D),
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        isDesktop ? _buildDesktopCategoryRow() : _buildMobileCategoryGrid(),
      ],
    );
  }

  Widget _buildDesktopCategoryRow() {
    final categories = [
      {'icon': '🚧', 'label': 'Potholes'},
      {'icon': '💡', 'label': 'Streetlights'},
      {'icon': '🗑️', 'label': 'Trash'},
      {'icon': '🌳', 'label': 'Parks'},
      {'icon': '🚽', 'label': 'Sanitation'},
      {'icon': 'add', 'label': 'Other'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSmallCategoryButton(category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCategoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryCard('🚧', 'Potholes'),
        _buildCategoryCard('💡', 'Streetlights'),
        _buildCategoryCard('🗑️', 'Trash'),
        _buildCategoryCard('🌳', 'Parks'),
        _buildCategoryCard('🚽', 'Sanitation'),
        _buildCategoryCard('', 'Other', isOther: true),
      ],
    );
  }

  Widget _buildSmallCategoryButton(Map category) {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E6E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (category['icon'] == 'add')
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF8B7355),
                    size: 20,
                  )
                else
                  Text(
                    category['icon']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                const SizedBox(height: 4),
                Text(
                  category['label']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String emoji, String label, {bool isOther = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isOther)
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF8B7355),
                    size: 32,
                  )
                else
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CRITICAL FIX: No orderBy in Firestore query but sort by createdAt in Dart
  Widget _buildRecentReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportService.getUserReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error loading reports',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF8B7355)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: const Color(0xFF6B6B6B),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No reports yet',
                  style: TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your submitted reports will appear here',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Submit Your First Report',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

        // sort reports by createdAt DESCENDING in APP code
        docs.sort((a, b) {
          Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        List<QueryDocumentSnapshot> reports = docs.take(3).toList();

        return Column(
          children: reports.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReportCard(doc.id, data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> data) {
    Color statusColor;
    String displayStatus = data['status'] ?? 'Submitted';
    switch (displayStatus) {
      case 'Submitted':
        statusColor = const Color(0xFFFFA726);
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      case 'Resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    String timeAgo = _formatTimeAgo(data['createdAt'] as Timestamp?);
    String reportIdShort = reportId.length > 8 ? reportId.substring(0, 8) : reportId;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIssueIcon(data['issueType']),
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Unknown Issue',
                          style: const TextStyle(
                            color: Color(0xFF2D2D2D),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          displayStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['description'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFF9E9E9E),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$timeAgo • ID: #$reportIdShort',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data['issueType'] ?? 'Other',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
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
    );
  }

  IconData _getIssueIcon(String? issueType) {
    switch (issueType?.toLowerCase()) {
      case 'potholes':
        return Icons.construction;
      case 'streetlights':
        return Icons.lightbulb_outline;
      case 'trash':
        return Icons.delete_outline;
      case 'parks':
        return Icons.park_outlined;
      case 'sanitation':
        return Icons.cleaning_services_outlined;
      case 'traffic signs':
        return Icons.traffic_outlined;
      case 'water issues':
        return Icons.water_drop_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final now = DateTime.now();
    final reportTime = timestamp.toDate();
    final difference = now.difference(reportTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showAllReportsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B7355),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'My Reports',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _reportService.getUserReports(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF8B7355)),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Color(0xFF6B6B6B),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reports found',
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                      docs.sort((a, b) {
                        Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        if (timeA == null || timeB == null) return 0;
                        return timeB.compareTo(timeA);
                      });
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          QueryDocumentSnapshot doc = docs[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReportCard(doc.id, data),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}