import 'package:flutter/material.dart';

class DashboardStatsCards extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final int pendingCount;
  final int newlyReportedCount;

  const DashboardStatsCards({
    super.key,
    required this.activeCount,
    required this.completedCount,
    required this.pendingCount,
    this.newlyReportedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          // Wide layout with 5 cards
          return Row(
            children: [
              Expanded(child: _buildStatCard('Active Tasks', activeCount.toString(), Colors.brown, Icons.play_circle_fill)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Completed Today', completedCount.toString(), Colors.green, Icons.check_circle)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Pending Tasks', pendingCount.toString(), Colors.blue, Icons.pending_actions)),
              const SizedBox(width: 16),
              Expanded(child: _buildNewTasksCard('New Reports', newlyReportedCount.toString(), Colors.orange, Icons.new_releases)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Avg Response', '2.4h', Colors.purple, Icons.schedule)),
            ],
          );
        } else if (constraints.maxWidth > 768) {
          // Medium layout with 4 cards in first row
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Active Tasks', activeCount.toString(), Colors.brown, Icons.play_circle_fill)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Completed Today', completedCount.toString(), Colors.green, Icons.check_circle)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Pending Tasks', pendingCount.toString(), Colors.blue, Icons.pending_actions)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNewTasksCard('New Reports', newlyReportedCount.toString(), Colors.orange, Icons.new_releases)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Avg Response', '2.4h', Colors.purple, Icons.schedule)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Spacer
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Spacer
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Spacer
                ],
              ),
            ],
          );
        } else {
          // Narrow layout with 2 cards per row
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Active Tasks', activeCount.toString(), Colors.brown, Icons.play_circle_fill)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Completed Today', completedCount.toString(), Colors.green, Icons.check_circle)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pending Tasks', pendingCount.toString(), Colors.blue, Icons.pending_actions)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNewTasksCard('New Reports', newlyReportedCount.toString(), Colors.orange, Icons.new_releases)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Avg Response', '2.4h', Colors.purple, Icons.schedule)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Spacer
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTasksCard(String title, String value, Color color, IconData icon) {
    bool hasNewTasks = int.tryParse(value) != null && int.parse(value) > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasNewTasks ? color.withOpacity(0.3) : const Color(0xFFE8E6E1),
          width: hasNewTasks ? 2 : 1,
        ),
        boxShadow: hasNewTasks ? [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (hasNewTasks) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: hasNewTasks ? color : color.withOpacity(0.7),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasNewTasks) ...[
                const SizedBox(width: 6),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.trending_up,
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: hasNewTasks ? const Color(0xFF6B6B6B) : const Color(0xFF9B9B9B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasNewTasks) ...[
            const SizedBox(height: 2),
            Text(
              'Requires attention',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
