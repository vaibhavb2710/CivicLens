import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/report_service.dart';

class EnhancedDashboardSidebar extends StatefulWidget {
  final Function() onLogout;
  final Function(int) onNavigationChanged;
  final int selectedIndex;

  const EnhancedDashboardSidebar({
    super.key,
    required this.onLogout,
    required this.onNavigationChanged,
    required this.selectedIndex,
  });

  @override
  State<EnhancedDashboardSidebar> createState() => _EnhancedDashboardSidebarState();
}

class _EnhancedDashboardSidebarState extends State<EnhancedDashboardSidebar> {
  final ReportService _reportService = ReportService();
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B7355), Color(0xFFA0845C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 25,
                    color: Color(0xFF8B7355),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Municipal Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Task Management System',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Main Navigation
                  _buildNavSection('MAIN NAVIGATION', [
                    _NavItem(Icons.dashboard, 'Overview', 0),
                    _NavItem(Icons.map, 'Live City Map', 1),
                    _NavItem(Icons.assignment, 'Task Management', 2),
                    _NavItem(Icons.person_add, 'Task Assignment', 3),
                    _NavItem(Icons.analytics, 'Performance', 4),
                  ]),
                  
                  // Task Status Section with Real-time Counts
                  _buildTaskStatusSection(),
                  
                  // Quick Actions
                  _buildQuickActionsSection(),
                ],
              ),
            ),
          ),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavSection(String title, List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildNavItem(item)),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildNavItem(_NavItem item) {
    bool isSelected = widget.selectedIndex == item.index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => widget.onNavigationChanged(item.index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B7355).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF8B7355).withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? const Color(0xFF8B7355) : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF8B7355) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTaskStatusSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportService.getAllReports(),
      builder: (context, snapshot) {
        Map<String, int> counts = {
          'pending': 0,
          'assigned': 0,
          'active': 0,
          'completed': 0,
        };
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String status = data['municipalStatus']?.toString() ?? 'pending';
            counts[status] = (counts[status] ?? 0) + 1;
          }
        }
        
        return ExpansionTile(
          leading: Icon(
            Icons.task_alt,
            size: 18,
            color: Colors.grey[600],
          ),
          title: Text(
            'Task Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            _buildTaskStatusItem('Pending Tasks', counts['pending'] ?? 0, Colors.blue, Icons.assignment),
            _buildTaskStatusItem('Assigned Tasks', counts['assigned'] ?? 0, Colors.orange, Icons.person_pin),
            _buildTaskStatusItem('Active Tasks', counts['active'] ?? 0, Colors.green, Icons.work_outline),
            _buildTaskStatusItem('Completed Tasks', counts['completed'] ?? 0, Colors.purple, Icons.done_all),
          ],
        );
      },
    );
  }
  
  Widget _buildTaskStatusItem(String label, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            // Could navigate to filtered view
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildQuickActionItem('Assign New Task', Icons.assignment_add, () {
          widget.onNavigationChanged(3); // Task Assignment screen
        }),
        _buildQuickActionItem('View Reports', Icons.bar_chart, () {
          // Navigate to reports
        }),
        _buildQuickActionItem('Export Data', Icons.download, () {
          // Export functionality
        }),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildQuickActionItem(String label, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  final String? badge;
  
  _NavItem(this.icon, this.label, this.index, [this.badge]);
}