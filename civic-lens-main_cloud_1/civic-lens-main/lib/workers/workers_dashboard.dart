import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';
import 'worker_assigned_tasks_screen.dart';

class WorkersDashboard extends StatefulWidget {
  const WorkersDashboard({super.key});

  @override
  State<WorkersDashboard> createState() => _WorkersDashboardState();
}

class _WorkersDashboardState extends State<WorkersDashboard> {
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _selectedIndex = 0;
  String? currentWorkerId;
  String? currentWorkerDepartment;

  // Navigation items for workers
  final List<NavigationItem> _navItems = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/workers-dashboard'),
    NavigationItem(icon: Icons.assignment, label: 'Assigned Tasks', route: '/workers-tasks'),
    NavigationItem(icon: Icons.location_on, label: 'Field Work', route: '/workers-field'),
    NavigationItem(icon: Icons.report, label: 'Reports', route: '/workers-reports'),
    NavigationItem(icon: Icons.person, label: 'Profile', route: '/workers-profile'),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentWorkerInfo();
  }

  Future<void> _getCurrentWorkerInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        currentWorkerId = user.uid;
      });
      
      // Get worker's department
      Map<String, dynamic>? userData = await _userService.getUserProfile(user.uid);
      if (userData != null && mounted) {
        setState(() {
          currentWorkerDepartment = userData['department'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 768;
        
        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: _buildSidebar(),
          ),
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Workers Portal',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(),
      ),
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF8B7355),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.engineering,
                  size: 30,
                  color: Color(0xFF8B7355),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Field Worker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _authService.currentUser?.email ?? 'worker@civic.com',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              return _buildNavItem(_navItems[index], index);
            },
          ),
        ),
        // Logout Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(NavigationItem item, int index) {
    bool isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? const Color(0xFF8B7355) : Colors.grey[600],
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF8B7355) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF8B7355).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF8B7355),
      unselectedItemColor: Colors.grey[600],
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Tasks',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Field',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Reports',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildTasksContent();
      case 2:
        return _buildFieldWorkContent();
      case 3:
        return _buildReportsContent();
      case 4:
        return _buildProfileContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.engineering,
                  size: 48,
                  color: Color(0xFF8B7355),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to Workers Portal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your field assignments and track progress',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Cards
          _buildTaskStatsCards(),
          const SizedBox(height: 24),
          
          // Recent Activities
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B7355).withOpacity(0.1),
                        child: const Icon(
                          Icons.work,
                          color: Color(0xFF8B7355),
                          size: 20,
                        ),
                      ),
                      title: Text('Task ${index + 1} completed'),
                      subtitle: Text('${index + 1} hour${index == 0 ? '' : 's'} ago'),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatsCards() {
    if (currentWorkerId == null) {
      return _buildStaticStatsCards();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _reportService.getAssignedTasks(currentWorkerId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStaticStatsCards();
        }

        List<QueryDocumentSnapshot> allTasks = snapshot.data!.docs;
        
        int pendingCount = allTasks.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['municipalStatus'] == 'assigned'; // Pending = assigned but not started
        }).length;
        
        int activeCount = allTasks.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['municipalStatus'] == 'active'; // Active = started but not completed
        }).length;
        
        int completedCount = allTasks.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['municipalStatus'] == 'completed'; // Completed tasks
        }).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 768 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Pending Tasks',
                  pendingCount.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Tasks',
                  activeCount.toString(),
                  Icons.work_outline,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed',
                  completedCount.toString(),
                  Icons.done_all,
                  const Color(0xFF8B7355),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStaticStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 768 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Pending Tasks',
              '0',
              Icons.assignment,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Tasks',
              '0',
              Icons.work_outline,
              Colors.orange,
            ),
            _buildStatCard(
              'Completed',
              '0',
              Icons.done_all,
              const Color(0xFF8B7355),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksContent() {
    return const WorkerAssignedTasksScreen();
  }

  Widget _buildFieldWorkContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Field Work',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Track your location and field activities',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Generate and view work reports',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your profile and settings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}