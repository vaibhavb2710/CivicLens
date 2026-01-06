import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSidebar extends StatefulWidget {
  final Stream<QuerySnapshot> pendingTasksStream;
  final Stream<QuerySnapshot> activeTasksStream;
  final int activeCount;
  final int pendingCount;
  final int newlyReportedCount;
  final VoidCallback onLogout;
  final Widget Function(IconData, String, bool, {String? badge}) buildNavItem;
  final Function(int) onNavigationChanged;
  final int? selectedIndex;

  const DashboardSidebar({
    super.key,
    required this.pendingTasksStream,
    required this.activeTasksStream,
    required this.activeCount,
    required this.pendingCount,
    this.newlyReportedCount = 0,
    required this.onLogout,
    required this.buildNavItem,
    required this.onNavigationChanged,
    this.selectedIndex,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  @override
  Widget build(BuildContext context) {
    int totalTasks = widget.activeCount + widget.pendingCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Municipal Officer',
                      style: TextStyle(
                        color: const Color(0xFF2D2D2D),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Area Division 5',
                      style: TextStyle(
                        color: const Color(0xFF6B6B6B),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE8E6E1)),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Officer Status',
                style: TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'On Duty',
                    style: TextStyle(
                      color: Color(0xFF2D2D2D),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Assigned Area: Districts 5A-5C',
                style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 11,
                ),
              ),
              Text(
                'Active tasks: ${widget.activeCount} active, ${widget.pendingCount} pending',
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', 0, true, badge: widget.newlyReportedCount > 0 ? 'NEW' : null),
              _buildNavItem(Icons.map_outlined, 'Live City Map', 1, false, badge: 'Heat'),
              _buildNavItem(Icons.assignment, 'Assigned Tasks', 2, false, badge: totalTasks.toString()),
              _buildNavItem(Icons.group_work, 'Assigning Tasks', 3, false, badge: widget.newlyReportedCount > 0 ? widget.newlyReportedCount.toString() : null),
              _buildNavItem(Icons.trending_up, 'Performance', 4, false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isMain, {String? badge}) {
    final bool isSelected = (widget.selectedIndex ?? 0) == index;
    return GestureDetector(
      onTap: () {
        if ((widget.selectedIndex ?? 0) != index && mounted) {
          widget.onNavigationChanged(index);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF8B7355).withValues(alpha: 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B7355) : const Color(0xFF6B6B6B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF8B7355) : const Color(0xFF6B6B6B),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8B7355) : const Color(0xFF6B6B6B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
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
    );
  }
}
